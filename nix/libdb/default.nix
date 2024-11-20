# { lib, stdenv, fetchurl, autoreconfHook, ... } @ args:

# import ./generic.nix (args // {
#   version = "6.2.32";
#   sha256 = "1yx8wzhch5wwh016nh0kfxvknjkafv6ybkqh6nh7lxx50jqf5id9";
#   license = lib.licenses.agpl3;
#   extraPatches = [
#     ./clang-6.0.patch
#     ./CVE-2017-10140-cwd-db_config.patch
#     ./darwin-mutexes.patch
#   ];
# })

{ lib, stdenv, fetchurl, autoreconfHook }:

stdenv.mkDerivation rec {
  pname = "db";
  version = "6.2.32";

  src = fetchurl {
    url = "https://download.oracle.com/berkeley-db/${pname}-${version}.tar.gz";
    sha256 = "1yx8wzhch5wwh016nh0kfxvknjkafv6ybkqh6nh7lxx50jqf5id9";
  };

  extraPatches = [
    ./clang-6.0.patch
    # ./CVE-2017-10140-cwd-db_config.patch
  ];

  # The provided configure script features `main` returning implicit `int`, which causes
  # configure checks to work incorrectly with clang 16.
  nativeBuildInputs = [ autoreconfHook ];

  outputs = [ "bin" "out" "dev" ];

  # Required when regenerated the configure script to make sure the vendored macros are found.
  autoreconfFlags = [ "-fi" "-Iaclocal" "-Iaclocal_java" ];

  preAutoreconf = ''
    pushd dist
    # Upstream's `dist/s_config` cats everything into `aclocal.m4`, but that doesn't work with
    # autoreconfHook, so cat `config.m4` to another file. Otherwise, it won't be found by `aclocal`.
    cat aclocal/config.m4 >> aclocal/options.m4
  '';

  # This isnt pretty. The version information is kept separate from the configure script.
  # After the configure script is regenerated, the version information has to be replaced with the
  # contents of `dist/RELEASE`.
  postAutoreconf = ''
    (
      declare -a vars=(
        "DB_VERSION_FAMILY"
        "DB_VERSION_RELEASE"
        "DB_VERSION_MAJOR"
        "DB_VERSION_MINOR"
        "DB_VERSION_PATCH"
        "DB_VERSION_STRING"
        "DB_VERSION_FULL_STRING"
        "DB_VERSION_UNIQUE_NAME"
        "DB_VERSION"
      )
      source RELEASE
      for var in "''${vars[@]}"; do
        sed -e "s/__EDIT_''${var}__/''${!var}/g" -i configure
      done
    )
    popd
  '';

  CXXFLAGS = lib.concatStringsSep " " [
    "-std=c++98"
    "-Wno-error"
    # Add other flags as necessary
  ];
  CFLAGS = lib.concatStringsSep " " [
    "-std=c99"
    "-Wno-error"
    # Add other flags as necessary
  ];

  configureFlags = [
    "--enable-compat185"
    "--enable-dbm"
    "--enable-cxx"
    "--enable-static"
  ];

  preConfigure = ''
    cd build_unix
    configureScript=../dist/configure
  '';
  postPatch = ''
    find . -type f -exec sed -i 's/\bstore\b/db_store/g' {} \;
    find . -type f -exec sed -i 's/atomic_init(/db_atomic_init(/g' {} \;
  '';

  # installPhase = ''
  #   find ../ -maxdepth 1 -type d
  #   mkdir -p $bin/bin
  #   mv .bin/* $bin/bin
  #   mkdir -p $out/lib
  #   mv .lib/* $out/lib
  #   mv .libs/libdb_cxx-6.2.so $out/lib/libdb-6.2.so
  #   ln -s $out/lib/libdb-6.2.so $out/lib/libdb-6.so
  #   ln -s $out/lib/libdb-6.2.so $out/lib/libdb.so
  #   mv .libs/libdb_cxx-6.2.a $out/lib/libdb-6.2.a
  #   ln -s $out/lib/libdb-6.2.a $out/lib/libdb.a
  #   mkdir -p $dev/include
  # '';
  postInstall = ''
    rm -rf $out/docs
  '';
  # postInstall = ''
  #   # Example of moving C++ headers to the out output
  #   moveToOutput "include" "$out/include"
  #   moveToOutput "lib/libdb_cxx*" "$out/lib"
  #   rm -rf $out/docs
  # '';

  enableParallelBuilding = true;

  doCheck = false;

  meta = with lib; {
    homepage = "https://www.oracle.com/database/technologies/related/berkeleydb.html";
    description = "Berkeley DB";
    platforms = platforms.unix;
  };
}
