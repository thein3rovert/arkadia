{
  description = "Arkadia Lib";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    inputs:
    let
      # Create our own core inputs
      core-inputs = inputs // {
        src = ./.;
      };
    in
    { self, nixpkgs }:
    let
      # WARNING: Might need to remove this as im importing
      # self and nixpkgs which might be needed by custom
      # imputs above
      library = nixpkgs.lib;
      packages = nixpkgs.legacyPackages.x86_64-linux;

      # Creating the llibrary, extending for now
      # nixpkgs library to make them available.
      # USAGE: mkLib {inherit inputs; src = ./.; ...}
      # RESULT: lib
      mkLib = import ./lib {
        lib = library;
        pkgs = packages;
      };

      # Create flake option
      mkFlake =
        flake-and-lib-options@{
          # What does the @ sign means?
          inputs,
          src,
          arkadia ? { },
          ...
        }:
        let
          lib = mkLib {
            # Q: What input is mkflake inherting? is it
            # the custom or the main?
            inherit inputs src arkadia;
          };
          # We remove attr inputs and src from the flake-option
          # because we dont need them.
          flake-options = builtins/removeAttrs flake-and-lib-options [
            "inputs"
            "src"
          ];
        in
        lib.mkFlake flake-options;
    in
    {
      inherit mkLib mkFlake;

      packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

      packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    };
}
