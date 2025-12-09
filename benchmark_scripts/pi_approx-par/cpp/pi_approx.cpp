#include <iostream>
#include <chrono>
#include <iomanip>
#include <algorithm>
#include <omp.h>

long long compute_chunksize(long long n, int num_threads) {
    long long chunk = n / num_threads;
    if (n % num_threads != 0)
        chunk += 1;
    return chunk;
}

double approx_pi(long long num_intervals, int num_threads) {
    long long chunk = compute_chunksize(num_intervals, num_threads);
    double pi = 0.0;
    double w = 1.0 / num_intervals;

    // Parallel region and not parallel for to match other languages chunking logic
    #pragma omp parallel num_threads(num_threads) reduction(+:pi)
    {
        int tid = omp_get_thread_num();
        long long start = tid * chunk;
        long long end   = std::min(start + chunk, num_intervals);

        for (long long i = start; i < end; ++i) {
            double local = (i + 0.5) * w;
            pi += 4.0 / (1.0 + local * local);
        }
    }

    return pi * w;
}

// Main
int main(int argc, char** argv) {
    if (argc != 3) {
        std::cout << "Usage: bin NUM_INTERVALS NUM_THREADS" << std::endl;
        return 1;
    }

    auto start_data = std::chrono::high_resolution_clock::now();
    int num_intervals = atoi(argv[1]);
    int num_threads = atoi(argv[2]);

    auto start_compute = std::chrono::high_resolution_clock::now();
    double pi = approx_pi(num_intervals, num_threads);
    auto stop = std::chrono::high_resolution_clock::now();

    auto duration_compute = std::chrono::duration<float>(stop - start_compute); // only compute time
    auto duration_ete = std::chrono::duration<float>(stop - start_data); // end-to-end
    std::cout << duration_ete.count() << "," << duration_compute.count() << "," << std::setprecision (16) << pi << std::endl;
    return 0;    
}