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
      # in
      # { self, nixpkgs }:
      # let
      # WARNING: Might need to remove this as im importing
      # self and nixpkgs which might be needed by custom
      # imputs above

      # library = nixpkgs.lib;
      # packages = nixpkgs.legacyPackages.x86_64-linux;

      # Creating the llibrary, extending for now
      # nixpkgs library to make them available.
      # USAGE: mkLib {inherit inputs; src = ./.; ...}
      # RESULT: lib
      mkLib = import ./arkadia-lib {
        # lib = library;
        # pkgs = packages;
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
          # because we dont need them, we only need arkadia options
          # as flake options
          flake-options = builtins.removeAttrs flake-and-lib-options [
            "inputs"
            "src"
          ];
        in
        lib.mkFlake flake-options;
    in
    {
      inherit mkLib mkFlake;

      formatter = {
        x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.alejandra;
        aarch64-linux = inputs.nixpkgs.legacyPackages.aarch64-linux.alejandra;
        x86_64-darwin = inputs.nixpkgs.legacyPackages.x86_64-darwin.alejandra;
        aarch64-darwin = inputs.nixpkgs.legacyPackages.aarch64-darwin.alejandra;
      };
      /*
        `rec` means recursive attribute set

        It lets attributes reference each other inside the same set.
        Without rec, values can’t see siblings; with it, they can.
      */

      # TODO: Understand in plain english before
      # moving on

      arkadia = rec {
        # ? are we definfing an empty variable here with config
        # i thought that isnt possible
        /*
          The rec allow attributes inside the set to refer to
          other attribute in the same set, example: `raw-config=config`
          workks because `config` is later define in the set
        */
        raw-config = config;

        config = {
          root = "./.";
          src = "./.";

          namespace = "arkadia";
          lib-dir = "arkadia-lib";

          meta = {
            name = "arkadia-lib";
            title = "Arkadia Library";
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
      # packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
      #
      # packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    };
}
