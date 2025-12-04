using Random
using Base.Threads

DELTA_TIME=1
CONST_G=1

mutable struct Particle{T<:Real}
    mass::T
    posx::T
    posy::T
    velx::T
    vely::T
    accx::T
    accy::T
end

function distance(p1::Particle, p2::Particle)::Real
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

function simulate(nb_particles::Int, nb_timesteps::Int)
    particles = 0:nb_particles .|> (x -> Particle(rand(Float64, 1) * 100.0..., rand(Float64, 6)...))
    for t in 1:nb_timesteps
        before = time()
        # Computing new forces
        for i in 1:nb_particles
            p1 = particles[i]
            accx = Threads.Atomic{Float64}(p1.accx)
            accy = Threads.Atomic{Float64}(p1.accy)
            @threads for j in 1:nb_particles
                if i != j
                    p2 = particles[j]
                    dist = distance(p1, p2);
                    f = CONST_G*(p1.mass * p2.mass)/(dist^2);
                    Threads.atomic_add!(accx, f * (p2.posx - p1.posx) / dist)
                    Threads.atomic_add!(accy, f * (p2.posy - p1.posy) / dist)
                end
            end
            particles[i].accx = accx[]
            particles[i].accy = accy[]
        end
        # Updating the rest
        @threads for i in 1:nb_particles
            update_velocity!(particles[i])
            update_position!(particles[i])
            reset_force!(particles[i])
        end
        elapsed = time() - before
        println("[$(t)/$(nb_timesteps)] $(elapsed) $(particles[1].posx)")
    end
end


function main()
    Random.seed!(0)
    nb_particles = 1000
    nb_timesteps = 10
    simulate(nb_particles, nb_timesteps)
end

main()
