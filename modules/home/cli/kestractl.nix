{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.kestractl;
in {
  options.programs.kestractl = {
    enable = mkEnableOption "Kestra workflow orchestration CLI";

    enableShellCompletion = mkOption {
      type = types.bool;
      default = true;
      description = "Enable shell completion for kestractl";
    };

    aliases = mkOption {
      type = types.attrsOf types.str;
      default = {
        kctl = "kestractl";
      };
      example = {
        kctl = "kestractl";
        kestra = "kestractl";
      };
      description = "Shell aliases for kestractl commands";
    };
  };

  config = mkIf cfg.enable {
    # Install the package (via overlay)
    home.packages = [ pkgs.kestractl ];

    # Add shell aliases
    home.shellAliases = cfg.aliases;

    # Add to PATH
    home.sessionPath = [ "${pkgs.kestractl}/bin" ];
  };

  meta.maintainers = with lib.maintainers; [ ];
}
