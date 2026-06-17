{
  core-inputs,
  user-inputs,
  arkadia-lib,
  arkadia-config,
}:
let
  inherit (core-inputs.nixpkgs.lib)
    assertMsg
    foldl
    filterAttrs
    const
    ;
in
rec {
  flake = rec {
    ## Remove the `self` attribute from an attribute set.
    ## Example Usage:
    ## ```nix
    ## without-self { self = {}; x = true; }
    ## ```
    ## Result:
    ## ```nix
    ## { x = true; }
    ## ```
    #@ Attrs -> Attrs
    without-self = flake-inputs: builtins.removeAttrs flake-inputs [ "self" ];

    ## Remove the `src` attribute from an attribute set.
    ## Example Usage:
    ## ```nix
    ## without-src { src = ./.; x = true; }
    ## ```
    ## Result:
    ## ```nix
    ## { x = true; }
    ## ```
    #@ Attrs -> Attrs
    without-src = flake-inputs: builtins.removeAttrs flake-inputs [ "src" ];

    ## Remove the `src` and `self` attributes from an attribute set.
    ## Example Usage:
    ## ```nix
    ## without-arkadia-inputs { self = {}; src = ./.; x = true; }
    ## ```
    ## Result:
    ## ```nix
    ## { x = true; }
    ## ```
    #@ Attrs -> Attrs
    without-arkadia-inputs = arkadia-lib.fp.compose without-self without-src;

    ## Remove Arkadia-specific attributes so the rest can be safely passed to flake-utils-plus.
    ## Example Usage:
    ## ```nix
    ## without-arkadia-options { src = ./.; x = true; }
    ## ```
    ## Result:
    ## ```nix
    ## { x = true; }
    ## ```
    #@ Attrs -> Attrs
    without-arkadia-options =
      flake-options:
      builtins.removeAttrs flake-options [
        "systems"
        "modules"
        "overlays"
        "packages"
        "outputs-builder"
        "outputsBuilder"
        "packagesPrefix"
        "hosts"
        "homes"
        "channels-config"
        "templates"
        "checks"
        "alias"
        "arkadia"
      ];

    ## Transform an attribute set of inputs into an attribute set where the values are the inputs' `lib` attribute. Entries without a `lib` attribute are removed.
    ## Example Usage:
    ## ```nix
    ## get-lib { x = nixpkgs; y = {}; }
    ## ```
    ## Result:
    ## ```nix
    ## { x = nixpkgs.lib; }
    ## ```
    #@ Attrs -> Attrs
    get-libs =
      attrs:
      let
        # @PERF(jakehamilton): Replace filter+map with a fold.
        attrs-with-libs = filterAttrs (name: value: builtins.isAttrs (value.lib or null)) attrs;
        libs = builtins.mapAttrs (name: input: input.lib) attrs-with-libs;
      in
      libs;
  };

  ## Build a complete flake with auto-discovered packages, modules, overlays, and shells
  ## Example Usage:
  ## ```nix
  ## mkFlake {
  ##   inputs = inputs;
  ##   src = ./.;
  ##   systems = ["x86_64-linux" "aarch64-linux"];
  ## }
  ## ```
  #@ Attrs -> Attrs
  mkFlake =
    flake-options@{
      inputs,
      src ? ./.,
      systems ? [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ],
      ...
    }:
    let
      inherit (core-inputs.nixpkgs.lib)
        genAttrs
        optionalAttrs
        ;

      # Create lib for this flake
      lib = arkadia-lib;

      # Helper to create pkgs for a given system
      createPkgsFor =
        system:
        import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      # Helper function for all systems
      forAllSystems = genAttrs systems;

      # Auto-discover packages from packages/ directory
      packagesPath = "${src}/packages";
      hasPackages = builtins.pathExists packagesPath;

      # Auto-discover modules
      nixosModulesPath = "${src}/modules/nixos";
      homeModulesPath = "${src}/modules/home";
      darwinModulesPath = "${src}/modules/darwin";

      hasNixosModules = builtins.pathExists nixosModulesPath;
      hasHomeModules = builtins.pathExists homeModulesPath;
      hasDarwinModules = builtins.pathExists darwinModulesPath;

      # Auto-discover overlays
      overlaysPath = "${src}/overlays";
      hasOverlays = builtins.pathExists overlaysPath;

      # Auto-discover shells
      shellsPath = "${src}/shells";
      hasShells = builtins.pathExists shellsPath;

    in
    {
      # Export packages
      packages = forAllSystems (
        system:
        let
          pkgs = createPkgsFor system;
        in
        if hasPackages then import packagesPath { inherit pkgs inputs; } else { }
      );

      # Export NixOS modules
      nixosModules = optionalAttrs hasNixosModules {
        default = nixosModulesPath;
      };

      # Export Home Manager modules
      homeManagerModules = optionalAttrs hasHomeModules {
        default = import homeModulesPath;
      };

      # Export Darwin modules
      darwinModules = optionalAttrs hasDarwinModules {
        default = darwinModulesPath;
      };

      # Export overlays (only if default.nix exists)
      overlays = optionalAttrs (hasOverlays && builtins.pathExists "${overlaysPath}/default.nix") (
        import overlaysPath
      );

      # Export modifications overlay
      modifications =
        if hasOverlays then
          (final: prev: import "${overlaysPath}/mods" { inherit prev; })
        else
          (final: prev: { });

      # Export library
      lib = forAllSystems (system: lib);

      # Export dev shells (Reference from m3tm3re)
      devShells = forAllSystems (
        system:
        let
          pkgs = createPkgsFor system;
        in
        if hasShells then
          import shellsPath {
            inherit pkgs inputs;
            #INFO: Reference from https://code.m3ta.dev/m3tam3re/nixpkgs/src/branch/master/flake.nix
            agents = inputs.agents or null;
          }
        else
          { }
      );

      # Export checks
      checks = forAllSystems (
        system:
        let
          pkgs = createPkgsFor system;
          packages = if hasPackages then import packagesPath { inherit pkgs inputs; } else { };
        in
        builtins.mapAttrs (name: pkg: pkgs.lib.hydraJob pkg) packages
        // {
          # Add formatting check using treefmt
          formatting = pkgs.runCommand "check-formatting" { } ''
            ${pkgs.nixfmt-tree}/bin/treefmt --fail-on-change --no-cache -C ${src}
            touch $out
          '';
        }
      );

      # Formatter for 'nix fmt'
      formatter = forAllSystems (system: (createPkgsFor system).nixfmt);
    };
}
