{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux =
      let
        # Helper function to get packages with specified stdenv
        getPkgs = stdenv: let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          cpppkgs = pkgs;  # You might want to customize this based on the stdenv
        in {
          inherit pkgs cpppkgs stdenv;
        };

        # Define package builders
        qpid-proton = { stdenv, pkgs, cpppkgs }: pkgs.callPackage ./nix/qpid-proton {
          inherit stdenv;
        };

        cajun = { stdenv, pkgs, cpppkgs }: pkgs.callPackage ./nix/cajun {
          inherit stdenv;
        };

        sipxtapi = { stdenv, pkgs, cpppkgs }: pkgs.callPackage ./nix/sipxtapi {
          inherit stdenv;
        };

        resiprocate = { stdenv, pkgs, cpppkgs }: pkgs.callPackage ./default.nix {
          inherit stdenv;
          inherit (pkgs.unixtools) xxd;
          sipxtapi = (sipxtapi { inherit stdenv pkgs cpppkgs; });
          qpid-proton = (qpid-proton { inherit stdenv pkgs cpppkgs; });
          cajun = (cajun { inherit stdenv pkgs cpppkgs; });
          libdb = cpppkgs.db62;
        };

        # Get package sets for different compilers
        gccPkgs = getPkgs nixpkgs.legacyPackages.x86_64-linux.gcc14Stdenv;
        clangPkgs = getPkgs nixpkgs.legacyPackages.x86_64-linux.llvmPackages_19.libcxxStdenv;

        # Build variants with different stdenvs
        mkVariant = pkgSet: {
          resiprocate = resiprocate {
            stdenv = pkgSet.stdenv;
            pkgs = pkgSet.pkgs;
            cpppkgs = pkgSet.cpppkgs;
          };
          qpid-proton = qpid-proton {
            stdenv = pkgSet.stdenv;
            pkgs = pkgSet.pkgs;
            cpppkgs = pkgSet.cpppkgs;
          };
          cajun = cajun {
            stdenv = pkgSet.stdenv;
            pkgs = pkgSet.pkgs;
            cpppkgs = pkgSet.cpppkgs;
          };
          sipxtapi = sipxtapi {
            stdenv = pkgSet.stdenv;
            pkgs = pkgSet.pkgs;
            cpppkgs = pkgSet.cpppkgs;
          };
        };

      in
      {
        default = (mkVariant gccPkgs).resiprocate;

        # GCC variants
        gccResiprocate = (mkVariant gccPkgs).resiprocate;
        # Clang variants
        clangResiprocate = (mkVariant clangPkgs).resiprocate;
      };
  };
}
