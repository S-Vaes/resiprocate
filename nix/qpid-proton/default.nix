{ stdenv, cmake, pkg-config, fetchFromGitHub, openssl, python311 }:
stdenv.mkDerivation {
  name = "qpid-proton";
  version = "0.39.0";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "qpid-proton";
    rev = "0.39.0";
    sha256 = "sha256-PpoIWQPCss0nDNVqApyubNLxNTKjNKMxjvUguTUa8jo=";
  };

  nativeBuildInputs = [ cmake pkg-config python311 ];
  buildInputs = [ openssl ];
  cmakeFlags = [
    "-DBUILD_CPP=ON"
  ];

  # Make sure pkg-config can find the .pc files
  postInstall = ''
    moveToOutput "lib/pkgconfig" "$dev"
  '';
}
