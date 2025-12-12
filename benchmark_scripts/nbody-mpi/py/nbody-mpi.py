import sys
import time
import numpy as np
from random import random, seed
from math import sqrt, ceil
from multiprocessing.pool import ThreadPool

DELTA_TIME=1
CONST_G=1

from mpi4py import MPI
from mpi4py.util import dtlib

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
world = comm.Get_size()

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

def worker_compute(tt):
    particles, i, start, end = tt
    nb_particles = len(particles)
    accx = 0.0
    accy = 0.0
    for j in range(start, min(end, nb_particles)):
        if i != j:
            dist = particles[i].distance(particles[j])
            f = CONST_G * (particles[i].mass * particles[j].mass) / (dist**2)
            accx += f * (particles[j].posx - particles[i].posx) / dist
            accy += f * (particles[j].posy - particles[i].posy) / dist
    return (accx, accy)

def worker_update(tt):
    particles, start, end = tt
    for i in range(start, min(end, len(particles))):
        particles[i].update_velocity()
        particles[i].update_position()
        particles[i].reset_force()

def particle_to_buffer(particle):
    return np.array([
        particle.mass, particle.posx, particle.posy,
        particle.velx, particle.vely, particle.accx, particle.accy
    ], dtype=np.float64)

def buffer_to_particle(buffer):
    return Particle(*buffer)

def main():
    args = sys.argv
    assert len(args) == 4
    nb_particles = int(args[1])
    nb_timesteps = int(args[2])
    num_threads = int(args[3])
    start_data = time.time()
    w = ceil(1.0 * nb_particles / num_threads)

    sizes = [0 for _ in range(world)];
    offsets = [0 for _ in range(world)];
    cum_sum = 0;
    for k in range(world):
        sizes[k] = nb_particles // world
        offsets[k] = cum_sum
        cum_sum += sizes[k]
    sizes[world-1] = nb_particles - (world-1) * (nb_particles//world)

    sizes_doubles = [s * 7 for s in sizes]
    offsets_doubles = [o * 7 for o in offsets]

    seed(0)
    particles = None
    sendbuf = None
    if rank == 0:
        particles = np.array([random_particle() for _ in range(nb_particles)])
        sendbuf = np.concatenate([particle_to_buffer(p) for p in particles])
    particles = comm.bcast(particles, 0)
    sendbuf = comm.bcast(sendbuf, root=0)
    particles = np.array([
        buffer_to_particle(sendbuf[i*7:(i+1)*7])
        for i in range(nb_particles)
    ])

    my_particles = np.array([particles[i] for i in range(offsets[rank], offsets[rank]+sizes[rank])])

    start_compute = time.time()
    with ThreadPool(processes=num_threads) as pool:
        for t in range(1,nb_timesteps+1):
            for i in range(offsets[rank], offsets[rank] + sizes[rank]):
                results = pool.map(worker_compute, [(particles, i, start, start + w) for start in range(0, nb_particles,w)])
                acc = [sum(tup) for tup in zip(*results)]
                my_particles[i-offsets[rank]].accx = acc[0]
                my_particles[i-offsets[rank]].accy = acc[1]

            w_update = ceil(sizes[rank]*1.0/num_threads)
            _ = pool.map(worker_update, [(my_particles, start, start + w_update) for start in range(0, sizes[rank],w_update)])

            sendbuf = np.concatenate([particle_to_buffer(p) for p in my_particles])
            recvbuf = np.empty(sum(sizes) * 7, dtype=np.float64)
            comm.Allgatherv(
                [sendbuf, MPI.DOUBLE],
                [recvbuf, sizes_doubles, offsets_doubles, MPI.DOUBLE]
            )
            particles = np.array([
                buffer_to_particle(recvbuf[i*7:(i+1)*7])
                for i in range(nb_particles)
            ])

    if rank == 0:
        end = time.time()
        duration_ete = end - start_data
        duration_sort = end - start_compute
        print(f"{duration_ete},{duration_sort},{particles[0].posx}")

if __name__ == "__main__":
    main()
