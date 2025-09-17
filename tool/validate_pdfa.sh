#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/samples/pdfs"
VERAPDF_IMAGE="${VERAPDF_IMAGE:-docker.io/verapdf/cli:latest}"

pushd "$PROJECT_ROOT" >/dev/null

echo "Generating sample PDFs via Dart script..."
if ! command -v dart &>/dev/null && ! command -v flutter &>/dev/null; then
  echo "Neither dart nor flutter command is available. Please install one to run the generator." >&2
  exit 1
fi

if command -v dart &>/dev/null; then
  dart run tool/generate_sample_pdfs.dart
else
  flutter pub get >/dev/null
  flutter pub run tool/generate_sample_pdfs.dart
fi

echo "Validating PDFs with veraPDF (Docker)..."
if ! command -v docker &>/dev/null; then
  echo "Docker is required to run veraPDF locally." >&2
  exit 1
fi

docker run --rm -v "$OUTPUT_DIR:/work" "$VERAPDF_IMAGE" \
  --format text --maxfail 1 --failonerror /work/*.pdf

echo "PDF/A validation completed successfully."

popd >/dev/null