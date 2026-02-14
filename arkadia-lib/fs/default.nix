{
  core-inputs,
  user-inputs,
  arkadia-lib,
  arkadia-config,
}:
let

  inherit (builtins) readDir pathExists;
  inherit (core-inputs) flake-utils-plus;
  inherit (core-inputs.nixpkgs.lib)
    assertMsg
    filterAttrs
    mapAttrsToList
    flatten
    ;

  file-name-regex = "(.*)\\.(.*)$";
in
{

  fs = rec {

    # Check/validate if file type in a directory
    ## Matchers for file kinds. These are often used with `readDir`.
    ## Example Usage:
    ## ```nix
    ## is-file-kind "directory"
    ## ```
    ## Result:
    ## ```nix
    ## false
    ## ```
    ## ```
    #@ String -> Bool
    is-file-type = type: type == "regular";
    is-symlink-type = type: type == "symlink";
    is-directory-type = type: type == "directory";
    is-unknown-tye = type: type == "unknown";

    ## Get a file path relative to the user's flake.
    ## Example Usage:
    ## ```nix
    ## get-file "systems"
    ## ```
    ## Result:
    ## ```nix
    ## "/user-source/systems"
    ## ```
    #@ String -> String
    # (./ )
    get-file = filePath: "${user-inputs.src}/${filePath}";

    ## Get a file path relative to the user's snowfall directory.
    ## Example Usage:
    ## ```nix
    ## get-snowfall-file "systems"
    ## ```
    ## Result:
    ## ```nix
    ## "/user-source/snowfall-dir/systems"
    ## ```
    #@ String -> String
    # (./arkadia-lib)
    get-arkadia-file = filePath: "${arkadia-config.root}/${filePath}";

  };
}
