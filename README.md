# Arkadia Library Bootstrapper

A minimal library framework for Nix projects that auto-discovers and loads library modules.

## Overview

This framework provides a **unified library (`lib`)** that combines:

- Standard nixpkgs functions
- Framework-provided utilities
- Your project's custom functions

Think of it as a **plugin system** for Nix libraries.

## How It Works (The Big Picture)

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   flake.nix     │────▶│  default.nix     │────▶│   lib (output)  │
│   (calls the    │     │  (bootstrapper)  │     │  (usable        │
│   bootstrapper) │     │                  │     │   everywhere)   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                        │
         │                        │
         ▼                        ▼
  • framework inputs        • Loads framework modules
  • user project inputs     • Loads user modules
  • user configuration      • Merges everything
  • src path                • Returns unified lib
```

## Step-by-Step Flow

### 1. Your flake.nix Calls The Bootstrapper

```nix
# flake.nix
{
  outputs = inputs: let
    # Prepare framework's core inputs
    core-inputs = inputs // {
      src = ./.;  # Path to this framework's code
    };

    # Import the bootstrapper
    mkLib = import ./arkadia-lib {};

  in {
    # When someone uses your flake
    lib = mkLib {
      inherit inputs;      # User's flake inputs
      src = ./.;           # User's project root
      arkadia = {          # Optional configuration
        namespace = "myproject";
      };
    };
  };
}
```

### 2. The Bootstrapper Function Signature

```nix
# arkadia-lib/default.nix

# This is a CURRIED function - it takes arguments one at a time
core-inputs: user-options: let ... in lib

# Think of it like: bootstrapper(framework_deps)(user_config)
```

**`core-inputs`** (First Argument)

- What the framework needs to work
- Set in your flake.nix: `inputs // { src = ./.; }`
- Contains: `nixpkgs`, `src` (framework path), etc.
- **Constant**: Same for every user of your framework

**`user-options`** (Second Argument)

- What each project wants to configure
- Passed when calling `mkLib { ... }`
- Contains: their `inputs`, their `src`, their config
- **Variable**: Different for every project

### 3. Configuration Merging

```nix
# Extract user config section (or empty if not provided)
raw-arkadia-config = user-options.arkadia or {};

# Merge with defaults
arkadia-config = raw-arkadia-config // {
  src = user-options.src;                              # Their project path
  root = raw-arkadia-config.root or user-options.src;  # Project root
  namespace = raw-arkadia-config.namespace or "internal";  # Lib prefix
  meta = {                                             # Metadata
    name = raw-arkadia-config.meta.name or null;
    title = raw-arkadia-config.meta.title or null;
  };
};
```

**Why the `//` operator?**

```nix
{ a = 1; } // { a = 2; b = 3; }
# Result: { a = 2; b = 3; }
# Right side wins on conflicts!
```

### 4. Loading Framework Library Modules

```nix
# Where framework modules live
arkadia-lib-root = "${core-inputs.src}/arkadia-lib";

# Discover all subdirectories
arkadia-lib-dirs = ["attrs" "fs" "module" ...]  # Auto-detected!

# Load each one using 'fix' for recursion
arkadia-lib = fix (arkadia-lib:
  let
    attrs = {
      inherit arkadia-lib arkadia-config core-inputs user-inputs;
    };
    libs = map (dir: import "${arkadia-lib-root}/${dir}" attrs) arkadia-lib-dirs;
  in
    merge-deep libs
);
```

**What `fix` does:**

```nix
# Allows modules to reference each other!
# Example: fs/default.nix can call attrs functions
# Without fix: circular dependency error
# With fix: works seamlessly
```

### 5. Building the Base Library

```nix
base-lib = merge-shallow [
  core-inputs.nixpkgs.lib      # Standard nix functions
  core-inputs-libs             # Libs from framework deps
  user-inputs-libs             # Libs from user deps
  arkadia-top-level-lib        # Framework functions
  {arkadia = arkadia-lib;}     # Namespaced framework lib
];
```

**Result:** A `lib` that has:

- All nixpkgs functions: `lib.map`, `lib.filter`, etc.
- All framework functions: `lib.myFunction`
- All framework modules: `lib.arkadia.attrs.*`, `lib.arkadia.fs.*`

### 6. Loading User's Custom Library

```nix
# Where user's modules live (by convention)
user-lib-root = "${user-inputs.src}/lib";

# Auto-discover all .nix files
user-lib-modules = ["lib/helper.nix" "lib/utils.nix" ...];

# Load with access to base-lib
user-lib = fix (user-lib:
  let
    attrs = {
      inherit inputs;
      arkadia-inputs = core-inputs;
      namespace = arkadia-config.namespace;
      lib = merge-shallow [base-lib {${arkadia-config.namespace} = user-lib;}];
    };
  in
    merge-deep (map (path: import-and-call path attrs) user-lib-modules)
);
```

**Key Point:** User modules can access:

- `lib.*` - All base functions
- `lib.${namespace}.*` - Their own functions
- `inputs.*` - Their flake inputs
- `arkadia-inputs.*` - Framework inputs

### 7. Final Assembly and Validation

```nix
# Merge everything together
lib = merge-deep [
  base-lib
  user-lib
];

# Ensure required inputs exist
assert (assertMsg user-inputs-has-self "Missing attribute `self` for mkLib.");
assert (assertMsg user-inputs-has-src "Missing attribute `src` for mkLib.");

# Return the finished library
lib
```

