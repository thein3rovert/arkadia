{
  pkgs,
  inputs,
}:
{
  # Test package to verify mkFlake works
  hello-test = pkgs.hello;

  # Add more modifications here as needed
  # example-package = prev.example-package.override { ... };
}
