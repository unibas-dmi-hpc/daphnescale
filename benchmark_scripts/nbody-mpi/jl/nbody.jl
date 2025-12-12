using Random
using Base.Threads

using MPI
MPI.Init()

comm = MPI.COMM_WORLD

DELTA_TIME=1.0
CONST_G=1.0

mutable struct Particle
    mass::Float64
    posx::Float64
    posy::Float64
    velx::Float64
    vely::Float64
    accx::Float64
    accy::Float64
end

function distance(p1::Particle, p2::Particle)::Float64
    return sqrt((p1.posx - p2.posx)^2 + (p1.posy - p2.posy)^2)
end

function update_position!(p::Particle)
    p.posx = p.posx + p.velx * DELTA_TIME;
    p.posy = p.posy + p.vely * DELTA_TIME; 
end

function update_velocity!(p::Particle)
    p.velx = p.velx + p.accx/p.mass * DELTA_TIME;
    p.vely = p.vely + p.accy/p.mass * DELTA_TIME; 
end

function update_acceleration!(p1::Particle, p2::Particle)
    dist = distance(p1, p2);
    f = CONST_G*(p1.mass * p2.mass)/(dist^2);

    p1.accx = p1.accx + f * (p2.posx - p1.posx) / dist 
    p1.accy = p1.accy + f * (p2.posy - p1.posy) / dist
end

function reset_force!(p::Particle)
    p.accx = 0.0
    p.accy = 0.0
end

function main()
    nb_particles = parse(Int64, ARGS[1])
    nb_timesteps = parse(Int64, ARGS[2])
    before = time()
    Random.seed!(0)
    rank = MPI.Comm_rank(comm)
    world = MPI.Comm_size(comm)
    particles = nothing
    if rank == 0
        particles = 1:nb_particles .|> (x -> Particle(rand(Float64, 1) * 100.0..., rand(Float64, 6)...))
    end

    sizes = fill(0, world)
    offsets = fill(0, world)
    cum_sum = 0
    for k in 1:world
        sizes[k] = div(nb_particles, world)
        offsets[k] = cum_sum
        cum_sum += sizes[k]
    end
    sizes[world] = nb_particles - (world-1) * (div(nb_particles, world))
    particles = MPI.bcast(particles, 0, comm)
    my_particles = Vector{Particle}(undef, sizes[rank+1])

    before_compute = time()
    for t in 1:nb_timesteps
        for i in (1+offsets[rank+1]):(offsets[rank+1] + sizes[rank+1])
            accx = zeros(Float64, nthreads())
            accy = zeros(Float64, nthreads())
            @threads for j in 1:nb_particles
                if i != j
                    dist = distance(particles[i], particles[j]);
                    f = CONST_G*(particles[i].mass * particles[j].mass)/(dist^2);
                    accx[threadid()] += f * (particles[j].posx - particles[i].posx) / dist 
                    accy[threadid()] += f * (particles[j].posy - particles[i].posy) / dist
                end
            end
            my_particles[i - offsets[rank+1]] = particles[i]
            my_particles[i - offsets[rank+1]].accx = sum(accx)
            my_particles[i - offsets[rank+1]].accy = sum(accy)
        end

        @threads for i in 1:sizes[rank+1]
            update_velocity!(my_particles[i])
            update_position!(my_particles[i])
            reset_force!(my_particles[i])
        end

        sendbuf = vcat([Float64[p.mass, p.posx, p.posy, p.velx, p.vely, p.accx, p.accy] for p in my_particles]...)
        recvbuf = MPI.VBuffer(Vector{Float64}(undef, nb_particles*7), sizes .* 7, offsets .* 7)
        MPI.Allgatherv!(sendbuf, recvbuf, comm)
        particles = [Particle(recvbuf.data[7i+1:7i+7]...) for i in 0:nb_particles-1]

    end
    if rank == 0
        fin = time()
        duration_ete = fin - before
        duration_compute = fin - before_compute
        println("$(duration_ete), $(duration_compute), $(particles[1].posx)")
    end
end

main()
