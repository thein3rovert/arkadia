{
  pkgs,
  inputs,
}:
{
  # Test package to verify mkFlake works
  hello-test = pkgs.hello;

  # Custom pomodoro timer with rofi launcher
  pomodoro-timer = pkgs.callPackage ./pomodoro-timer { };
  kestractl = pkgs.callPackage ./kestractl { };

  # Add more modifications here as needed
  # example-package = prev.example-package.override { ... };
}
