using MatrixMarket
using SparseArrays
using SparseMatricesCSR

function G_broadcast_mult_c(G, c)
  cols = colvals(G)
  vals = nonzeros(G)
  m, n = size(G)
  new_vals = zeros(length(vals))
  Threads.@threads for j = 1:m
     for i in nzrange(G, j)
        col = cols[i]
        val = vals[i]
        new_vals[i] = vals[i] * c[col]
     end
  end
  SparseMatricesCSR.SparseMatrixCSR{1}(m, n, G.rowptr, cols, new_vals)
end

function spmaximum(G, dim)
  cols = colvals(G)
  vals = nonzeros(G)
  m, n = size(G)
  maxs = zeros(n)
  if dim == 0
    for j = 1:m
       for i in nzrange(G, j)
          col = cols[i]
          val = vals[i]
          if val > maxs[col]
            maxs[col] = val
          end
       end
    end
  elseif dim == 1
    for j = 1:m
       for i in nzrange(G, j)
          val = vals[i]
          if val > maxs[j]
            maxs[j] = val
          end
       end
    end
  else
    println("Oopsi dim '$(dim)' not supported")
  end
  maxs
end


function cc(filename, maxi)
  start_reading = time_ns()
  # this line made trouble --> /daphnesched2/julia-trouble.out: :csr is not accepted anymore by MatrixMarket.jl v0.5.2
  #G = MatrixMarket.mmread(filename, :csr)
  G = MatrixMarket.mmread(filename)  # reads as SparseMatrixCSC
  G = SparseMatrixCSR(G)             # converts to CSR
  start_compute = time_ns()
  c = vec(collect(1.0:1.0:float(size(G, 1))))

  for iter in 1:maxi
    x = spmaximum(G_broadcast_mult_c(G, transpose(c)), 1)
    c = max.(c, x)
  end
  fin = time_ns()
  duration_reading = (fin - start_reading) * 1e-9
  duration_compute = (fin - start_compute) * 1e-9
  println("$(duration_reading),$(duration_compute),$(sum(c))")
end

@assert(length(ARGS) == 1)
filename = ARGS[1]
maxi = 100
cc(filename, maxi)
