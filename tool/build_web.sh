#!/bin/bash
# Builds the browser version into build/web_publish/ with only the files the
# page needs. The hosting sandbox blocks requests to other sites, so the
# rendering engine (CanvasKit) and fonts are bundled locally.
# Usage: tool/build_web.sh
#   BASE_HREF=/idle-orbit-game/ tool/build_web.sh   # when served under a sub-path (GitHub Pages)
set -e
cd "$(dirname "$0")/.."
flutter build web --release --no-web-resources-cdn --base-href "${BASE_HREF:-/}"
OUT=build/web_publish
rm -rf "$OUT" && mkdir -p "$OUT"
cd build/web
# Skip debug symbols, renderers this build doesn't use, the service worker
# (not supported where it's hosted) and binary manifests/shaders it never loads.
find . -type f \
  ! -name "*.symbols" ! -name ".last_build_id" ! -name "flutter_service_worker.js" \
  ! -name "AssetManifest.bin" ! -name "*.frag" \
  ! -path "./canvaskit/skwasm*" ! -path "./canvaskit/wimp*" ! -path "./canvaskit/webparagraph/*" \
  ! -path "./assets/packages/flutter_local_notifications_web/*" \
  -exec cp --parents {} "../../$OUT" \;
cd ../..
echo "Built $OUT ($(du -sh "$OUT" | cut -f1), $(find "$OUT" -type f | wc -l) files)"
