# Arkadia Lib

This project is ongoing so it's not fully ready for use but you can reference it for anything.
The goal is to have a lib that can be used to easily spin up nixos server for a homelab.
My personal goal is to learn nix by building this library.

You might be wondering why i gave it the name `Arkadia`, it is from one of my favorite location in the series `The 100` and it basically means
`HOME`.

```
~/arkadia/
├── flake.nix
├── lib/
│   └── default.nix          # Your custom library
├── modules/
│   ├── common.nix            # Shared across all servers
│   ├── docker.nix            # Docker-specific config
│   └── monitoring.nix        # Monitoring setup
├── hosts/
│   ├── server1/
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   ├── server2/
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   └── server3/
│       ├── configuration.nix
│       └── hardware-configuration.nix
└── README.md
```
