args@{
  # We used arg@ so that we can both pick specific values and keep the original set around.
  pkgs,
  lib,
  options,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    mkDefault
    mkRenameOptionModule
    foldl
    optionalAttrs
    optional
    ;

  cfg = config.arkadia;

  inputs = args.inputs or { };

  # usernames will be config.arkadia.users.{{name}}
  usernames = builtins.attrNames cfg.users;

  create-users =
    system-users: name:
    let
      user = cfg.users.${name};

    in
    system-users
    //
      /*
        Used to merge two attrset
        { a = 1; b = 2; } // { b = 3; c = 4; }
        { a = 1; b = 3; c = 4; }
      */

      # New attrset called user.create.name
      (optionalAttrs user.create {
        ${name} = {
          isNormalUser = mkDefault true;
          name = mkDefault name;

          # cfg.users.{{name}}.home.path = [];
          home = mkDefault user.home.path;
          group = mkDefault "users";

          # cfg.users.{{name}}.{{admin}} = [];
          extraGroups = optional user.admin "wheel";
        };
      });
in
{

}
