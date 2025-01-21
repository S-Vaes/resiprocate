{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ] (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      # Helper to create packages for a specific target platform's pkgs
      mkPkgsFor = targetPkgs: rec {
        qpid-proton = targetPkgs.callPackage ./nix/qpid-proton {};
        cajun = targetPkgs.callPackage ./nix/cajun {};
        sipxtapi = targetPkgs.callPackage ./nix/sipxtapi {};
        resiprocate = targetPkgs.callPackage ./default.nix {
          inherit (targetPkgs.unixtools) xxd;
          inherit sipxtapi qpid-proton cajun;
          libdb = targetPkgs.db62;
        };

        # GCC variants
        gccQpidProton = qpid-proton.override { stdenv = targetPkgs.gcc14Stdenv; };
        gccCajun = cajun.override { stdenv = targetPkgs.gcc14Stdenv; };
        gccSipxtapi = sipxtapi.override { stdenv = targetPkgs.gcc14Stdenv; };
        gccResiprocate = resiprocate.override { stdenv = targetPkgs.gcc14Stdenv; };

        # Clang variants
        clangQpidProton = qpid-proton.override { stdenv = targetPkgs.llvmPackages_19.libcxxStdenv; };
        clangCajun = cajun.override { stdenv = targetPkgs.llvmPackages_19.libcxxStdenv; };
        clangSipxtapi = sipxtapi.override { stdenv = targetPkgs.llvmPackages_19.libcxxStdenv; };
        clangResiprocate = resiprocate.override { stdenv = targetPkgs.llvmPackages_19.libcxxStdenv; };
      };
    in {
      packages = rec {
        # Native packages
        native = mkPkgsFor pkgs;
        default = native.resiprocate;

        # Cross-compiled packages for Darwin
        aarch64-darwin = mkPkgsFor crossPkgs.aarch64-darwin;
        x86_64-darwin = mkPkgsFor crossPkgs.x86_64-darwin;
      };

      overlays.default = final: prev: {
        inherit (self.packages.${system})
          qpid-proton
          cajun
          sipxtapi
          resiprocate;
      };
    });
}
