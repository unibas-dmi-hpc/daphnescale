#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <thread>
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

// Parallel merge sort implementation spawning threads in recursion --> binary tree of threads
// only the leaves do perform work (recursive merge sort, insertion sort at the bottom)
void merge_sort_parallel(std::vector<int>& arr, int left, int right, std::vector<int>& tmp, int threshold, int max_depth, int depth) {
    int size = right - left;
    if (size <= 1) return;

    // Base case → insertion sort
    if (size <= threshold) {
        insertion_sort(arr, left, right);
        return;
    }

    int mid = left + size / 2;

    if (depth < max_depth) {
        std::thread left_thread(merge_sort_parallel, std::ref(arr), left, mid, std::ref(tmp), threshold, max_depth, depth + 1);
        std::thread right_thread(merge_sort_parallel, std::ref(arr), mid, right, std::ref(tmp), threshold, max_depth, depth + 1);
        // wait for them to join
        left_thread.join();
        right_thread.join();
    } else {
        merge_sort(arr, left, mid, tmp, threshold);
        merge_sort(arr, mid, right, tmp, threshold);
    }

    merge(arr, left, mid, right, tmp);
}

// Sort function to call from main
void sort(std::vector<int>& arr, int threshold, int workers) {
    std::vector<int> tmp(arr.size());
    int max_depth = std::floor(std::log2(workers));  // the max depth to spawn threads
    int depth = 0;
    merge_sort_parallel(arr, 0, arr.size(), tmp, threshold, max_depth, depth);
}

// Main
int main(int argc, char** argv) {
    if (argc != 4) {
        std::cout << "Usage: bin SIZE THRESHOLD N_WORKERS" << std::endl;
        return 1;
    }
    // Problem size
    int N = atoi(argv[1]);
    // Threshold for switching to insertion sort (good value ~ 32)
    int threshold = atoi(argv[2]);
    // Workers (ranks/cpuCores)
    int workers = atoi(argv[3]);

    auto start_gen = std::chrono::high_resolution_clock::now();
    // Problem to sort (Reverse sorted array N,...,1)
    std::vector<int> arr(N);
    for (int i = 0; i < N; ++i) arr[i] = N - i;

    auto start_sort = std::chrono::high_resolution_clock::now();
    sort(arr, threshold, workers);
    auto stop = std::chrono::high_resolution_clock::now();

    // Correctness check: H = Sum^{N-1}_{i=0} (i * arr[i}) <=> H = N(N-1)(N+1)/3
    long long H = 0;
    for (int i = 0; i < N; ++i) {
        H += 1LL * i * arr[i];
    }
    double c = (double)H / ((double)N * N * N);// To avoid printing large numbers

    auto duration_sort = std::chrono::duration<float>(stop - start_sort); // only compute time
    auto duration_ete = std::chrono::duration<float>(stop - start_gen); // end-to-end
    std::cout << duration_ete.count() << "," << duration_sort.count() << "," << std::setprecision (16) << c << std::endl;
    return 0;    
}