#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter nao encontrado no PATH. Instale-o antes de continuar." >&2
  exit 1
fi

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temporary_dir="$(mktemp -d)"
trap 'rm -rf "${temporary_dir}"' EXIT

# Gera somente os arquivos binarios/padrao do Gradle Wrapper que nao devem ser
# recriados manualmente. A configuracao Android do app permanece intacta.
flutter create \
  --platforms=android \
  --project-name=aqua_monitor \
  --org=br.edu \
  "${temporary_dir}/wrapper_source" >/dev/null

mkdir -p "${project_dir}/android/gradle/wrapper"
cp "${temporary_dir}/wrapper_source/android/gradlew" \
  "${project_dir}/android/gradlew"
cp "${temporary_dir}/wrapper_source/android/gradlew.bat" \
  "${project_dir}/android/gradlew.bat"
cp "${temporary_dir}/wrapper_source/android/gradle/wrapper/gradle-wrapper.jar" \
  "${project_dir}/android/gradle/wrapper/gradle-wrapper.jar"
cp "${temporary_dir}/wrapper_source/android/gradle/wrapper/gradle-wrapper.properties" \
  "${project_dir}/android/gradle/wrapper/gradle-wrapper.properties"
chmod +x "${project_dir}/android/gradlew"

echo "Gradle Wrapper preparado em ${project_dir}/android."

