{ stdenv, lib, fetchFromGitHub, patch, dos2unix }:

stdenv.mkDerivation rec {
  name = "cajun";
  version = "2.1.1";
  src = fetchFromGitHub {
    owner = "cajun-jsonapi";
    repo = "cajun-jsonapi";
    rev = "2.1.1";
    sha256 = "sha256-7z9L67kcoBNrTqsLV0HgTOmg6AFN2+siFWKrTcsq2BQ=";
  };

  patchFlags = [ "-p1" ];
  patches = [ ./reader.patch ./makefile.patch ./elements.patch ];
  nativeBuildInputs = [ patch dos2unix ];

  CXXFLAGS = "-std=c++11";

  buildPhase = ''
    make CXXFLAGS="$CXXFLAGS"
  '';

  prePatch = ''
    dos2unix Makefile
    dos2unix include/cajun/json/reader.inl
    dos2unix include/cajun/json/elements.inl
  '';

  installPhase = ''
    mkdir -p $out/include
    cp -r include/* $out/include/
  '';
}
