# Template file for 'libgccjit'
_majorver=9
_minorver=${_majorver}.3
_shlib_version=0.0.1
pkgname=libgccjit
version=${_minorver}.0
revision=9
short_desc="GNU Compiler Collection - JIT compiler library"
wrksrc="gcc-${version}"
maintainer="lane-brain <lane@mailbox.org>"
homepage="http://gcc.gnu.org"
license="GFDL-1.2-or-later, GPL-3.0-or-later, LGPL-2.1-or-later"
distfiles="${GNU_SITE}/gcc/gcc-${version}/gcc-${version}.tar.xz"
checksum="71e197867611f6054aa1119b13a0c0abac12834765fe2d81f35ac57f84f742d1"
depends="gcc>=${_minorver}"
makedepends="libssp-devel-${version}_${revision} gmp-devel mpfr-devel
  libmpc-devel zlib-devel"
depends="gcc"
hostmakedepends="tar texinfo perl flex"
checkdepends="dejagnu"
subpackages="libgccjit-devel"
#nostrip=yes

case "$XBPS_TARGET_MACHINE" in
	i686) _triplet="i686-pc-linux-gnu";;
	i686-musl) _triplet="i686-linux-musl";;
	x86_64) _triplet="x86_64-unknown-linux-gnu";;
	x86_64-musl) _triplet="x86_64-linux-musl";;
	armv5tel) _triplet="arm-linux-gnueabi";;
	armv5tel-musl) _triplet="arm-linux-musleabi";;
	armv6l) _triplet="arm-linux-gnueabihf";;
	armv7l) _triplet="armv7l-linux-gnueabihf";;
	armv6l-musl) _triplet="arm-linux-musleabihf";;
	armv7l-musl) _triplet="armv7l-linux-musleabihf";;
	aarch64) _triplet="aarch64-linux-gnu";;
	aarch64-musl) _triplet="aarch64-linux-musl";;
	ppc) _triplet="powerpc-linux-gnu";;
	ppc-musl) _triplet="powerpc-linux-musl";;
	ppcle) _triplet="powerpcle-linux-gnu";;
	ppcle-musl) _triplet="powerpcle-linux-musl";;
	ppc64le) _triplet="powerpc64le-linux-gnu";;
	ppc64le-musl) _triplet="powerpc64le-linux-musl";;
	ppc64) _triplet="powerpc64-linux-gnu";;
	ppc64-musl) _triplet="powerpc64-linux-musl";;
	mips-musl) _triplet="mips-linux-musl";;
	mipshf-musl) _triplet="mips-linux-muslhf";;
	mipsel-musl) _triplet="mipsel-linux-musl";;
	mipselhf-musl) _triplet="mipsel-linux-muslhf";;
esac


pre_configure() {
	# _FORTIFY_SOURCE needs an optimization level.
	sed -i "/ac_cpp=/s/\$CPPFLAGS/\$CPPFLAGS -O2/" {gcc,libiberty}/configure
	case "$XBPS_TARGET_MACHINE" in
		*-musl)
			patch -p0 -i ${FILESDIR}/libgnarl-musl.patch
			patch -p0 -i ${FILESDIR}/libssp-musl.patch
			patch -p0 -i ${FILESDIR}/gccgo-musl.patch
			;;
	esac
}

