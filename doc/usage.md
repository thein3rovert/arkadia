# Using Arkadia in Your Project

Yes! You can use Arkadia in other flake projects right now.

## Method 1: Basic Usage (Just the Library)

Add Arkadia to your flake:

```nix
# flake.nix
{
  description = "My Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    arkadia.url = "path:/path/to/arkadia";  # Or git URL
  };

  outputs = inputs:
    let
      # Create the library
      lib = inputs.arkadia.mkLib {
        inherit inputs;
        src = ./.;
        arkadia = {
          namespace = "myproject";
        };
      };
    in {
      # Now you can use lib.arkadia.* functions!
      
      # Example: Create modules automatically
      nixosModules = lib.arkadia.module.create-modules {
        src = ./modules/nixos;
      };
      
      # Example: Use file utilities
      # lib.arkadia.fs.get-files ./my-folder
    };
}
```

## Method 2: Full Flake Management

Let Arkadia manage your entire flake:

```nix
# flake.nix
{
  description = "My Full Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    arkadia.url = "path:/path/to/arkadia";
  };

  outputs = inputs: inputs.arkadia.mkFlake {
    inherit inputs;
    src = ./.;
    
    # Configure your project
    arkadia = {
      namespace = "myproject";
    };
    
    # Systems you support
    systems = [ "x86_64-linux" "aarch64-linux" ];
    
    # Modules will be auto-discovered from ./modules/nixos/
    # Packages from ./packages/
    # etc.
  };
}
```

## What You Get

After calling `mkLib`, your `lib` has:

```nix
lib = {
  # Standard nixpkgs functions
  map = ...;
  filter = ...;
  
  # Arkadia framework functions
  arkadia = {
    # File utilities
    fs.get-files = ...;
    fs.get-arkadia-file = ...;
    fs.get-default-nix-files-recursive = ...;
    
    # Attribute utilities  
    attrs.merge-deep = ...;
    attrs.merge-shallow = ...;
    attrs.map-concat-attrs-to-list = ...;
    
    # Module management
    module.create-modules = ...;
    
    # Flake utilities
    flake.without-self = ...;
    flake.without-src = ...;
    
    # Your custom functions
    myproject = { ... };  # From your lib/ directory
  };
};
```

## Directory Structure for Auto-Discovery

```
my-project/
├── flake.nix              # Imports arkadia
├── lib/                   # Your custom functions (optional)
│   ├── helpers.nix
│   └── utils.nix
└── modules/
    └── nixos/            # Auto-discovered modules
        ├── networking/
        │   └── default.nix
        └── users/
            └── default.nix
```

## Testing It Works

```bash
# In your project directory
nix eval .#nixosModules.networking  # Should show the module
```

## Real Example

Here's a complete example with a NixOS configuration:

```nix
# flake.nix
{
  description = "My Server Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    arkadia.url = "github:yourusername/arkadia";  # Or path
  };

  outputs = inputs:
    let
      lib = inputs.arkadia.mkLib {
        inherit inputs;
        src = ./.;
        arkadia.namespace = "myserver";
      };
      
      # Auto-discover all modules
      myModules = lib.arkadia.module.create-modules {
        src = ./modules/nixos;
        alias = { default = "desktop"; };
      };
    in {
      # Export modules for reuse
      nixosModules = myModules;
      
      # Use in a system
      nixosConfigurations.myhost = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          myModules.desktop
          ./hosts/myhost/configuration.nix
        ];
      };
    };
}
```

And a module:

```nix
# modules/nixos/desktop/default.nix
{ config, pkgs, lib, inputs, namespace, ... }:
{
  # You have access to:
  # - lib: Full library with arkadia functions
  # - inputs: Your flake inputs
  # - namespace: "myserver"
  
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
  # Can use arkadia functions
  environment.systemPackages = [
    (lib.arkadia.myserver.my-custom-package or pkgs.hello)
  ];
}
```

## Next Steps

1. **Publish your flake**: Push to GitHub so others can use it
2. **Create modules**: Add files to `modules/nixos/` to auto-discover
3. **Add custom functions**: Create `lib/` directory with your utilities
4. **Use in CI**: The library works great in GitHub Actions/GitLab CI

## Limitations (Current)

- No automatic system creation yet (coming in `mkFlake`)
- No package auto-discovery yet
- No home-manager integration yet

These are planned for future versions!