## Directory Structure

```
.
├── flake.nix              # Defines framework, exports mkLib
├── arkadia-lib/
│   └── default.nix        # Bootstrapper (this file!)
│   └── lib/               # Framework modules (optional)
│       ├── attrs/
│       │   └── default.nix
│       ├── fs/
│       │   └── default.nix
│       └── module/
│           └── default.nix
└── lib/                   # User's custom modules (optional)
    ├── helper.nix
    └── utils.nix
```

## Usage Example

### 1. Framework Side (You)

```nix
# flake.nix
{
  description = "My Nix Framework";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = inputs: let
    core-inputs = inputs // { src = ./.; };
    mkLib = import ./arkadia-lib {};
  in {
    inherit mkLib;

    # Example internal usage
    lib = mkLib {
      src = ./.;
      inputs = inputs // { self = {}; };
    };
  };
}
```

### 2. User Side (Someone Using Your Framework)

```nix
# flake.nix
{
  description = "My Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    arkadia.url = "path:/path/to/arkadia";
  };

  outputs = inputs: let
    lib = inputs.arkadia.mkLib {
      inherit (inputs) self;
      inherit inputs;
      src = ./.;
      arkadia = {
        namespace = "myproject";
        meta = {
          name = "myproject";
          title = "My Cool Project";
        };
      };
    };
  in {
    # Now use lib everywhere!
    nixosConfigurations.myhost = lib.nixosSystem {
      modules = [ ./configuration.nix ];
    };
  };
}
```

### 3. User's Custom Module

```nix
# lib/helper.nix
{ inputs, lib, namespace, ... }:
{
  # Available: lib (base), inputs (flake inputs), namespace ("myproject")

  myHelper = arg:
    let
      # Can use nixpkgs functions
      cleaned = lib.filterAttrs (n: v: v != null) arg;
      # Can use other user functions
      formatted = lib.${namespace}.format cleaned;
    in
      formatted;

  format = attrs:
    lib.mapAttrs (name: value: "${name}=${toString value}") attrs;
}
```

## Key Concepts

### Curried Functions

```nix
# Instead of: f(a, b)
# Nix uses:   f(a)(b)

add = a: b: a + b;
add 5 3  # Returns 8

# This allows partial application!
add5 = add 5;  # Returns a function
add5 3         # Returns 8
```

### The `fix` Function

```nix
# Creates self-referencing attribute sets
# Essential for modules that need to call each other

attrs = fix (self: {
  a = 1;
  b = self.a + 1;  # Can reference 'a'!
  c = self.b + 1;  # Can reference 'b'!
});
# Result: { a = 1; b = 2; c = 3; }
```

### Attribute Set Operations

```nix
# Merge shallow (top level only)
{ a = 1; } // { a = 2; }        # { a = 2; }
{ x = { a = 1; }; } // { x = { b = 2; }; }  # { x = { b = 2; }; }  # 'a' is lost!

# Merge deep (recursive)
recursiveUpdate
  { x = { a = 1; }; }
  { x = { b = 2; }; }           # { x = { a = 1; b = 2; }; }  # Both kept!

# Filter attributes
filterAttrs (n: v: v != null) { a = 1; b = null; c = 2; }
# Result: { a = 1; c = 2; }

# Remove specific keys
removeAttrs { a = 1; b = 2; c = 3; } ["b"]
# Result: { a = 1; c = 3; }
```

### The `or` Operator

```nix
# Provides default values
value = config.name or "default";     # If config.name is null/undefined, use "default"
attrs = config.meta or {};             # If config.meta is null/undefined, use {}
```

## Benefits

1. **Modularity**: Organize functions in separate files/directories
2. **Auto-discovery**: No manual registration needed
3. **Composability**: Merge multiple libraries together
4. **Recursion**: Modules can reference each other
5. **Flexibility**: Users can extend with custom functions
6. **Validation**: Assertions catch configuration errors early

## Common Patterns

### Pattern 1: Namespace Isolation

```nix
# User functions don't pollute top-level lib
lib.myproject.myFunction  # User's function
lib.arkadia.fs.readFile   # Framework's function
lib.map                   # nixpkgs function
```

### Pattern 2: Progressive Enhancement

```nix
# Start with base
base-lib = nixpkgs.lib

# Add framework
base-lib = base-lib // { arkadia = ...; }

# Add user customizations
lib = base-lib // user-lib

# Each layer builds on the previous
```

### Pattern 3: Dependency Injection

```nix
# Modules receive their dependencies as arguments
{ inputs, lib, namespace, ... }:  # Auto-injected!
{
  myFn = x: lib.map ...;  # Can use injected lib
}
```

## Troubleshooting

### "Missing attribute `self` for mkLib"

**Solution:** Pass `self` in inputs:

```nix
lib = mkLib {
  inputs = inputs // { inherit (inputs) self; };
  # ...
};
```

### "Missing attribute `src` for mkLib"

**Solution:** Always provide src:

```nix
lib = mkLib {
  src = ./.;  # Required!
  # ...
};
```

### Functions Not Available

**Check:** Did you create the `lib/` directory in your project?
**Check:** Are your files named with `.nix` extension?
**Check:** Do they export an attribute set?

## Next Steps

1. Create your first framework module in `arkadia-lib/lib/`
2. Create a test project that uses `mkLib`
3. Add custom functions in the test project's `lib/` directory
4. See them appear in the final `lib` output!
