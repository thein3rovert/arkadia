# Overlays exported by arkadia
# These make custom packages available as pkgs.packageName
{
  # Default overlay: adds all custom packages to pkgs
  default = final: prev: {
    # Import all packages from packages/default.nix
    # Makes them available as pkgs.pomodoro-timer, pkgs.kestractl, etc.
  } // (import ../packages { pkgs = prev; inputs = { }; });
}
