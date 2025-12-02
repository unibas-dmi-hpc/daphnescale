#include <iostream>
#include <Eigen/SparseCore>
#include <Eigen/Dense>
#include <Eigen/Sparse>
#include <Eigen/Core>
#include <unsupported/Eigen/SparseExtra>
#include <chrono>
#include <iomanip>

typedef Eigen::SparseMatrix<double, Eigen::RowMajor> SpMatR;
typedef SpMatR::InnerIterator InIterMatR;

SpMatR G_broadcast_mult_c(SpMatR G, Eigen::VectorXd c) {
  SpMatR res = SpMatR(G);
  #pragma omp parallel for
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

int main(int argc, char** argv) {
  if (argc != 3) {
    std::cout << "Usage: bin mat.mtx size" << std::endl;
    return 1;
  }
  std::string filename = argv[1];

  int n = atoi(argv[2]);

  auto start_reading = std::chrono::high_resolution_clock::now();
  SpMatR G(n, n); 
  if (!loadMarket(G, filename))
    std::cout << "could  not load mtx file" << std::endl;
  auto start_compute = std::chrono::high_resolution_clock::now();

  Eigen::VectorXd c(n);
  for (int i = 0; i < n; i++) {
    c(i) = (double)(i + 1);
  }

  for (int iter = 0; iter < 100; iter++) {
    SpMatR tmp = G_broadcast_mult_c(G, c);
    Eigen::VectorXd x = spmaximum(tmp);
    c = c.cwiseMax(x);
  }
  auto stop = std::chrono::high_resolution_clock::now();
  auto duration_compute = std::chrono::duration<float>(stop - start_compute);
  auto duration_reading = std::chrono::duration<float>(stop - start_reading);
  std::cout << duration_reading.count() << "," << duration_compute.count() << "," << std::setprecision (16) << c.sum() << std::endl;
  return 0;
}
