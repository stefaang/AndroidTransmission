#!/bin/sh

# directories
SOURCE="transmission-2.93"
CURL_SOURCE="curl-7.40.0"
LIBEVENT_SOURCE="libevent-2.0.21-stable"
OPENSSL_SOURCE="openssl-1.0.1l"

FAT="TS-Android"

SCRATCH="scratch"
# must be an absolute path
THIN="`pwd`/thin"

NDK="/data/data/android/sdk/ndk-bundle"

SYSROOT_PREFIX="$NDK/platforms/android-23/arch-"


CONFIGURE_FLAGS="--disable-mac --without-gtk --disable-nls --with-inotify --enable-daemon --enable-largefile --enable-utp --enable-lightweight --build=x86_64-unknown-linux-gnu"


ARCHS="arm"

COMPILE="y"
#LIPO="y"

CROSS="${NDK}/toolchains/${ACT_ARCH}-${PLATFROM}-4.9/prebuilt/linux-x86_64/bin/${ACT_ARCH}-${PLATFROM}"

DEPLOYMENT_TARGET="6.0"

build_openssl() {
    ARCH=$1
    PLATFROM=$2
    if [ $ARCH = "arm64" ]
    then
        ACT_ARCH="aarch64"
    else
        ACT_ARCH=$ARCH
    fi
    if [ -z $PLATFROM ]
    then
        PLATFROM=linux-androideabi
    fi
    SYSROOT=${SYSROOT_PREFIX}${ARCH}
    export CC="${CROSS}-gcc --sysroot=${SYSROOT}"
    CWD=`pwd`

    echo "building openssl for $ARCH..."
    #mkdir -p "$SCRATCH/$ARCH-ssl"
    #cd "$SCRATCH/$ARCH-ssl"
    # don't create a separate build dir, build from openssl source dir instead
    cd $CWD/$OPENSSL_SOURCE
    export CFLAGS="-I$SYSROOT/usr/include -I$CWD/$OPENSSL_SOURCE"
    export LDFLAGS="-L$SYSROOT/usr/lib"
    $CWD/$OPENSSL_SOURCE/Configure android \
        --prefix=$THIN/$ARCH --openssldir=$THIN/$ARCH
    #    --cross-compile-prefix=${ACT_ARCH}-${PLATFROM}
    make -j4
    make test 
    make install
    cd ..
}

#build_openssl "arm"
#exit 0

build_libevent() {
    ARCH="$1"
    PLATFROM="$2"

    if [ -z $PLATFROM ]
    then
        PLATFROM="linux-androideabi"
    fi

    if [ $ARCH = "arm64" ]
    then
        PLATFROM="linux-android"
        ACT_ARCH="aarch64"
    else
        ACT_ARCH=$ARCH
    fi

    SYSROOT=${SYSROOT_PREFIX}${ARCH}
    CC="$NDK/toolchains/${ACT_ARCH}-${PLATFROM}-4.9/prebuilt/linux-x86_64/bin/${ACT_ARCH}-${PLATFROM}-gcc --sysroot=${SYSROOT}"

    export CC="$CC"

    CWD=`pwd`

    echo "building libevent for $ARCH..."
    mkdir -p "$SCRATCH/$ARCH-libevent"
    cd "$SCRATCH/$ARCH-libevent"
    CFLAGS="-I${SYSROOT_PREFIX}${ARCH}/usr/include"
    export CFLAGS="$CFLAGS"
    $CWD/$LIBEVENT_SOURCE/configure --host=$ACT_ARCH-$PLATFROM \
        --prefix=$THIN/$ARCH
    make -j4 install
    cd ../..
}

#build_libevent "arm"
#exit 0

