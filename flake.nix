{
  description = "Arkadia - Personal Nix framework and package repository";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    
    # Optional: Opencode agents configuration (if you use it)
    # agents = {
    #   url = "github:thein3rovert/agents";
    #   flake = false;
    # };
  };

  outputs =
    inputs:
    let
      # Create our own core inputs
      core-inputs = inputs // {
        src = ./.;
      };

      # Creating the library, extending nixpkgs library to make them available.
      # USAGE: mkLib {inherit inputs; src = ./.; ...}
      # RESULT: lib
      mkLib = import ./arkadia-lib core-inputs;

      # Create flake builder function
      # This wraps mkLib and passes the built lib to lib.mkFlake
      mkFlake =
        flake-and-lib-options@{
          inputs,
          src,
          arkadia ? { },
          ...
        }:
        let
          lib = mkLib {
            inherit inputs src arkadia;
          };
          # Only remove arkadia-specific options that mkFlake doesn't need
          flake-options = builtins.removeAttrs flake-and-lib-options [
            "arkadia"
          ];
        in
        lib.mkFlake flake-options;

      # Arkadia configuration for internal use
      arkadia-config = rec {
        raw-config = config;

        config = {
          root = "./.";
          src = "./.";
          namespace = "arkadia";
          lib-dir = "arkadia-lib";

          meta = {
            name = "arkadia";
            title = "Arkadia - Personal Nix Repository";
          };
        };

        internal-lib =
          let
            lib = mkLib {
              src = ./.;
              inputs = inputs // {
                self = { };
              };
            };
          in
          builtins.removeAttrs lib.arkadia [ "internal" ];
      };

      # Use mkFlake to generate our own flake outputs (dogfooding)
      personal-outputs = mkFlake {
        inherit inputs;
        src = ./.;
        arkadia = arkadia-config.config;
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];
      };
    in
    # Merge framework exports with personal flake outputs
    # personal-outputs includes: packages, devShells, checks, formatter, modules, lib
    personal-outputs
    // {
      # Export framework functions for other projects
      inherit mkLib mkFlake;

      # Export arkadia config for reference
      arkadia = arkadia-config;
    };
}
