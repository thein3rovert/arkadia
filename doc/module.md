# Understanding module/default.nix

This module helps you **auto-discover and manage NixOS/Home-Manager modules**.

## What It Does

Instead of manually listing modules, it:

1. **Finds** all `default.nix` files in your modules directory
2. **Names** them based on their folder path
3. **Wraps** them with useful arguments (inputs, lib, namespace)
4. **Returns** a ready-to-use modules set

## The Main Function

### `create-modules` - Auto-Discover Modules

```nix
modules = lib.arkadia.module.create-modules {
  src = ./modules/nixos;      # Where to look
  overrides = { };             # Replace specific modules
  alias = { default = "main"; };  # Create shortcuts
};
```

**What you get back:**
```nix
{
  networking = <wrapped-module>;   # From modules/nixos/networking/default.nix
  users = <wrapped-module>;        # From modules/nixos/users/default.nix
  default = <wrapped-module>;      # Alias pointing to "main"
}
```

## How Modules Get Wrapped

Each discovered module receives these arguments automatically:

```nix
{ pkgs, lib, inputs, system, namespace, ... }:
{
  # Your module code here
  # Can use lib.arkadia.* functions
  # Can access inputs.self, inputs.nixpkgs, etc.
}
```

## Directory Structure

```
modules/
└── nixos/
    ├── networking/
    │   └── default.nix     # Becomes "networking" module
    ├── users/
    │   └── default.nix     # Becomes "users" module
    └── desktop/
        └── default.nix     # Becomes "desktop" module
```

## Usage Example

```nix
# In your flake.nix
outputs = inputs: 
  let
    lib = inputs.arkadia.mkLib {
      inherit inputs;
      src = ./.;
    };
    
    # Auto-discover all modules
    myModules = lib.arkadia.module.create-modules {
      src = ./modules/nixos;
      alias = {
        default = "desktop";  # nixosModules.default works
      };
    };
  in {
    # Export discovered modules
    nixosModules = myModules;
    
    # Use in a system
    nixosConfigurations.myhost = lib.nixosSystem {
      modules = [ myModules.desktop ];
    };
  };
```

## Key Features

- **Auto-discovery**: Finds all `default.nix` files recursively
- **Smart naming**: Uses folder path as module name
- **Dependency injection**: Injects `lib`, `inputs`, `system` automatically
- **Aliases**: Create shortcuts like `default = "main"`
- **Overrides**: Replace auto-discovered modules with custom ones

## Why Use This?

Without it:
```nix
# Manual, tedious
modules = {
  networking = import ./modules/nixos/networking/default.nix;
  users = import ./modules/nixos/users/default.nix;
  desktop = import ./modules/nixos/desktop/default.nix;
  # ... more imports for every new module
};
```

With it:
```nix
# Automatic, maintainable
modules = lib.arkadia.module.create-modules {
  src = ./modules/nixos;
};
# Automatically includes new modules as you add them!
```
