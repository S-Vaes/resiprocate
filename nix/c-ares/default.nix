{ lib, stdenv, fetchFromGitHub, cmake, pkg-config }:

stdenv.mkDerivation rec {
  pname = "c-ares";
  version = "1_28_1";

  src = fetchFromGitHub {
    owner = "c-ares";
    repo = "c-ares";
    rev = "cares-${version}";
    sha256 = "sha256-vgUlq55zKhSYq45KM21PNn04Cb+uk9GlEm/W0A8YSJo=";
  };

  nativeBuildInputs = [ cmake pkg-config ];

  cmakeFlags = [
    "-DCARES_STATIC=ON"
    "-DCARES_SHARED=OFF"
    "-DCARES_STATIC_PIC=ON"
    "-DCARES_INSTALL=ON"
    "-DCARES_BUILD_TESTS=OFF"
    "-DCARES_BUILD_CONTAINER_TESTS=OFF"
    "-DCARES_THREADS=ON"
  ];

  meta = {
    homepage = "https://c-ares.org/";
    description = "A C library for asynchronous DNS requests";
    license = lib.licenses.mit; # Adjust the license as necessary
  };
}
