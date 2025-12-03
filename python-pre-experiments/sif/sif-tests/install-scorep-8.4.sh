# install scoreP with python bindings enabled. The default on Vega has none:
    # module load Score-P/8.4-gompi-2024a
    # ls $(dirname $(dirname $(which scorep)))/lib | grep python

module purge
module load gompi/2024a

# Remove BLAS/LAPACK wrappers injected by gompi
unset LD_PRELOAD
unset LIBRARY_PATH
unset LDFLAGS
unset CPPFLAGS
unset CFLAGS
unset CXXFLAGS
export BLAS_LIBS=""
export LAPACK_LIBS=""

# enforce mpi compilers
export CC=mpicc
export CXX=mpicxx
export FC=mpif90

export PREFIX=/ceph/hpc/data/d2025d03-111-users/scorep-8.4

# 1. Create folders
rm -p $PREFIX
mkdir -p $PREFIX
mkdir -p /tmp/build-scorep
cd /tmp/build-scorep

# 2. Download Score-P source
wget https://perftools.pages.jsc.fz-juelich.de/cicd/scorep/tags/scorep-8.4/scorep-8.4.tar.gz -O scorep-8.4.tar.gz
tar xf scorep-8.4.tar.gz
cd scorep-8.4

# 3. Configure, build, install
./configure \
    --prefix=$PREFIX \
    --enable-python \
    --disable-shmem \
    --without-cuda \
    --without-rocm \
    --without-opencl \
    --with-libgotcha=builtin

make -j"$(nproc)"
make install

# 4. Cleanup
cd /
rm -rf /tmp/build-scorep

# 5. Verify installation
echo "MPI libraries used by Score-P:"
ldd $PREFIX/lib/libscorep_adapter_mpi_event.so | grep mpi
echo "Python instrumentation library present?"
ls $PREFIX/lib | grep python


