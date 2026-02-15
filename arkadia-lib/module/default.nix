{
  core-inputs,
  user-inputs,
  arkadia-lib,
  arkadia-config,
}:
let
  inherit (builtins) baseNameOf;
  inherit (core-inputs.nixpkgs.lib)
    foldl
    mapAttrs
    hasPrefix
    hasSuffix
    isFunction
    splitString
    tail
    ;

  # Path to user's modules directory
  user-modules-root = arkadia-lib.fs.get-arkadia-file "modules";
in
{
  module = {
    ## Create flake output modules.
    ## Automatically discovers and wraps NixOS/Home-Manager modules.
    ##
    ## Example Usage:
    ## ```nix
    ## create-modules {
    ##   src = ./my-modules;
    ##   overrides = { inherit another-module; };
    ##   alias = { default = "another-module"; };
    ## }
    ## ```
    ## Result:
    ## ```nix
    ## { another-module = ...; my-module = ...; default = ...; }
    ## ```
    #@ Attrs -> Attrs
    create-modules =
      {
        src ? "${user-modules-root}/nixos",
        overrides ? { },
        alias ? { },
      }:
      let
        # Find all default.nix files in the modules directory
        user-modules = arkadia-lib.fs.get-default-nix-files-recursive src;

        # Extract module name from file path
        # Converts "/path/to/modules/nixos/networking/default.nix" -> "networking"
        create-module-metadata = module: {
          name =
            let
              # Remove the base path and "/default.nix" from the module path
              path-name = builtins.replaceStrings [ (builtins.toString src) "/default.nix" ] [ "" "" ] (
                builtins.unsafeDiscardStringContext module
              );
            in
            # Remove leading slash if present
            if hasPrefix "/" path-name then
              builtins.substring 1 ((builtins.stringLength path-name) - 1) path-name
            else
              path-name;
          path = module;
        };

        # Create metadata for all discovered modules
        modules-metadata = builtins.map create-module-metadata user-modules;

        # Merge a single module into the modules set
        merge-modules =
          modules: metadata:
          modules
          // {
            ${metadata.name} =
              args@{ pkgs, ... }:
              let
                # Extract system and target information
                # NOTE: home-manager *requires* modules to specify named arguments
                # or it will not pass values in. For this reason we must specify
                # things like `pkgs` as a named attribute.
                system = args.system or pkgs.stdenv.hostPlatform.system;
                target = args.target or system;

                # Determine the system format (linux, darwin, etc.)
                # For now, simplified version - just check if it's Darwin
                format = if builtins.match ".*-darwin" target != null then "darwin" else "linux";

                # Replicates the specialArgs pattern from Arkadia Lib's system builder
                modified-args = args // {
                  inherit
                    system
                    target
                    format
                    pkgs
                    ;

                  # Virtual system detection (placeholder for future)
                  # TODO: Create system detection modules next
                  virtual = args.virtual or false;
                  systems = args.systems or { };

                  # Pass the library but not the full arkadia-lib (which contains user-inputs)
                  # Only pass what the module actually needs
                  lib = args.lib or core-inputs.nixpkgs.lib;
                  arkadia-lib = arkadia-lib.arkadia; # Only pass the utility functions

                  # Filter out src and self from inputs to avoid circular references
                  inputs = arkadia-lib.flake.without-self (arkadia-lib.flake.without-src user-inputs);
                  namespace = arkadia-config.namespace;
                };

                # Import the user's module
                imported-user-module = import metadata.path;

                # Call it with args if it's a function, otherwise use as-is
                user-module =
                  if isFunction imported-user-module then
                    imported-user-module modified-args
                  else
                    imported-user-module;
              in
              user-module // { _file = metadata.path; };
          };

        # Build the modules attribute set
        modules-without-aliases = foldl merge-modules { } modules-metadata;

        # Create aliases (e.g., default = some-module)
        aliased-modules = mapAttrs (name: value: modules-without-aliases.${value}) alias;

        # Final modules: discovered + aliases + overrides
        modules = modules-without-aliases // aliased-modules // overrides;
      in
      modules;
  };
}
