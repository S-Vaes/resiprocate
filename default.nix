{ stdenv
, lib
, fetchFromGitHub
, cmake
, pkg-config
, git
, makeWrapper
, patch
, openssl
, pcre
, asio
, srtp
, sox
, xxd
, popt
, sipxtapi
, libdb
, qpid-proton
, cajun
, c-ares
, fmt
, buildRepro ? false
, buildReturn ? false
}:

stdenv.mkDerivation rec {
  pname = "resiprocate";
  version = "nix-test";

  src = ./.;


  # Keep your existing configuration
  nativeBuildInputs = [ cmake pkg-config git makeWrapper xxd patch ];
  buildInputs = [ pcre cajun asio srtp sox libdb qpid-proton cajun popt fmt ];
  propagatedBuildInputs = [ openssl c-ares ];

  doCheck = false;
  dontStrip = true;

  # Update the git ID to match your fork's commit
  NIX_CFLAGS_COMPILE = [
    "-DRESIPROCATE_GIT_ID=\"master\""
    "-DRESIPROCATE_BRANCH_NAME=\"master\""
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_SHARED_LIBS_DEFAULT=OFF"
    "-DBUILD_SHARED_LIBS=OFF"
    "-DWITH_C_ARES=ON"
    "-DWITH_SSL=ON"
    "-DUSE_POPT=ON"
    "-DUSE_SIGCOMP=OFF"
    "-DUSE_FMT=OFF"
    "-DVERSIONED_SONAME=OFF"
    "-DENABLE_ANDROID=OFF"
    "-DUSE_IPV6=ON"
    "-DUSE_DTLS=ON"
    "-DPEDANTIC_STACK=OFF"
    "-DUSE_MYSQL=OFF"
    "-DUSE_SOCI_POSTGRESQL=OFF"
    "-DUSE_SOCI_MYSQL=OFF"
    "-DUSE_POSTGRESQL=OFF"
    "-DUSE_MAXMIND_GEOIP=OFF"
    "-DRESIP_HAVE_RADCLI=OFF"
    "-DUSE_NETSNMP=OFF"
    "-DBUILD_DSO_PLUGINS=OFF"
    "-DBUILD_REND=OFF"
    "-DBUILD_TFM=FALSE"
    "-DBUILD_CLICKTOCALL=OFF"
    "-DBUILD_ICHAT_GW=OFF"
    "-DBUILD_TELEPATHY_CM=OFF"
    "-DBUILD_RECON=OFF"
    "-DUSE_SRTP1=OFF"
    "-DUSE_SIPXTAPI=OFF"
    "-DUSE_KURENTO=OFF"
    "-DUSE_GSTREAMER=OFF"
    "-DUSE_LIBWEBRTC=ON"
    "-DRECON_LOCAL_HW_TESTS=OFF"
    "-DBUILD_P2P=OFF"
    "-DBUILD_PYTHON=OFF"
    "-DBUILD_QPID_PROTON=ON"
    "-DRESIP_ASSERT_SYSLOG=OFF"
    "-DREGENERATE_MEDIA_SAMPLES=OFF"
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  ] ++ lib.optional (!buildRepro) "-DBUILD_REPRO=OFF"
    ++ lib.optional (!buildReturn) "-DBUILD_RETURN=OFF";

  postInstall = ''
    chmod +x $out/bin/* || true
    chmod +x $out/sbin/* || true

    mkdir -p $out/src
    cp -r $src/resip $out/src
    cp -r $src/rutil $out/src

    # Iterate over all the .so files in the lib directory
    for lib in $out/lib/*.so; do
      if [ -f "$lib" ]; then
        # Extract the library name without the path and extension
        libName=$(basename "$lib" .so)

        # Create GDB configuration file for the library
        gdbConfigFile=$out/lib/$libName.so.gdb
        echo "set substitute-path /build/source/resip $out/src/resip" > $gdbConfigFile
        echo "set substitute-path /build/source/rutil $out/src/rutil" >> $gdbConfigFile
        echo "directory $out/src" >> $gdbConfigFile

        # Create LLDB configuration file for the library
        lldbConfigFile=$out/lib/$libName.so.lldb
        echo "settings set target.source-map /build/source/resip $out/src/resip" > $lldbConfigFile
        echo "settings set target.source-map /build/source/rutil $out/src/rutil" >> $lldbConfigFile
        echo "settings append target.debug-file-search-paths $out/src" >> $lldbConfigFile

        # Embed the configuration files into the library
        chmod +w "$lib"
        objcopy --add-section .gdb_auto_load="$gdbConfigFile" "$lib"
        objcopy --add-section .lldb_auto_load="$lldbConfigFile" "$lib"
      fi
    done
  '';

  meta = with lib; {
    description = "reSIProcate";
    homepage = "https://github.com/resipcroate/resiprocate";
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
  };
}
