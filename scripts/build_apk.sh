#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${project_dir}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter nao encontrado no PATH." >&2
  exit 1
fi

if [[ ! -f android/gradle/wrapper/gradle-wrapper.jar ]]; then
  "${project_dir}/scripts/bootstrap_android.sh"
fi

flutter doctor
flutter pub get
flutter analyze
flutter test
flutter build apk --release

apk_path="${project_dir}/build/app/outputs/flutter-apk/app-release.apk"
echo "APK gerado: ${apk_path}"

