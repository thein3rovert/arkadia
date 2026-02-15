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
            # Simply return the path - let the NixOS module system handle importing
            # This avoids circular references and is how flake-parts expects modules
            ${metadata.name} = metadata.path;
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
