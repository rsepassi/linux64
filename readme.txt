Cross-compile a Linux kernel, Musl libc, and clang compiler-rt

Just enough to build statically-linked binaries for Linux.

https://www.kernel.org
https://musl.libc.org
https://llvm.org

---

Pre-built artifacts in Releases.
https://github.com/rsepassi/linux64/releases

minisign public key
RWTLX5ltJwfq/WzrDBvijdyGjNvjypEg0tn6H1u4Ebn4FWY8evI2bmEH

Verify with:

minisign -V \
  -P "RWTLX5ltJwfq/WzrDBvijdyGjNvjypEg0tn6H1u4Ebn4FWY8evI2bmEH" \
  -m linux64-arm64.tar.gz

---

KVERSION=6.6.67 \
CVERSION=1.2.5 \
LLVM_VERSION=19.1.6 \
ARCH=all \
./do_podman.sh

or

export KVERSION=6.6.67
export CVERSION=1.2.5
export LLVM_VERSION=19.1.6
ARCH=arm64  ./do_podman.sh
ARCH=risv64 ./do_podman.sh
ARCH=x86_64 ./do_podman.sh

---

Output

build/linux64/
    linux64-arm64.tar.gz
    linux64-riscv64.tar.gz
    linux64-x86_64.tar.gz
    arm64
        kernel
        kernel.config
        libc/
        linux-headers/
        rtlib/
    riscv64
        kernel
        kernel.config
        libc/
        linux-headers/
        rtlib/
    x86_64
        kernel
        kernel.config
        libc/
        linux-headers/
        rtlib/

---

do_podman.sh: call build.sh in the alpine:3.21 container
  build.sh
    build_libc.sh
    build_kernel.sh
    build_compilerrt.sh
    build_tarball.sh

---

Compiler: clang-19
Kernel source: https://cdn.kernel.org/pub/linux/kernel
Musl source: https://musl.libc.org/releases
LLVM source: https://github.com/llvm/llvm-project/releases
Kernel config: defconfig
GPG signatures verified
