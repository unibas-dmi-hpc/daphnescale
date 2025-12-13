#include <iostream>
#include <cmath>
#include <vector>
#include <chrono>
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


int main(int argc, char** argv) {
    // if (argc != 3) {
    //     fprintf(stderr, "USAGE: %s nb_particles nb_timesteps\n", argv[0]);
    //     return 1;
    // }
    int nb_particles = atoi(argv[1]);
    int nb_timesteps = atoi(argv[2]);

    auto begin = std::chrono::high_resolution_clock::now();

    std::srand(0);
    std::vector<Particle> particles = {};
    particles.reserve(nb_particles);
    // is there a more c++ way to do this ?
    for (int i = 0; i < nb_particles; i++) {
        particles.push_back(rand_particle());
    }

    auto begin_compute = std::chrono::high_resolution_clock::now();

    for (int ts = 1; ts <= nb_timesteps; ts++) {
        for (int i = 0; i < nb_particles; i++) {
            for (int j = i+1; j < nb_particles; j++) {
                particles[i].update_acceleration(particles[j]);
                particles[j].update_acceleration(particles[i]);
            }
        }
        for (int i = 0; i < nb_particles; i++) {
            particles[i].update_velocity();
            particles[i].update_position();
            particles[i].reset_force();
        }
    }
    auto end = std::chrono::high_resolution_clock::now();
    auto duration_compute = std::chrono::duration<float>(end - begin_compute);
    auto duration_ete = std::chrono::duration<float>(end - begin);
    std::cout << duration_ete.count() << "," << duration_compute.count() << "," << std::setprecision (16) << particles[0].posx << std::endl;
    return 0;
}
