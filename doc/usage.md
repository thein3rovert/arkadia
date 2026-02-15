# Using Arkadia

Arkadia is a Nix library for auto-discovering and managing NixOS modules.

## Quick Start

### 1. Add Arkadia to your flake

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    arkadia = {
      url = "github:thein3rovert/arkadia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, arkadia, ... }@inputs:
    let
      # Initialize Arkadia
      arkadia-lib = arkadia.mkLib {
        inherit inputs;
        src = ./.;
        arkadia.namespace = "myproject";
      };

      # Auto-discover modules from ./modules/nixos/
      auto-modules = arkadia-lib.arkadia.module.create-modules {
        src = ./modules/nixos;
      };
    in {
      nixosModules = auto-modules;

      nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit arkadia-lib; };
        modules = [
          ./hosts/myhost
          self.nixosModules.tools  # Auto-discovered module
        ];
      };
    };
}
```

### 2. Create a module

```nix
# modules/nixos/tools/default.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    cowsay
    jq
  ];
}
```

### 3. Test it

```bash
nix eval .#nixosModules.tools   # Should show the module
nix build .#nixosConfigurations.myhost.config.system.build.toplevel
```

## Directory Structure

```
my-project/
├── flake.nix
├── modules/
│   └── nixos/           # Auto-discovered
│       ├── tools/
│       │   └── default.nix
│       └── networking/
│           └── default.nix
└── hosts/
    └── myhost/
        └── default.nix
```

Modules are named by their directory path:
- `modules/nixos/tools/default.nix` → `nixosModules.tools`
- `modules/nixos/os/services/nginx/default.nix` → `nixosModules."os/services/nginx"`

## Available Functions

### `arkadia.module.create-modules`

Auto-discovers modules from a directory.

```nix
arkadia-lib.arkadia.module.create-modules {
  src = ./modules/nixos;      # Directory to scan
  overrides = {};             # Manual overrides
  alias = { default = "tools"; };  # Aliases
}
```

### `arkadia.fs.*`

File system utilities:
- `get-files` - List files in directory
- `get-files-recursive` - List files recursively
- `get-default-nix-files-recursive` - Find all `default.nix` files

### `arkadia.attrs.*`

Attribute set utilities:
- `merge-deep` - Deep merge attribute sets
- `merge-shallow` - Shallow merge

### `arkadia.flake.*`

Flake utilities:
- `without-self` - Remove `self` from inputs
- `without-src` - Remove `src` from inputs

## With flake-parts

```nix
outputs = { self, nixpkgs, arkadia, flake-parts, ... }@inputs:
  let
    arkadia-lib = arkadia.mkLib {
      inherit inputs;
      src = ./.;
      arkadia.namespace = "myproject";
    };
  in
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];

    flake = {
      nixosModules =
        let
          all-modules = arkadia-lib.arkadia.module.create-modules {
            src = ./modules/nixos;
          };
        in
        { tools = all-modules.tools; }  # Pick specific modules
        // {
          manual-module = ./modules/other;  # Or add manual ones
        };
    };
  };
```
