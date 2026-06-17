# NixOS Modules
# Import this in your NixOS configuration with:
# imports = [ inputs.iv3-nixpkgs.nixosModules.default ];
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # This is the main entry point for all custom NixOS modules
  # Add your custom modules here as imports or inline definitions

  imports = [
    # Example: ./my-service.nix
    # Add more module files here as you create them
  ];

  # You can also define inline options here
  # options = {
  #   iv3 = {
  #     # Your custom options
  #   };
  # };

  # config = {
  #   # Your custom configuration
  # };
}
