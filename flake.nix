{
  description = "A reproducible development environment";

  # Inputs define the dependencies this flake relies on
  inputs = {
    # Using the unstable branch of nixpkgs for the latest versions of uv and gh
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # A utility library to easily generate outputs for multiple CPU architectures
    utils.url = "github:numtide/flake-utils";
  };

  # Outputs define the environment and packages provided by this flake
  outputs = { self, nixpkgs, utils }:
    # Automatically loop through standard systems (e.g., x86_64-linux, aarch64-darwin for M1-M4 Macs)
    utils.lib.eachDefaultSystem (system:
      let
        # Import the nixpkgs library configured for the current system architecture
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # Define the default development shell activated via 'nix develop'
        devShells.default = pkgs.mkShell {
          # System packages that Nix will install and inject into the shell's PATH
          packages = [
            pkgs.coreutils # GNU core utilities (ls, cat, cp, mv, etc.)
            pkgs.findutils # GNU find and xargs
            pkgs.gnutar # GNU tar
            pkgs.gnused   # GNU version of 'sed'
            pkgs.gnugrep  # GNU version of 'grep'
            pkgs.rsync # Rsync
            pkgs.gzip # gzip
            pkgs.vim # vim
            pkgs.nano # nano
            pkgs.curl # curl
            pkgs.git # git
            pkgs.openssl # openssl
            pkgs.gnumake # make
          ];
        };
      });
}
