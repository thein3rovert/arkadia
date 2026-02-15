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

    ## Get a file path relative to the this flake.
    ## Example Usage:
    ## ```nix
    ## get-file "systems"
    ## ```
    ## Result:
    ## ```nix
    ## "/user-source/systems"
    ## ```
    #@ String -> String
    internal-get-file = filePath: "${core-inputs.src}/${filePath}";

    ## Safely read from a directory if it exists.
    ## Example Usage:
    ## ```nix
    ## safe-read-directory ./some/path
    ## ```
    ## Result:
    ## ```nix
    ## { "my-file.txt" = "regular"; }
    ## ```
    #@ Path -> Attrs
    safe-read-directory = filePath: if pathExists filePath then readDir filePath else { };

    ## Get any files at a given path.
    ## Example Usage:
    ## ```nix
    ## get-files ./something
    ## ```
    ## Result:
    ## ```nix
    ## [ "./something/a-file" ]
    ## ```
    #@ Path -> [Path]
    get-files =
      filePath:
      let
        entries = safe-read-directory filePath;
        filtered-entries = filterAttrs (name: type: is-file-type type) entries;
      in
      mapAttrsToList (name: kind: "${filePath}/${name}") filtered-entries;

    ## Get nix files at a given path named "default.nix".
    ## Example Usage:
    ## ```nix
    ## get-default-nix-files "./something"
    ## ```
    ## Result:
    ## ```nix
    ## [ "./something/default.nix" ]
    ## ```
    #@ Path -> [Path]
    get-default-nix-files =
      filePath: builtins.filter (name: builtins.baseNameOf name == "default.nix") (get-files filePath);

    ## Get files at a given path, traversing any directories within.
    ## Example Usage:
    ## ```nix
    ## get-files-recursive ./something
    ## ```
    ## Result:
    ## ```nix
    ## [ "./something/some-directory/a-file" ]
    ## ```
    #@ Path -> [Path]
    get-files-recursive =
      filePath:
      let
        entries = safe-read-directory filePath;
        filtered-entries = filterAttrs (
          name: type: (is-file-type type) || (is-directory-type type)
        ) entries;
        map-file =
          name: kind:
          let
            filePath' = "${filePath}/${name}";
          in
          if is-directory-type kind then get-files-recursive filePath' else filePath';
        files = arkadia-lib.attrs.map-concat-attrs-to-list map-file filtered-entries;
      in
      files;

    ## Get nix files at a given path, traversing any directories within.
    ## Example Usage:
    ## ```nix
    ## get-nix-files "./something"
    ## ```
    ## Result:
    ## ```nix
    ## [ "./something/a.nix" ]
    ## ```
    #@ Path -> [Path]
    get-nix-files-recursive =
      filePath:
      builtins.filter (arkadia-lib.path.has-file-extension "nix") (get-files-recursive filePath);

    ## Get nix files at a given path named "default.nix", traversing any directories within.
    ## Example Usage:
    ## ```nix
    ## get-default-nix-files-recursive "./something"
    ## ```
    ## Result:
    ## ```nix
    ## [ "./something/some-directory/default.nix" ]
    ## ```
    #@ Path -> [Path]
    get-default-nix-files-recursive =
      filePath:
      builtins.filter (name: builtins.baseNameOf name == "default.nix") (get-files-recursive filePath);

  };
}