build_Curl() {
    ARCH="$1"
    PLATFROM="$2"

    if [ -z $PLATFROM ]
    then
        PLATFROM="linux-androideabi"
    fi

    if [ $ARCH = "arm64" ]
    then
        PLATFROM="linux-android"
        ACT_ARCH="aarch64"
    else
        ACT_ARCH=$ARCH
    fi

    SYSROOT=${SYSROOT_PREFIX}${ARCH}
    CC="$NDK/toolchains/${ACT_ARCH}-${PLATFROM}-4.9/prebuilt/linux-x86_64/bin/${ACT_ARCH}-${PLATFROM}-gcc --sysroot=${SYSROOT} -fpic -pie"

    export CC="$CC"

    CWD=`pwd`

    echo "building curl for $ARCH..."
    mkdir -p "$SCRATCH/$ARCH-curl"
    cd "$SCRATCH/$ARCH-curl"
    CFLAGS="-I${SYSROOT_PREFIX}${ARCH}/usr/include"
    export CFLAGS="$CFLAGS -Din_addr_t=uint32_t"
    $CWD/$CURL_SOURCE/configure --host=$ACT_ARCH-$PLATFROM \
        --with-ssl \
        --prefix=$THIN/$ARCH
    make -j4 install
    cd ../..
}

#build_Curl "arm"
#exit 0

NEED_RECONFIGURE=yes
if [ "$COMPILE" ]
then
	CWD=`pwd`
	for ARCH in $ARCHS
	do
		ACT_ARCH=$ARCH
		PLATFROM="linux-androideabi"
		if [ $ARCH = "arm64" ]; then
			ACT_ARCH="aarch64"
			PLATFROM="linux-android"
		fi

		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH-transmission"
		cd "$SCRATCH/$ARCH-transmission"

        CFLAGS="-I${SYSROOT_PREFIX}${ARCH}/usr/include -I${THIN}/$ARCH/include"

        export LIBCURL_CFLAGS="-I${THIN}/$ARCH/include"
        export LIBCURL_LIBS="-L${THIN}/$ARCH/lib"
        export LIBEVENT_CFLAGS="-I${THIN}/$ARCH/include"
        export LIBEVENT_LIBS="-L${THIN}/$ARCH/lib"
        export LIBS="-lcrypto -levent -lssl -lcurl"
        export PATH=$PATH:"$NDK/toolchains/${ACT_ARCH}-${PLATFROM}-4.9/prebuilt/linux-x86_64/bin/"

        SYSROOT=${SYSROOT_PREFIX}${ARCH}

		#CC="$NDK/toolchains/${ACT_ARCH}-${PLATFROM}-4.9/prebuilt/linux-x86_64/bin/${ACT_ARCH}-${PLATFROM}-gcc --sysroot=${SYSROOT}"
        CC="${CROSS}-gcc --sysroot=${SYSROOT}"
        export CC="${CC}"
		export CXX="$NDK/toolchains/${ACT_ARCH}-${PLATFROM}-4.9/prebuilt/linux-x86_64/bin/${ACT_ARCH}-${PLATFROM}-g++ --sysroot=${SYSROOT}"
        export AR="$NDK/toolchains/${ACT_ARCH}-${PLATFROM}-4.9/prebuilt/linux-x86_64/bin/${ACT_ARCH}-${PLATFROM}-ar "
        export RANLIB="$NDK/toolchains/${ACT_ARCH}-${PLATFROM}-4.9/prebuilt/linux-x86_64/bin/${ACT_ARCH}-${PLATFROM}-ranlib"        
        LDFLAGS="-L${SYSROOT_PREFIX}${ARCH}/usr/lib -L${THIN}/$ARCH/lib"
        export CFLAGS="$CFLAGS -Din_addr_t=uint32_t -D__android__ -Din_port_t=uint16_t -fpic -pie"
        export CXXFLAGS="$CFLAGS"
        export CPPFLAGS="-DTR_EMBEDDED"
        #export PKG_CONFIG="$NDK/toolchains/${ACT_ARCH}-${PLATFROM}-4.9/prebuilt/linux-x86_64/bin/${ACT_ARCH}-${PLATFROM}-pkg-config"
        export PKG_CONFIG_PATH="$THIN/$ARCH/lib/pkgconfig"

        export LDFLAGS="$LDFLAGS -pie"
        if [ $NEED_RECONFIGURE = "yes" ]
        then
		    $CWD/$SOURCE/autogen.sh \
                $CONFIGURE_FLAGS \
                --host=arm-linux-androideabi \
                --prefix=$THIN/$ARCH || exit 1;
        fi
        make clean;
        #make -s;
		make -j4; make install || exit 1
		cd $CWD
	done
fi

echo Done
