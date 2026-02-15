# NOTE: The role of this file is to bootstrap the Arkadia library.
# It serves as the main entry point that combines core framework dependencies
# with user-provided configuration to produce a unified library (lib).
# Think of it as a factory that creates a customized library for each project.

# ============================================================================
# FUNCTION SIGNATURE
# ============================================================================
# This file is a function that takes TWO arguments:
# 1. core-inputs: Dependencies the framework itself needs (constant for all users)
# 2. user-options: Configuration specific to each project (varies per call)
#
# The syntax `arg1: arg2: let ... in` is Nix's way of defining a curried function
# that accepts arguments one at a time.

# core-inputs contains:
#   - nixpkgs: The nix package set
#   - src: Path to this framework's source code
#   - Any other framework dependencies

core-inputs: user-options:
let
  # ==========================================================================
  # CONFIGURATION EXTRACTION
  # ==========================================================================
  # Extract the user's config section, defaulting to empty set if not provided
  # The `or {}` syntax means: use this value, or an empty set if it's null/undefined
  raw-arkadia-config = user-options.arkadia or { };

  # Merge user config with defaults to create the final config
  # The `//` operator merges two attribute sets, with right side taking precedence
  arkadia-config = raw-arkadia-config // {
    # src: Where the user's project files are located
    src = user-options.src;

    # root: The project root (can be overridden, defaults to src)
    root = raw-arkadia-config.root or user-options.src;

    # namespace: Creates a scope for user's custom functions
    # e.g., if namespace = "myproject", user functions appear as lib.myproject.foo
    namespace = raw-arkadia-config.namespace or "internal";

    # meta: Metadata about the project (optional)
    meta = {
      name = raw-arkadia-config.meta.name or null;
      title = raw-arkadia-config.meta.title or null;
    };
  };

  # ==========================================================================
  # USER INPUTS PREPARATION
  # ==========================================================================
  # Combine the user's flake inputs with their src path
  # This makes src available to all loaded modules as inputs.src
  user-inputs = user-options.inputs // {
    src = user-options.src;
  };

  # ==========================================================================
  # IMPORT UTILITY FUNCTIONS FROM NIXPKGS
  # ==========================================================================
  # Pull specific functions from nixpkgs.lib that we need
  # This is like "importing" functions in other languages
  # Basically inputs.nixpkgs.lib
  inherit (core-inputs.nixpkgs.lib)
    assertMsg # For runtime assertions with error messages
    fix # For creating recursive attribute sets (enables self-reference)
    filterAttrs # Filter attributes based on a predicate
    mergeAttrs # Shallow merge of two attribute sets
    foldr # Right-fold for lists (like reduce)
    recursiveUpdate # Deep merge of attribute sets
    callPackageWith # Inject dependencies into functions
    isFunction # Check if value is a function
    ;

  # ==========================================================================
  # HELPER FUNCTIONS
  # ==========================================================================

  # Recursively merge a list of attribute sets (deep merge)
  # Type: [Attrs] -> Attrs
  # Example: merge-deep [ { a = { b = 1; }; } { a = { c = 2; }; } ]
  #   Result: { a = { b = 1; c = 2; }; }
  merge-deep = foldr recursiveUpdate { };

  # Merge attribute sets at the top level only (shallow merge)
  # Type: [Attrs] -> Attrs
  # Example: merge-shallow [ { a = 1; } { a = 2; b = 3; } ]
  #   Result: { a = 2; b = 3; }
  merge-shallow = foldr mergeAttrs { };

  # Extract 'lib' attribute from inputs that have it
  # This collects libraries from all flake inputs
  # Type: Attrs -> Attrs
  # Example: get-libs { nixpkgs = <nixpkgs>; foo = { lib = {...}; }; }
  #   Result: { nixpkgs = <nixpkgs.lib>; foo = {...}; }
  get-libs =
    attrs:
    let
      # First, filter to only inputs that have a 'lib' attribute
      attrs-with-libs = filterAttrs (name: value: builtins.isAttrs (value.lib or null)) attrs;
      # Then extract just the lib from each
      libs = builtins.mapAttrs (name: input: input.lib) attrs-with-libs;
    in
    libs;

  # Extract lib from inputs and remove the self from exracted lib
  # Remove the 'self' attribute from a set (self creates circular refs)
  # INFO: Since it getting from flake and flake has alot of "self.<>"
  without-self = attrs: builtins.removeAttrs attrs [ "self" ];

  # ==========================================================================
  # COLLECT LIBRARIES FROM INPUTS ( WITHOUT THE SELF ) since it's been removed
  # ==========================================================================
  # Get lib and remove self from core flake inputs (excluding self)
  core-inputs-libs = get-libs (without-self core-inputs);

  # Get lib  and remove self from user flake inputs (excluding self)
  user-inputs-libs = get-libs (without-self user-inputs);

  # ==========================================================================
  # LOAD ARKADIA FRAMEWORK LIBRARY MODULES
  # ==========================================================================
  # Define where the framework's built-in library modules live
  # This path is relative to the framework's source code
  arkadia-lib-root = "${core-inputs.src}/arkadia-lib"; # Main path to arkadia lib

  # Discover all subdirectories in the lib folder
  # Each directory should contain a default.nix that exports library functions
  /*
    Make sure that all dir in the arkadia-lib has a default.nix file
    and make sure that are all directories
  */
  arkadia-lib-dirs =
    let
      files = builtins.readDir arkadia-lib-root; # Read from the arkadia-dir root folder
      dirs = filterAttrs (name: kind: kind == "directory") files; # Make sure the file in the arkadia dir are actual directories
      names = builtins.attrNames dirs; # Get the names of the dirs
    in
    names;

  # Load all framework library modules using 'fix' for recursion
  # 'fix' allows modules to reference each other (e.g., fs can use attrs functions)
  arkadia-lib = fix (
    arkadia-lib:
    let
      # Attributes passed to each module
      attrs = {
        inherit
          arkadia-lib
          arkadia-config
          core-inputs
          user-inputs
          ;
      };
      # Import each directory and collect the results
      libs = builtins.map (dir: import "${arkadia-lib-root}/${dir}" attrs) arkadia-lib-dirs;
    in
    # Merge all module exports into one attribute set
    merge-deep libs
  );

  # Extract only non-attrset values for the top-level lib
  # This prevents nested attribute sets from cluttering the top level
  arkadia-top-level-lib = filterAttrs (name: value: !builtins.isAttrs value) arkadia-lib;

  # ==========================================================================
  # BUILD BASE LIBRARY
  # ==========================================================================
  # Combine all the base libraries into one foundation
  # Order matters: later sets override earlier ones on key collisions
  base-lib = merge-shallow [
    core-inputs.nixpkgs.lib # Standard nixpkgs library
    core-inputs-libs # Libs from framework dependencies
    user-inputs-libs # Libs from user dependencies
    arkadia-top-level-lib # Framework's own top-level functions
    { arkadia = arkadia-lib; } # Namespaced framework library
  ];

  # ==========================================================================
  # LOAD USER'S PROJECT-SPECIFIC LIBRARY
  # ==========================================================================
  # Define where user's custom library modules live
  # By convention, this is in a 'lib/' directory at project root
  user-lib-root = "${user-inputs.src}/lib";

  # Discover all default .nix files in user's lib directory recursively
  user-lib-modules = arkadia-lib.fs.get-default-nix-files-recursive user-lib-root;

  # Load user's library modules
  user-lib = fix (
    user-lib:
    let
      # Attributes available inside user modules
      attrs = {
        inherit (user-options) inputs; # User's flake inputs
        arkadia-inputs = core-inputs; # Framework inputs
        namespace = arkadia-config.namespace; # Configured namespace
        # Lib includes base + user's own functions under their namespace
        lib = merge-shallow [
          base-lib
          { ${arkadia-config.namespace} = user-lib; }
        ];
      };
      # Import each user module
      libs = builtins.map (
        path:
        let
          imported-module = import path;
        in
        # If the module is a function, call it with our attrs
        # Otherwise, use it as-is
        if isFunction imported-module then callPackageWith attrs path { } else imported-module
      ) user-lib-modules;
    in
    merge-deep libs
  );

  # ==========================================================================
  # FINAL LIBRARY ASSEMBLY
  # ==========================================================================
  # Merge base library with user's custom library
  lib = merge-deep [
    base-lib
    user-lib
  ];

  # ==========================================================================
  # VALIDATION
  # ==========================================================================
  # Check that required inputs are present
  user-inputs-has-self = builtins.elem "self" (builtins.attrNames user-inputs);
  user-inputs-has-src = builtins.elem "src" (builtins.attrNames user-inputs);

in
# Assertions ensure the library is properly configured before returning
assert (assertMsg user-inputs-has-self "Missing attribute `self` for mkLib.");
assert (assertMsg user-inputs-has-src "Missing attribute `src` for mkLib.");
# Return the fully assembled library
lib
