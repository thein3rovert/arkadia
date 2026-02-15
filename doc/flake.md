# Understanding flake.nix

This file is the **entry point** for your framework. It tells Nix what your project provides.

## What It Does

```
flake.nix ──▶ exports mkLib ──▶ user calls mkLib ──▶ gets back lib
```

1. **Imports** dependencies (like nixpkgs)
2. **Creates** two functions: `mkLib` and `mkFlake`
3. **Exports** them so others can use your framework

## The Two Functions

### `mkLib` - Build Your Library

This function creates a complete `lib` with all your tools.

**How users call it:**
```nix
lib = inputs.arkadia.mkLib {
  inherit inputs;
  src = ./.;                    # Their project folder
  arkadia = {
    namespace = "myproject";    # Where their functions go
  };
};
```

**What they get back:**
- `lib.map`, `lib.filter` - Standard Nix functions
- `lib.arkadia.fs.*` - Your framework's file tools
- `lib.arkadia.attrs.*` - Your attribute set tools
- `lib.myproject.*` - Their custom functions

### `mkFlake` - Build a Complete Flake

This is for users who want your framework to manage their entire flake.

**How users call it:**
```nix
outputs = inputs: inputs.arkadia.mkFlake {
  inherit inputs;
  src = ./.;
  systems = ["x86_64-linux"];
  # ... more options
};
```

## The arkadia.internal-lib Output

This is for **testing** your framework. It creates a lib using the framework itself.

```bash
nix eval .#arkadia.internal-lib
```

This proves your `mkLib` function works correctly.

## How It All Connects

```
User's flake.nix                    Your flake.nix
──────────────────                  ──────────────
inputs.arkadia.url = "...";         mkLib = import ./arkadia-lib core-inputs;
                                    
lib = inputs.arkadia.mkLib {        core-inputs: user-options: let ... in lib
  inherit inputs;                          ▲
  src = ./.;                               │
};                                    User calls with their options
```

## Key Points

1. **mkLib is a function** - It doesn't run until someone calls it
2. **Lazy evaluation** - Code only runs when needed
3. **Self-testing** - `internal-lib` tests your code without needing a user
4. **Two use cases** - `mkLib` for library, `mkFlake` for full flake management

## Testing Your Changes

```bash
# Test that mkLib works
nix eval .#arkadia.internal-lib

# Check flake structure (doesn't run code)
nix flake check
```
