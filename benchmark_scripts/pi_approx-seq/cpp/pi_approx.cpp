#include <iostream>
#include <chrono>
#include <iomanip>

// Insertion sort for small arrays (right exclusive) --> the leaves of merge sort
double approx_pi(long long num_intervals) {
    double pi = 0.0;
    double w = 1.0 / num_intervals;

    for (long long i = 0; i < num_intervals; ++i) {
        double local = (i + 0.5) * w;
        pi += 4.0 / (1.0 + local * local);
    }
    return pi * w;
}

// Main
int main(int argc, char** argv) {
    if (argc != 2) {
        std::cout << "Usage: bin NUM_INTERVALS" << std::endl;
        return 1;
    }

    auto start_data = std::chrono::high_resolution_clock::now();
    int num_intervals = atoi(argv[1]);

    auto start_compute = std::chrono::high_resolution_clock::now();
    double pi = approx_pi(num_intervals);
    auto stop = std::chrono::high_resolution_clock::now();

    auto duration_compute = std::chrono::duration<float>(stop - start_compute); // only compute time
    auto duration_ete = std::chrono::duration<float>(stop - start_data); // end-to-end
    std::cout << duration_ete.count() << "," << duration_compute.count() << "," << std::setprecision (16) << pi << std::endl;
    return 0;    
}