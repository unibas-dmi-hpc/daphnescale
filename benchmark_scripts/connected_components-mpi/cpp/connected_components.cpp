#include <iostream>
#include <Eigen/SparseCore>
#include <Eigen/Dense>
#include <Eigen/Sparse>
#include <Eigen/Core>
#include <unsupported/Eigen/SparseExtra>
#include <chrono>
#include <iomanip>
#include <mpi.h>

#define MAX(x, y) ((x) < (y)) ? (y) : (x)

typedef Eigen::SparseMatrix<double, Eigen::RowMajor> SpMatR;
typedef SpMatR::InnerIterator InIterMatR;
typedef Eigen::Triplet<double> T;

SpMatR G_broadcast_mult_c(SpMatR G, Eigen::VectorXd c) {
  SpMatR res = SpMatR(G);
  for (int row_id = 0; row_id < G.outerSize(); row_id++) {
    for (InIterMatR i_(G, row_id); i_; ++i_) {
      res.coeffRef(row_id, i_.col()) *= c.coeff(i_.col());
    }
  }
  return res;
}

Eigen::VectorXd spmaximum(SpMatR G) {
  int n = G.rows();
  Eigen::VectorXd res = Eigen::VectorXd::Zero(n);
  for (int row_id = 0; row_id < G.outerSize(); row_id++) {
    for (InIterMatR i_(G, row_id); i_; ++i_) {
      auto tmp = G.coeff(row_id, i_.col());
      if (tmp > res.coeff(row_id)) {
        res.coeffRef(row_id) = tmp;
      }
    }
  }
  return res;
}

SpMatR read_and_send_matrix(std::string filename, int n) {
  int world;
  int rank;
  MPI_Comm_size(MPI_COMM_WORLD, &world);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  if (rank == 0) {
    SpMatR G(n, n); 
    if (!loadMarket(G, filename))
      std::cout << "could  not load mtx file" << std::endl;

    // if there is only one rank (world == 1), just retutrn G and no partition.
    if (world == 1) {
      return G;  // no distribution needed
    }

    int nb_sub = world;

    std::vector<T> content;
    std::vector<T> content0;
    std::vector<int> sizes;
    content.resize(G.nonZeros());
    content0.resize(G.nonZeros());
    sizes.resize(nb_sub);
    for (int i = 0; i < nb_sub; i++) {
      sizes[i] = n / nb_sub;
    }
    sizes[nb_sub - 1] = n - (nb_sub-1) * (n / nb_sub);
    int remainder = n % nb_sub;

    int previous_k = 0;
    int k = 0;
    for (int row_id = 0; row_id < G.outerSize(); row_id++) {
      previous_k = k;
      k = row_id / (n / nb_sub); 
      if (k > nb_sub - 1) k = nb_sub - 1;
      if (previous_k != 0 && previous_k != k) {
        int nb_elems = content.size();
        MPI_Send(&sizes[previous_k], 1, MPI_INT, previous_k, 0, MPI_COMM_WORLD);
        MPI_Send(&nb_elems, 1, MPI_INT, previous_k, 1, MPI_COMM_WORLD);
        MPI_Send(&content[0], nb_elems * sizeof(T), MPI_CHAR, previous_k, 2, MPI_COMM_WORLD);
        content.clear();
      }
      for (SpMatR::InnerIterator it(G,row_id); it; ++it)
      {
        if (k == 0) {
          content0.push_back(T(row_id - k * (n/nb_sub), it.col(), it.value()));
        } else {
          content.push_back(T(row_id - k * (n/nb_sub), it.col(), it.value()));
        }
      }
    }
    int nb_elems = content.size();
    MPI_Send(&sizes[nb_sub-1], 1, MPI_INT, nb_sub-1, 0, MPI_COMM_WORLD);
    MPI_Send(&nb_elems, 1, MPI_INT, nb_sub-1, 1, MPI_COMM_WORLD);
    MPI_Send(&content[0], nb_elems * sizeof(T), MPI_CHAR, nb_sub-1, 2, MPI_COMM_WORLD);
    content.clear();

    // for (int k = 1; k < world; k++) {
    //   int nb_elems = content[k].size();
    //   MPI_Send(&sizes[k], 1, MPI_INT, k, 0, MPI_COMM_WORLD);
    //   MPI_Send(&nb_elems, 1, MPI_INT, k, 1, MPI_COMM_WORLD);
    //   MPI_Send(&content[k][0], nb_elems * sizeof(T), MPI_CHAR, k, 2, MPI_COMM_WORLD);
    // }
    SpMatR Gs((sizes[0]), n);
    Gs.setFromTriplets(content0.begin(), content0.end());
    // std::cout << "rank " << rank << "\n" << Gs << "\n\n";
    return Gs;
  } else {
    int nb_elems = 0;
    int size = 0;
    MPI_Recv(&size, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    MPI_Recv(&nb_elems, 1, MPI_INT, 0, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    std::vector<T> content;
    content.resize(nb_elems);
    MPI_Recv(&content[0], nb_elems*sizeof(T), MPI_CHAR, 0, 2, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    SpMatR Gs(size, n);
    Gs.setFromTriplets(content.begin(), content.end());
    //std::cout << "rank " << rank << "\n" << Gs << "\n\n";
    return Gs;
  }
}

void reduce_max(double *in, double *inout, int *len, MPI_Datatype *datatype) {
  Eigen::Map<Eigen::VectorXd> x(in, *len);
  Eigen::Map<Eigen::VectorXd> y(inout, *len);
  y = y.cwiseMax(x);
} 

int main(int argc, char** argv) {
  MPI_Init(&argc, &argv);
  if (argc != 3) {
    std::cout << "Usage: bin mat.mtx size" << std::endl;
    return 1;
  }
  std::string filename = argv[1];

  int n = atoi(argv[2]);

  int world;
  int rank;
  MPI_Comm_size(MPI_COMM_WORLD, &world);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  std::vector<int> sizes;
  std::vector<int> offsets;
  int cum_sum = 0;
  for (int k = 0; k < world; k++) {
    sizes.push_back(n / world);
    offsets.push_back(cum_sum);
    cum_sum += sizes[k];
  }
  sizes[world-1] = n - (world-1) * (n/world);

  auto start_reading = std::chrono::high_resolution_clock::now();
  SpMatR G = read_and_send_matrix(filename, n);
  auto start_compute = std::chrono::high_resolution_clock::now();

  MPI_Op myOp;
  MPI_Op_create((MPI_User_function*)reduce_max, true, &myOp);


  Eigen::VectorXd c_partial(n);
  Eigen::VectorXd c(n);
  for (int i = 0; i < n; i++) {
    c(i) = (double)(i + 1);
  }

  Eigen::VectorXd x(n);

  for (int iter = 0; iter < 100; iter++) {
    SpMatR tmp = G_broadcast_mult_c(G, c);
    Eigen::VectorXd x_partial = spmaximum(tmp);
    MPI_Allgatherv(x_partial.data(), sizes[rank], MPI_DOUBLE, x.data(), sizes.data(), offsets.data(), MPI_DOUBLE, MPI_COMM_WORLD);
    c = c.cwiseMax(x);
  }
  auto stop = std::chrono::high_resolution_clock::now();
  auto duration_compute = std::chrono::duration<float>(stop - start_compute);
  auto duration_reading = std::chrono::duration<float>(stop - start_reading);
  if (rank == 0) {
    std::cout << duration_reading.count() << "," << duration_compute.count() << "," << std::setprecision (16) << c.sum() << std::endl;
  }
  MPI_Finalize();
  return 0;
}
