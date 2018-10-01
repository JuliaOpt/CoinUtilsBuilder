# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CoinUtilsBuilder"
version = v"2.10.14"

# Collection of sources required to build CoinUtilsBuilder
sources = [
    "https://github.com/coin-or/CoinUtils/archive/releases/2.10.14.tar.gz" =>
    "929b6eae0aaf62cf4467e506f24dfab1df7ab8d2e5a1ea71e9bab5480e872d84",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd CoinUtils-releases-2.10.14/
update_configure_scripts
# temporary fix
for path in ${LD_LIBRARY_PATH//:/ }; do
    for file in $(ls $path/*.la); do
        echo "$file"
        baddir=$(sed -n "s|libdir=||p" $file)
        sed -i~ -e "s|$baddir|'$path'|g" $file
    done
done
mkdir build
cd build/
../configure --prefix=$prefix --with-pic --disable-pkg-config --with-blas="-L${prefix}/lib -lcoinblas" --host=${target} --enable-shared --disable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all --with-glpk-lib="-L${prefix}/lib -lcoinglpk" --with-glpk-incdir="$prefix/include/coin/ThirdParty" --with-lapack="-L${prefix}/lib -lcoinlapack" 
make -j${nproc} 
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
    Linux(:aarch64, :glibc),
    Linux(:armv7l, :glibc, :eabihf),
    Linux(:powerpc64le, :glibc),
    Linux(:i686, :musl),
    Linux(:x86_64, :musl),
    Linux(:aarch64, :musl),
    Linux(:armv7l, :musl, :eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_gcc_versions(platforms)

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libCoinUtils", :libCoinUtils)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/juan-pablo-vielma/COINGLPKBuilder/releases/download/v1.10.5-1/build_COINGLPKBuilder.v1.10.5.jl",
    "https://github.com/juan-pablo-vielma/COINLapackBuilder/releases/download/v1.5.6-1/build_COINLapackBuilder.v1.5.6.jl",
    "https://github.com/juan-pablo-vielma/COINBLASBuilder/releases/download/v1.4.6-1/build_COINBLASBuilder.v1.4.6.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

