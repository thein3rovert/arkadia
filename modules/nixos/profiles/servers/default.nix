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

  usernames = builtins.attrNames cfg.server;

  create-server =
    system-server: server-host: time-zone:
    let
      hostname = cfg.server.${server-host};
    in
    system-server
    // (optionalAttrs hostname.create {
      ${server-host} = {
        networking.hostName = mkDefault server-host;
        time.timeZone = mkDefault time-zone;
        services.openssh.enable = true;
      };
    });
in
{

}
