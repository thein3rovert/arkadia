# Modern Python development environment with marimo and uv — Nushell version
# Usage: nix develop .#python   (drops into Nushell)
{
  pkgs,
  inputs ? null,
}:
let
  # Use the latest Python available in nixpkgs
  python = pkgs.python313;
in
pkgs.mkShell {
  name = "python-marimo-dev";

  buildInputs = with pkgs; [
    # Python interpreter
    python

    # Tooling
    black
    pyrefly

    # Modern package manager
    uv

    # Essential system dependencies for numpy and scientific packages
    stdenv.cc.cc.lib
    zlib
    gfortran
    openblas
    lapack

    # Nushell itself
    nushell
  ];

  # Environment variables for proper library linking
  LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
    pkgs.gfortran.cc.lib
  ]}";

  # Bash shellHook that sets up the environment and launches Nushell
  shellHook = ''
    echo "🐍 Python + Marimo Development Environment"
    echo ""
    echo "Python version: $(python --version)"
    echo "uv version: $(uv --version)"
    echo ""

    # Create venv if it doesn't exist
    if [ ! -d ".venv" ]; then
      echo "Creating virtual environment..."
      uv venv
    fi

    # Activate the virtual environment
    source .venv/bin/activate

    # Install marimo if not present
    if ! python -c "import marimo" 2>/dev/null; then
      echo "Installing marimo..."
      uv pip install marimo
    fi

    # Install numpy if not present
    if ! python -c "import numpy" 2>/dev/null; then
      echo "Installing numpy..."
      uv pip install numpy
    fi

    echo ""
    echo "✅ Environment ready!"
    echo ""
    echo "Quick start:"
    echo "  marimo edit               - Start marimo notebook"
    echo "  uv pip install <package>  - Install packages"
    echo "  python script.py          - Run Python scripts"
    echo ""
    echo "💡 Popular packages: uv pip install pandas matplotlib scipy scikit-learn"
    echo ""

    # Launch Nushell
    exec nu
  '';
}
