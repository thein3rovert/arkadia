# Development shells for various programming environments
# Each shell can be accessed via: nix develop .#<shell-name>
# Or used in home-manager/system configs
{
  pkgs,
  inputs,
  agents ? null,
}:
{
  # Default shell for working on this repository
  default = pkgs.mkShell {
    name = "m3ta-nixpkgs-dev";

    buildInputs = with pkgs; [
      nil # Nix LSP
      alejandra # Nix formatter
      nix-tree # Explore dependency trees
      statix # Nix linter
      deadnix # Find dead Nix code
    ];

    shellHook = ''
      echo "🚀 m3ta-nixpkgs development environment"
      echo "Available commands:"
      echo "  nix flake check    - Check flake validity"
      echo "  nix flake show     - Show flake outputs"
      echo "  nix build .#<pkg>  - Build a package"
      echo "  nix fmt .           - Format Nix files"
      echo "  statix check .     - Lint Nix files"
      echo "  deadnix .          - Find dead code"
    '';
  };

  # Import all individual shell environments
  # python = import ./python.nix {inherit pkgs inputs;};
  # devops = import ./devops.nix {inherit pkgs inputs;};
  # coding = import ./coding.nix {inherit pkgs inputs agents;};
}
