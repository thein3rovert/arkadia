{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
let
  sources = lib.importJSON ./sources.json;
  source = sources.sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "kestractl";
  version = sources.version;

  src = fetchurl {
    inherit (source) url hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  unpackPhase = ''
    tar -xzf $src
  '';

  installPhase = ''
    install -Dm755 kestractl $out/bin/kestractl
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "CLI for the Kestra workflow orchestration platform";
    homepage = "https://github.com/kestra-io/kestractl";
    license = licenses.asl20;
    platforms = attrNames sources.sources;
    mainProgram = "kestractl";
  };
}