do_configure() {
	local _langs _args _hash

	_hash=gnu
	case "$XBPS_TARGET_MACHINE" in
		mipselhf-musl) _args+=" --with-arch=mips32r2 --with-float=hard"; _hash=sysv;;
		mipsel-musl) _args+=" --with-arch=mips32r2 --with-float=soft"; _hash=sysv;;
		mipshf-musl) _args+=" --with-arch=mips32r2 --with-float=hard";;
		mips-musl) _args+=" --with-arch=mips32r2 --with-float=soft";;
		armv5*) _args+=" --with-arch=armv5te --with-float=soft";;
		armv6l*) _args+=" --with-arch=armv6 --with-fpu=vfp --with-float=hard";;
		armv7l*) _args+=" --with-arch=armv7-a --with-fpu=vfpv3 --with-float=hard";;
		aarch64*) _args+=" --with-arch=armv8-a";;
		ppc64le*) _args+=" --with-abi=elfv2 --enable-secureplt --enable-targets=powerpcle-linux";;
		ppc64*) _args+=" --with-abi=elfv2 --enable-secureplt --enable-targets=powerpc-linux";;
		ppc*) _args+=" --enable-secureplt";;
	esac

	# on ppc64le-musl and all big endian ppc64
	case "$XBPS_TARGET_MACHINE" in
		ppc64le) ;;
		ppc64*) _args+=" --disable-libquadmath" ;;
	esac

	# fix: unknown long double size, cannot define BFP_FMT
	case "$XBPS_TARGET_MACHINE" in
		ppc*-musl) _args+=" --disable-decimal-float";;
	esac

    if [ -z "$CHROOT_READY" ]; then
		export LD_LIBRARY_PATH="${XBPS_MASTERDIR}/usr/lib${XBPS_TARGET_WORDSIZE}"
		_args+=" --build=${_triplet}"
	else
		_args+=" --build=${_triplet}"
	fi

	if [ "$XBPS_TARGET_LIBC" = "musl" ]; then
		_args+=" --disable-gnu-unique-object"
		_args+=" --disable-libsanitizer"
		_args+=" --disable-symvers"
		_args+=" libat_cv_have_ifunc=no"
	else
		_args+=" --enable-gnu-unique-object"
	fi

	case "$XBPS_TARGET_MACHINE" in
		ppc*) _args+=" --disable-vtable-verify";;
		*) _args+=" --enable-vtable-verify";;
	esac

	export CFLAGS="${CFLAGS/-D_FORTIFY_SOURCE=2/}"
	export CXXFLAGS="${CXXFLAGS/-D_FORTIFY_SOURCE=2/}"

	# Disable explicit -fno-PIE, gcc will figure this out itself.
	export CFLAGS="${CFLAGS//-fno-PIE/}"
	export CXXFLAGS="${CXXFLAGS//-fno-PIE/}"
	export LDFLAGS="${LDFLAGS//-no-pie/}"

	_args+=" --prefix=/usr"
	_args+=" --mandir=/usr/share/man"
	_args+=" --infodir=/usr/share/info"
	_args+=" --libexecdir=/usr/lib${XBPS_TARGET_WORDSIZE}"
	_args+=" --libdir=/usr/lib${XBPS_TARGET_WORDSIZE}"
    _args+=" --enable-threads=posix"
	_args+=" --enable-__cxa_atexit"
	_args+=" --with-system-zlib"
	_args+=" --enable-shared"
	# libgccjit requires host installation to be shared
    _args+=" --enable-host-shared" # listed on libgccjit
	_args+=" --disable-multilib" # listed on libgccjit
	_args+=" --enable-checking=release" # listed on libgccjit
    _args+=" --enable-lto" # listed on libjit
	_args+=" --enable-linker-build-id"
	_args+=" --disable-bootstrap"
    _args+=" --disable-werror"
	_args+=" --disable-nls"
	_args+=" --enable-default-pie"
    _args+=" --enable-default-ssp"
	_args+=" --disable-libstdcxx-pch"
	_args+=" --with-linker-hash-style=$_hash"
	_args+=" --disable-sjlj-exceptions"
	_args+=" --disable-target-libiberty"
    # We don't need g++ if we aren't running tests. 
    [ "$XBPS_CHECK_PKGS" ] && _args+=" --enable-languages=jit,c++" || _args+=" --enable-languages=jit"

    # Configure
    mkdir -p "${wrksrc}/build"
	cd "${wrksrc}/build"

    CONFIG_SHELL=/bin/bash \
		${wrksrc}/configure ${_args}
}

do_build() {
	if [ -z "$CHROOT_READY" ]; then
		export LD_LIBRARY_PATH="${XBPS_MASTERDIR}/usr/lib${XBPS_TARGET_WORDSIZE}"
	fi
    cd "${wrksrc}/build"
    make ${makejobs}
}

post_build() { 
    # Lets stage a folder to install into
    mkdir -p "${wrksrc}/install"
    cd "${wrksrc}/build"
    make DESTDIR="${wrksrc}/install" -C gcc install
}

do_install() {
    _includehostdir="usr/lib/gcc/${_triplet}/${_minorver}/include"
    
    # Lets get the shlibs over
    cd "${wrksrc}/install"
    vinstall usr/lib64/libgccjit.so.0.0.1 0755 "usr/lib/"
    vinstall usr/lib64/libgccjit.so.0 0755 "usr/lib/"
    vinstall usr/lib64/libgccjit.so 0755 "usr/lib/"
    
    # Get the header files in place
    vinstall usr/include/libgccjit.h 0644 "${_includehostdir}"
    vinstall usr/include/libgccjit++.h 0644 "${_includehostdir}"

    # The most important part, the info file
    vinstall usr/share/info/libgccjit.info 0755 "usr/share/info"
}

post_install() {
    vlicense ${wrksrc}/COPYING.RUNTIME RUNTIME.LIBRARY.EXCEPTION
}

libgccjit-devel_package() {
    depends="libgccjit>=${_minorver}"
	short_desc+=" - development files"
    pkg_install() {
        vmove usr/lib/libgccjit.so
        vmove usr/lib/gcc
        vmove usr/share/info/libgccjit.info
    }
}