{
  description = "Arkadia Lib";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    inputs:
    let
      # Create our own core inputs
      core-inputs = inputs // {
        src = ./.;
      };
    in
    { self, nixpkgs }:
    let
      library = nixpkgs.lib;
      packages = nixpkgs.legacyPackages.x86_64-linux;

      mkLib = import ./lib {
        lib = library;
        pkgs = packages;
      };

    in
    {
      packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

      packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    };
}
