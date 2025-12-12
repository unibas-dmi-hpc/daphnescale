using Random
using Base.Threads

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
    particles = 1:nb_particles .|> (x -> Particle(rand(Float64, 1) * 100.0..., rand(Float64, 6)...))

    before_compute = time()
    for t in 1:nb_timesteps
        for i in 1:nb_particles
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
            particles[i].accx = sum(accx)
            particles[i].accy = sum(accy)
        end

        @threads for i in 1:nb_particles
            update_velocity!(particles[i])
            update_position!(particles[i])
            reset_force!(particles[i])
        end

    end
    fin = time()
    duration_ete = fin - before
    duration_compute = fin - before_compute
    println("$(duration_ete), $(duration_compute), $(particles[1].posx)")
end

main()
