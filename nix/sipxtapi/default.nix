{ stdenv, lib, autoreconfHook, makeWrapper, fetchFromGitHub, pkg-config, autoconf269, libtool, pcre, alsa-lib, spandsp3, yasm, gsm, openssl, speex, cppunit }:
stdenv.mkDerivation rec {
  pname = "sipxtapi";
  version = "commit-3d2c7f4";

  src = fetchFromGitHub {
    owner = "sipXtapi";
    repo = "sipXtapi";
    rev = "3d2c7f4";
    sha256 = "sha256-gfbbhpES9+80BocA0Nuthf4GnOTkmK3RkPZz+rYTvWo=";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config makeWrapper libtool autoconf269 ];
  buildInputs = [ pcre alsa-lib spandsp3 yasm gsm openssl speex cppunit ];

  patches = [
    ./utlregex.patch
    ./sipmessage.patch
  ];

  postPatch = ''
    sed -i '1i#include <stdlib.h>' sipXtackLib/src/resparse/res_free.c
    sed -i '1i#include <stdlib.h>' sipXtackLib/src/resparse/res_info.c
    sed -i '1i#include <stdlib.h>' sipXtackLib/src/resparse/res_parse.c
    # sed -i 's|/usr/local/sipx|$TMPDIR|g' `grep -rl '/usr/local/sipx' ./`
  '';

  autoreconfPhase = ''
    export ACLOCAL_PATH=${libtool}/share/aclocal:$ACLOCAL_PATH
  '';

  configurePhase = ''
    runHook preConfigure
    cd sipXportLib
    autoreconf -fi
    ./configure --prefix=$TMPDIR

    cd ../sipXsdpLib
    autoreconf -fi
    ./configure --prefix=$TMPDIR

    cd ../sipXmediaLib
    autoreconf -fi
    ./configure --prefix=$TMPDIR --enable-local-audio --disable-stream-player

    cd ../sipXmediaAdapterLib
    autoreconf -fi
    ./configure --prefix=$TMPDIR --enable-topology-graph --disable-stream-player
    cd ..
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    mkdir -p $TMPDIR/lib

    echo "Building sipXportLib first..."
    pushd sipXportLib
    make
    popd

    echo "Building sipXsdpLib first..."
    pushd sipXsdpLib
    make
    popd
    echo "Contents of $TMPDIR/lib:"
    ls $TMPDIR/lib

    echo "Building sipXmediaLib first..."
    pushd sipXmediaLib
    make
    popd
    echo "Contents of $TMPDIR/lib:"
    ls $TMPDIR/lib

    echo "Building sipXmediaAdapterLib first..."
    pushd sipXmediaAdapterLib
    make
    popd
    echo "Contents of $TMPDIR/lib:"
    ls $TMPDIR/lib

    runHook postBuild
  '';

  doCheck = false;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    mkdir -p $out/include
    mkdir $out/include/sipXport
    mkdir $out/include/sipXsdp
    mkdir $out/include/sipXtack
    mkdir $out/include/sipXmedia
    mkdir $out/include/sipXmediaAdapter
    mkdir $out/include/sipXcall

    mv $TMPDIR/* $out
    runHook postInstall
  '';

  meta = with lib; {
    description = "SipXtapi library"; # Provide a meaningful description
    homepage = "https://github.com/sipXtapi/sipXtapi"; # Adjust the homepage URL as necessary
    license = licenses.mit;
    maintainers = [ ];
  };
}
