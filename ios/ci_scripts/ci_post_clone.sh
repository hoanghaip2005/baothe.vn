#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "error: Missing Xcode Cloud environment variable GEMINI_API_KEY"
  exit 1
fi

mkdir -p lib/src/constants
cat > lib/src/constants/api_keys.dart <<EOF
class ApiKeys {
  static const geminiApiKey = '$GEMINI_API_KEY';
}
EOF

FLUTTER_HOME="$HOME/flutter"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version
flutter pub get
flutter precache --ios

if ! command -v pod >/dev/null 2>&1; then
  brew install cocoapods
fi

cd ios
pod install --repo-update
