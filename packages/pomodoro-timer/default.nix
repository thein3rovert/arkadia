{
  lib,
  stdenv,
  writeShellScriptBin,
  timer,
  kitty,
  rofi,
  libnotify,
  speechd,
}:
let
  launcher = writeShellScriptBin "launch-timer" ''
    #!/bin/bash

    validate_time() {
      local input=$1
      if [[ $input =~ ^[0-9]+[mhs]$ ]]; then
        return 0
      else
        return 1
      fi
    }

    notify_end() {
      local session_name=$1
      ${libnotify}/bin/notify-send "Pomodoro" "$session_name session ended!"
      ${speechd}/bin/spd-say "$session_name session ended"
    }

    start_timer() {
      local duration=$1
      local session_name=$2
      kitty \
        --class="floating-pomodoro" \
        --title="floating-pomodoro" \
        ${timer}/bin/timer $duration
      notify_end "$session_name"
    }

    # Show rofi menu with options
    selected=$(printf "work\nbreak\ncustom" | rofi -dmenu -p "Work Timer:" -l 3)

    # Exit if no selection was made
    [ -z "$selected" ] && exit

    case $selected in
      "work")
        start_timer "45m" "work"
        ;;
      "break")
        start_timer "10m" "break"
        ;;
      "custom")
        # Show input dialog for custom time
        custom_time=$(rofi -dmenu -p "Enter time (e.g., 25m, 1h, 30s):" -l 0)

        # Validate input and start timer
        if [ ! -z "$custom_time" ] && validate_time "$custom_time"; then
          start_timer "$custom_time" "custom"
        else
          ${libnotify}/bin/notify-send "Invalid time format" "Please use format: 30s, 25m, or 1h"
          exit 1
        fi
        ;;
    esac
  '';
in
stdenv.mkDerivation {
  pname = "work-timer";
  version = "0.1.0";

  dontUnpack = true;

  buildInputs = [
    timer
    kitty
    rofi
    libnotify
    speechd
  ];

  installPhase = ''
    mkdir -p $out/bin
    ln -s ${launcher}/bin/launch-timer $out/bin/launch-timer
  '';

  meta = {
    description = "A Work timer.";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "launch-timer";
  };
}
