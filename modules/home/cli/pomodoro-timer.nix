{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.pomodoro-timer;
in {
  options.programs.pomodoro-timer = {
    enable = mkEnableOption "pomodoro timer with rofi launcher";

    workDuration = mkOption {
      type = types.str;
      default = "45m";
      example = "25m";
      description = ''
        Default work session duration.
        Format: number followed by s (seconds), m (minutes), or h (hours).
      '';
    };

    breakDuration = mkOption {
      type = types.str;
      default = "10m";
      example = "5m";
      description = ''
        Default break session duration.
        Format: number followed by s (seconds), m (minutes), or h (hours).
      '';
    };

    shellAlias = mkOption {
      type = types.str;
      default = "pomo";
      description = "Shell alias for launching the timer";
    };
  };

  config = mkIf cfg.enable {
    # Install the package (via overlay, so just use pkgs)
    home.packages = [ pkgs.pomodoro-timer ];

    # Add shell alias
    home.shellAliases = {
      ${cfg.shellAlias} = "launch-timer";
    };

    # Optional: Add the configuration as environment variables
    # (you'd need to modify the package to read these)
    home.sessionVariables = {
      POMODORO_WORK_DURATION = cfg.workDuration;
      POMODORO_BREAK_DURATION = cfg.breakDuration;
    };
  };

  meta.maintainers = with lib.maintainers; [ ];
}
