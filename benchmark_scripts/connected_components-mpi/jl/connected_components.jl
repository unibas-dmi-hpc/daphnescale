using MatrixMarket
using SparseArrays
using SparseMatricesCSR

using MPI
MPI.Init()

comm = MPI.COMM_WORLD

function read_and_send_matrix(filename)
  rank = MPI.Comm_rank(comm)
  world = MPI.Comm_size(comm)
  if rank == 0
    G = MatrixMarket.mmread(filename, :csr)
    n = size(G, 1)
    nb_sub = world
    Is = Array{Array{Int}}(undef, nb_sub)
    Js = Array{Array{Int}}(undef, nb_sub)
    shapes     = [div(n, nb_sub) for _ in 1:nb_sub]
    shapes[nb_sub] = n - (nb_sub-1)*div(n, nb_sub)
    offsets = zeros(nb_sub)
    offsets[2:nb_sub] = cumsum(shapes)[1:nb_sub-1]
    for k in 1:nb_sub
      Is[k] = []
      Js[k] = []
    end
    for row_id in 1:(length(G.rowptr) - 1)
      next_ptr = G.rowptr[row_id + 1]
      current_ptr = G.rowptr[row_id]
      k = div((row_id - 1), div(n, nb_sub)) + 1
      if k > nb_sub
        k = nb_sub
      end
      nb_elements = next_ptr - current_ptr
      append!(Is[k], fill(row_id - offsets[k], nb_elements))
      append!(Js[k], G.colval[current_ptr:next_ptr-1])
    end

    for k in 2:nb_sub
      MPI.send(n, comm; dest=k-1, tag=0)
      MPI.send(Is[k], comm; dest=k-1, tag=1)
      MPI.send(Js[k], comm; dest=k-1, tag=2)
      MPI.send(shapes[k], comm; dest=k-1, tag=3)
    end
    Gs = sparsecsr(Is[1], Js[1], ones(length(Is[1])), shapes[1], n)
    return Gs
  else

    n = MPI.recv(comm; source=0, tag=0)
    Is = MPI.recv(comm; source=0, tag=1)
    Js = MPI.recv(comm; source=0, tag=2)
    shape = MPI.recv(comm; source=0, tag=3)
    Gs = sparsecsr(Is, Js, ones(length(Is)), shape, n)
    return Gs
  end
end

# function G_broadcast_mult_c(G, c)
#   cols = colvals(G)
#   vals = nonzeros(G)
#   m, n = size(G)
#   maxs = zeros(n)
#   @Threads.threads for j = 1:m
#      for i in nzrange(G, j)
#         col = cols[i]
#         val = vals[i]
#         if val * c[j] > maxs[col]
#           maxs[col] = val*c[j]
#         end
#      end
#   end
#   maxs
# end

function G_broadcast_mult_c(G, c)
  cols = colvals(G)
  vals = nonzeros(G)
  m, n = size(G)
  maxs = zeros(m)
  @Threads.threads for row = 1:m
     maxval = 0.0
     for i in nzrange(G, row)
        col = cols[i]
        val = vals[i]
        weighted = val * c[col]
        if weighted > maxval
          maxval = weighted
        end
     end
     maxs[row] = maxval
  end
  return maxs
end

struct MyWrapper
  data::Vector{Float64}
end

function reduce_max(x, y)
  max.(x, y)
end

function cc(filename, maxi)
  start_reading = time_ns()
  G = read_and_send_matrix(filename)
  start_compute = time_ns()
  rank = MPI.Comm_rank(comm)
  world = MPI.Comm_size(comm)
  n = size(G, 2)

  sizes = [div(n, world) for _ in 1:world]
  sizes[world] = n - (world-1) * div(n, world)
  offsets = zeros(Int64, world)
  offsets[2:world] = cumsum(sizes)[1:world-1]

  # c = vec(collect(1.0:1.0:float(size(G, 2))))
  c = collect(1.0:1.0:float(n))

  for iter in 1:maxi
    # x = G_broadcast_mult_c(G, c[1+offsets[rank + 1]:(1+offsets[rank + 1] + sizes[rank + 1] - 1)])
    # c_partial = max.(c, x)
    # MPI.Allreduce!(c_partial, c, reduce_max, comm)

    # 1. Multiply G with full c and Extract only the part for this rank
    x_local = G_broadcast_mult_c(G, c)

    # 3. Allgatherv to collect full x from all ranks
    x_full = similar(c) # new array same ytpe and size, uniitialized
    sizes32 = Int32.(sizes)

    MPI.Allgatherv!(x_local, x_full, sizes32, comm)

    # 4. Max update
    c = max.(c, x_full)
  end
  if rank == 0
    fin = time_ns()
    duration_reading = (fin - start_reading) * 1e-9
    duration_compute = (fin - start_compute) * 1e-9
    println("$(duration_reading),$(duration_compute),$(sum(c))")
  end

end

@assert(length(ARGS) == 1)
filename = ARGS[1]
maxi = 100
cc(filename, maxi)

