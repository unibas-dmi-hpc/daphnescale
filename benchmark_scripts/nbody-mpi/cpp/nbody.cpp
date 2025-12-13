#include <iostream>
#include <cmath>
#include <vector>
#include <chrono>
#include <mpi.h>
#include <iomanip>

#define DELTA_TIME 1.0
#define CONST_G 1.0

class Particle {
    public:
        double mass;
        double posx;
        double posy;
        double velx;
        double vely;
        double accx;
        double accy;

        double distance(Particle other);
        void update_position();
        void update_velocity();
        void update_acceleration(Particle other);
        void reset_force();

        Particle(double m, double x, double y, double vx, double vy, double ax, double ay) {
            mass = m;
            posx = x; posy = y;
            velx = vx; vely = vy;
            accx = ax; accy = ay;
        }
};

double Particle::distance(Particle other) {
    return sqrt(pow(posx - other.posx,2) + pow(posy - other.posy,2));
}

void Particle::update_position() {
    posx += velx * DELTA_TIME;
    posy += vely * DELTA_TIME;
}

void Particle::update_velocity() {
    velx += accx/mass * DELTA_TIME;
    vely += accy/mass * DELTA_TIME;
}

void Particle::update_acceleration(Particle other) {
    double dist = this->distance(other);
    double f = CONST_G*(mass * other.mass)/(pow(dist,2));

    accx += f * (other.posx - posx) / dist;
    accy += f * (other.posy - posy) / dist;
}

void Particle::reset_force() {
    accx = 0.0;
    accy = 0.0;
}

double _rand() {
    return (double) std::rand() / RAND_MAX;
}

Particle rand_particle() {
    return Particle(100.0 * _rand(), _rand(), _rand(), _rand(), _rand(), _rand(), _rand());
}

int B[7] = {1, 1, 1, 1, 1, 1, 1};
MPI_Aint D[7] = {
    0,
    1*sizeof(double),
    2*sizeof(double),
    3*sizeof(double),
    4*sizeof(double),
    5*sizeof(double),
    6*sizeof(double)
};
MPI_Datatype T[7] = {
    MPI_DOUBLE,
    MPI_DOUBLE,
    MPI_DOUBLE,
    MPI_DOUBLE,
    MPI_DOUBLE,
    MPI_DOUBLE,
    MPI_DOUBLE,
};

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    // if (argc != 3) {
    //     fprintf(stderr, "USAGE: %s nb_particles nb_timesteps\n", argv[0]);
    //     return 1;
    // }
    int nb_particles = atoi(argv[1]);
    int nb_timesteps = atoi(argv[2]);
    auto begin = std::chrono::high_resolution_clock::now();

    int world;
    int rank;
    MPI_Comm_size(MPI_COMM_WORLD, &world);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    MPI_Datatype mpi_dt_particle;
    MPI_Type_create_struct(7, B, D, T, &mpi_dt_particle);
    MPI_Type_commit(&mpi_dt_particle);

    std::srand(0);
    std::vector<Particle> particles = {};
    particles.reserve(nb_particles);

    if (rank == 0) {
        // is there a more c++ way to do this ?
        for (int i = 0; i < nb_particles; i++) {
            particles.push_back(rand_particle());
        }
    }

    std::vector<int> sizes;
    std::vector<int> offsets;
    int cum_sum = 0;
    for (int k = 0; k < world; k++) {
        sizes.push_back(nb_particles / world);
        offsets.push_back(cum_sum);
        cum_sum += sizes[k];
    }
    sizes[world-1] = nb_particles - (world-1) * (nb_particles/world);
    MPI_Bcast(particles.data(), nb_particles, mpi_dt_particle, 0, MPI_COMM_WORLD);

    std::vector<Particle> my_particles = {};
    my_particles.reserve(sizes[rank]);

    auto begin_compute = std::chrono::high_resolution_clock::now();

    for (int ts = 1; ts <= nb_timesteps; ts++) {
        for (int i = offsets[rank]; i < offsets[rank] + sizes[rank]; i++) {
            double accx = 0.0;
            double accy = 0.0;
#pragma omp parallel for shared(particles,my_particles) reduction(+:accx) reduction(+:accy)
            for (int j = 0; j < nb_particles; j++) {
                if (i != j) {
                    double dist = particles[i].distance(particles[j]);
                    double f = CONST_G*(particles[i].mass * particles[j].mass)/(pow(dist,2));
                    accx += f * (particles[j].posx - particles[i].posx) / dist;
                    accy += f * (particles[j].posy - particles[i].posy) / dist;
                }
            }
            my_particles[i - offsets[rank]] = particles[i];
            my_particles[i - offsets[rank]].accx = accx;
            my_particles[i - offsets[rank]].accy = accy;
        }
#pragma omp parallel for shared(my_particles)
        for (int i = 0; i < sizes[rank]; i++) {
            my_particles[i].update_velocity();
            my_particles[i].update_position();
            my_particles[i].reset_force();
        }

        MPI_Allgatherv(my_particles.data(), sizes[rank], mpi_dt_particle, particles.data(), sizes.data(), offsets.data(), mpi_dt_particle, MPI_COMM_WORLD);
    }
    if (rank == 0) { 
        auto end = std::chrono::high_resolution_clock::now();
        auto duration_compute = std::chrono::duration<float>(end - begin_compute);
        auto duration_ete = std::chrono::duration<float>(end - begin);
        std::cout << duration_ete.count() << "," << duration_compute.count() << "," << std::setprecision (16) << particles[0].posx << std::endl;
    }
    MPI_Finalize();
    return 0;
}
