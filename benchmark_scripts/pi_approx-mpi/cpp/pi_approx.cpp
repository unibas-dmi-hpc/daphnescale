#include <iostream>
#include <chrono>
#include <iomanip>
#include <algorithm>
#include <mpi.h>

long long compute_chunksize(long long n, int num_workers) {
    long long chunk = n / num_workers;
    if (n % num_workers != 0)
        chunk += 1;
    return chunk;
}

double approx_pi(long long num_intervals, int rank, int size) {
    long long chunk = compute_chunksize(num_intervals, size);
    double w = 1.0 / num_intervals;

    long long start = rank * chunk;
    long long end   = std::min(start + chunk, num_intervals);

    double local_pi = 0.0;
    for (long long i = start; i < end; ++i) {
        double local = (i + 0.5) * w;
        local_pi += 4.0 / (1.0 + local * local);
    }

    double pi = 0.0;
    MPI_Reduce(&local_pi, &pi, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        return pi * w;
    } else {
        return 0.0; // Non-root processes return 0
    }
}

// Main
int main(int argc, char** argv) {

    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm comm = MPI_COMM_WORLD;
    MPI_Comm_rank(comm, &rank);
    MPI_Comm_size(comm, &size);

    if (argc != 2) {
        std::cout << "Usage: bin NUM_INTERVALS" << std::endl;
        MPI_Finalize();
        return 1;
    }

    auto start_data = std::chrono::high_resolution_clock::now();
    int num_intervals = atoi(argv[1]);

    auto start_compute = std::chrono::high_resolution_clock::now();
    double pi = approx_pi(num_intervals, rank, size);
    auto stop = std::chrono::high_resolution_clock::now();

    if (rank == 0) { // Only root process prints
        auto duration_compute = std::chrono::duration<float>(stop - start_compute); // only compute time
        auto duration_ete = std::chrono::duration<float>(stop - start_data); // end-to-end
        std::cout << duration_ete.count() << "," << duration_compute.count() << "," << std::setprecision (16) << pi << std::endl;
    }
    MPI_Finalize();
    return 0;    
}