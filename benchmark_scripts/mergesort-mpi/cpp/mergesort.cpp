#include <mpi.h>
#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <cmath>

// Insertion sort for small arrays (right exclusive) --> the leaves of merge sort
void insertion_sort(std::vector<int>& arr, int left, int right) {
    for (int i = left + 1; i < right; ++i) {
        int key = arr[i];
        int j = i - 1;
        while (j >= left && arr[j] > key) {
            arr[j + 1] = arr[j];
            --j;
        }
        arr[j + 1] = key;
    }
}

// Merge step a[left:mid] and a[mid:right] using tmp buffer
void merge(std::vector<int>& arr, int left, int mid, int right, std::vector<int>& tmp) {
    int i = left;
    int j = mid;
    int k = left;

    while (i < mid && j < right) {
        if (arr[i] <= arr[j]) {
            tmp[k++] = arr[i++];
        } else {
            tmp[k++] = arr[j++];
        }
    }
    while (i < mid)  tmp[k++] = arr[i++];
    while (j < right) tmp[k++] = arr[j++];

    // Copy back to original array
    for (int idx = left; idx < right; ++idx) {
        arr[idx] = tmp[idx];
    }
}

// Recursive merge sort implementation
void merge_sort(std::vector<int>& arr, int left, int right, std::vector<int>& tmp, int threshold) {
    int size = right - left;
    if (size <= 1) return;

    // Base case → insertion sort
    if (size <= threshold) {
        insertion_sort(arr, left, right);
        return;
    }

    int mid = left + size / 2;

    merge_sort(arr, left, mid, tmp, threshold);
    merge_sort(arr, mid, right, tmp, threshold);
    merge(arr, left, mid, right, tmp);
}

// Compute child rank based on current depth
int compute_child(int rank, int depth, int max_depth, int size) {
    if (depth >= max_depth) return -1;
    int bit_pos = max_depth - depth - 1;
    int child = rank | (1 << bit_pos);

    if (child >= size) return -1;
    if (child == rank) return -1; // no self-child
    return child;
}

// Parallel merge sort implementation sending to ranks in recursion --> binary tree of ranks
// only the leaves do perform work (recursive merge sort, insertion sort at the bottom)
std::vector<int> merge_sort_parallel(std::vector<int> arr,
                                     int threshold,
                                     int max_depth,
                                     int depth,
                                     int rank,
                                     int size,
                                     MPI_Comm comm) {
    int n = static_cast<int>(arr.size());

    // decide whether to use MPI child or do local sort
    int child = compute_child(rank, depth, max_depth, size);
    if (child == -1 || n <= threshold) {
        std::vector<int> tmp(n);
        merge_sort(arr, 0, n, tmp, threshold);
        return arr;
    }

    int mid = n / 2;
    std::vector<int> left_part(arr.begin(), arr.begin() + mid);
    std::vector<int> right_part(arr.begin() + mid, arr.end());

    // send right part to child
    int right_size = static_cast<int>(right_part.size());
    MPI_Send(&right_size, 1, MPI_INT, child, depth, comm);
    if (right_size > 0) {
        MPI_Send(right_part.data(), right_size, MPI_INT, child, depth, comm);
    }

    // sort left part locally
    std::vector<int> sorted_left =
        merge_sort_parallel(left_part, threshold, max_depth, depth + 1,
                            rank, size, comm);

    // receive sorted right part from child
    MPI_Status status;
    int recv_size = 0;
    MPI_Recv(&recv_size, 1, MPI_INT, child, depth, comm, &status);

    std::vector<int> sorted_right(recv_size);
    if (recv_size > 0) {
        MPI_Recv(sorted_right.data(), recv_size, MPI_INT,
                 child, depth, comm, &status);
    }

    // merge sorted parts
    std::vector<int> merged;
    merged.reserve(sorted_left.size() + sorted_right.size());
    merged.insert(merged.end(), sorted_left.begin(), sorted_left.end());
    merged.insert(merged.end(), sorted_right.begin(), sorted_right.end());

    std::vector<int> tmp(merged.size());
    merge(merged, 0, static_cast<int>(sorted_left.size()),
          static_cast<int>(merged.size()), tmp);

    return merged;
}

// Main
int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm comm = MPI_COMM_WORLD;
    MPI_Comm_rank(comm, &rank);
    MPI_Comm_size(comm, &size);

    // Argument check on all ranks
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " SIZE THRESHOLD\n";
        MPI_Finalize();
        return 1;
    }

    int N = std::atoi(argv[1]);
    int threshold = std::atoi(argv[2]);

    int max_depth = static_cast<int>(std::floor(std::log2(size)));

    if (rank == 0) {
        auto start_gen = std::chrono::high_resolution_clock::now();
        // Problem to sort (Reverse sorted array N,...,1)
        std::vector<int> arr(N);
        for (int i = 0; i < N; ++i) arr[i] = N - i;

        auto start_sort = std::chrono::high_resolution_clock::now();
        std::vector<int> sorted_arr =
                merge_sort_parallel(arr, threshold, max_depth, 0, rank, size, comm);

        auto stop = std::chrono::high_resolution_clock::now();

        // Correctness check: H = Sum^{N-1}_{i=0} (i * arr[i}) <=> H = N(N-1)(N+1)/3
        long long H = 0;
        for (int i = 0; i < N; ++i) {
            H += 1LL * i * sorted_arr[i];
        }
        double c = (double)H / ((double)N * N * N);// To avoid printing large numbers

        auto duration_sort = std::chrono::duration<float>(stop - start_sort); // only compute time
        auto duration_ete = std::chrono::duration<float>(stop - start_gen); // end-to-end
        std::cout << duration_ete.count() << "," << duration_sort.count() << "," << std::setprecision (16) << c << std::endl;

        // Tell all workers to stop
        for (int r = 1; r < size; ++r) {
            MPI_Send(nullptr, 0, MPI_INT, r, 999, comm);
        }

    } else {
        MPI_Status status;

        while (true) {
            // Probe to see what message is coming
            MPI_Probe(MPI_ANY_SOURCE, MPI_ANY_TAG, comm, &status);
            int tag = status.MPI_TAG;
            int parent = status.MPI_SOURCE;

            if (tag == 999) {
                // termination signal; receive and break
                MPI_Recv(nullptr, 0, MPI_INT, parent, tag, comm, &status);
                break;
            }

            // receive size, then data
            int n = 0;
            MPI_Recv(&n, 1, MPI_INT, parent, tag, comm, &status);
            std::vector<int> data(n);
            if (n > 0) {
                MPI_Recv(data.data(), n, MPI_INT, parent, tag, comm, &status);
            }

            int depth = tag;
            std::vector<int> sorted =
                merge_sort_parallel(data, threshold, max_depth, depth + 1,
                                    rank, size, comm);

            int out_n = static_cast<int>(sorted.size());
            MPI_Send(&out_n, 1, MPI_INT, parent, depth, comm);
            if (out_n > 0) {
                MPI_Send(sorted.data(), out_n, MPI_INT, parent, depth, comm);
            }
        }
    }
    MPI_Finalize();
    return 0;    
}