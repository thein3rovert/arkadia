# Arkadia Lib

<p>
  <a href="https://nixos.wiki/wiki/Flakes" target="_blank"><img alt="Nix Flakes Ready" src="https://img.shields.io/static/v1?logo=nixos&logoColor=ebdbb2&label=Nix%20Flakes&labelColor=689d6a&message=Ready&color=ebdbb2&style=for-the-badge"></a>
  <a href="https://nixos.org" target="_blank"><img alt="Linux Ready" src="https://img.shields.io/static/v1?logo=linux&logoColor=ebdbb2&label=Linux&labelColor=689d6a&message=Ready&color=ebdbb2&style=for-the-badge"></a>
  <a href="https://github.com/lnl7/nix-darwin" target="_blank"><img alt="macOS Ready" src="https://img.shields.io/static/v1?logo=apple&logoColor=ebdbb2&label=macOS&labelColor=689d6a&message=Ready&color=ebdbb2&style=for-the-badge"></a>
  <a href="https://github.com/nix-community/nixos-generators" target="_blank"><img alt="Generators Ready" src="https://img.shields.io/static/v1?logo=linux-containers&logoColor=ebdbb2&label=Generators&labelColor=689d6a&message=Ready&color=ebdbb2&style=for-the-badge"></a>
</p>

A Nix library framework for managing NixOS configurations. Named after "Arkadia" from The 100 series (meaning "home").

> **Status**: Core features working - usable for module management!

## Quick Start

```nix
# flake.nix
{
  inputs.arkadia.url = "github:yourusername/arkadia";

  outputs = inputs:
    let
      lib = inputs.arkadia.mkLib {
        inherit inputs;
        src = ./.;
        arkadia.namespace = "myproject";
      };
    in {
      # Auto-discover modules
      nixosModules = lib.arkadia.module.create-modules {
        src = ./modules/nixos;
      };
    };
}
```

## What's Working

✅ **mkLib** - Creates library with:

- File utilities (`fs.get-files`, `fs.get-default-nix-files-recursive`)
- Attribute utilities (`attrs.merge-deep`, `attrs.map-concat-attrs-to-list`)
- Module auto-discovery
- Flake helpers (`without-self`, `without-src`)

✅ **Modules** - Auto-discover from `modules/nixos/` with injected args

## Project Structure

```
arkadia/
├── flake.nix              # Exports mkLib
├── arkadia-lib/
│   ├── default.nix        # Bootstrapper
│   ├── attrs/             # Attribute utilities
│   ├── fs/                # File utilities
│   ├── flake/             # Flake helpers
│   └── module/            # Module management
├── doc/                   # Documentation
└── modules/nixos/         # Your modules
```

## Documentation

- [flake.nix](doc/flake.md) - How the bootstrapper works
- [Modules](doc/module.md) - Auto-discover and wrap modules
- [Usage](doc/usage.md) - Using in other projects

## Testing

```bash
nix eval .#arkadia.internal-lib    # Test library
nix flake check                     # Check flake
```

## Coming Soon

🚧 mkFlake - Full flake management
🚧 Package auto-discovery
🚧 Home-manager integration

## Why Arkadia?

From The 100 series - it means "home". Built to learn Nix while managing homelab servers.
