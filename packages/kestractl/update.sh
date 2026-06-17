#!/usr/bin/env nix-shell
#!nix-shell --pure -i bash -p bash curl jq nix cacert git
set -euo pipefail

# Update kestractl sources.json with the latest release from GitHub.
# Usage: ./update.sh (or via nix-update --update-script)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_FILE="$SCRIPT_DIR/sources.json"

# Map Nix system -> GitHub release asset name fragment
declare -A SYSTEMS=(
  ["x86_64-linux"]="linux_amd64"
  ["aarch64-linux"]="linux_arm64"
)

echo "Fetching latest kestractl release..."
LATEST=$(curl -fsSL "https://api.github.com/repos/kestra-io/kestractl/releases/latest")
VERSION=$(echo "$LATEST" | jq -r '.tag_name')
echo "Latest version: $VERSION"

CURRENT_VERSION=$(jq -r '.version' "$SOURCES_FILE")
if [[ "$VERSION" == "$CURRENT_VERSION" ]]; then
  echo "Already at latest version $VERSION, nothing to do."
  exit 0
fi

NEW_SOURCES="{}"

for NIX_SYSTEM in "${!SYSTEMS[@]}"; do
  ASSET_FRAG="${SYSTEMS[$NIX_SYSTEM]}"
  URL="https://github.com/kestra-io/kestractl/releases/download/${VERSION}/kestractl_${VERSION}_${ASSET_FRAG}.tar.gz"

  echo "Fetching hash for $NIX_SYSTEM ($URL)..."
  HASH=$(nix-prefetch-url --type sha256 "$URL" 2>/dev/null)
  SRI=$(nix hash to-sri --type sha256 "$HASH")

  NEW_SOURCES=$(echo "$NEW_SOURCES" | jq \
    --arg sys "$NIX_SYSTEM" \
    --arg url "$URL" \
    --arg hash "$SRI" \
    '. + {($sys): {url: $url, hash: $hash}}')
done

jq -n \
  --arg version "$VERSION" \
  --argjson sources "$NEW_SOURCES" \
  '{"version": $version, "sources": $sources}' \
  > "$SOURCES_FILE"

echo "Updated $SOURCES_FILE to $VERSION"


#INFO: Commit when running in CI or via nix-update

if [[ -d "$SCRIPT_DIR/../../.git" ]] || git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  NIXPKGS_ROOT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)
  if [[ -n "$NIXPKGS_ROOT" && -n "$(git -C "$NIXPKGS_ROOT" status --porcelain "$SOURCES_FILE")" ]]; then
    git -C "$NIXPKGS_ROOT" add "$SOURCES_FILE"
    git -C "$NIXPKGS_ROOT" commit -m "kestractl: ${CURRENT_VERSION} -> ${VERSION}"
    echo "Committed update to git"
  fi
fi

