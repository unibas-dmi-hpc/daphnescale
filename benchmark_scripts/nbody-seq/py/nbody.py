import sys
import time
from random import random, seed
from math import sqrt

DELTA_TIME=1
CONST_G=1


class Particle:
    def __init__(self, mass, posx, posy, velx, vely, accx, accy):
        self.mass = mass
        self.posx = posx
        self.posy = posy
        self.velx = velx
        self.vely = vely
        self.accx = accx
        self.accy = accy

    def distance(self, other):
        return sqrt((self.posx-other.posx)**2 + (self.posy-other.posy)**2)

    def update_position(self):
        self.posx += self.velx * DELTA_TIME
        self.posy += self.vely * DELTA_TIME

    def update_velocity(self):
        self.velx += self.accx/self.mass * DELTA_TIME
        self.vely += self.accy/self.mass * DELTA_TIME

    def update_acceleration(self, other):
        dist = self.distance(other)
        f = CONST_G * (self.mass * other.mass) / (dist**2)
        self.accx += f * (other.posx - self.posx) / dist
        self.accy += f * (other.posy - self.posy) / dist

    def reset_force(self):
        self.accx = 0.0
        self.accy = 0.0

def random_particle():
    return Particle(100.0*random(),\
                    random(), random(),\
                    random(), random(),\
                    random(), random())

def main():
    args = sys.argv
    assert len(args) == 3
    nb_particles = int(args[1])
    nb_timesteps = int(args[2])
    start_data = time.time()

    seed(0)
    particles = [random_particle() for _ in range(nb_particles)]

    start_compute = time.time()
    for t in range(1,nb_timesteps+1):
        for i in range(nb_particles):
            for j in range(i+1, nb_particles):
                particles[i].update_acceleration(particles[j])
                particles[j].update_acceleration(particles[i])
        for i in range(nb_particles):
            particles[i].update_velocity()
            particles[i].update_position()
            particles[i].reset_force()
    end = time.time()
    duration_ete = end - start_data
    duration_sort = end - start_compute
    print(f"{duration_ete},{duration_sort},{particles[0].posx}")

if __name__ == "__main__":
    main()
