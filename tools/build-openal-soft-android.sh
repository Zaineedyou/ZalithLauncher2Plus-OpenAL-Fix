#!/usr/bin/env bash
set -euo pipefail

# Rebuild the native OpenAL library used by ZalithLauncher for Android arm64.
# OpenAL-Soft 1.24.x implements ALC_SOFT_system_events. Android/OpenSL does
# not implement hotplug events, so the API reports ALC_EVENT_NOT_SUPPORTED_SOFT
# rather than leaving LWJGL's function pointer unresolved.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-${ROOT_DIR}/.openal-build}"
OPENAL_TAG="${OPENAL_TAG:-1.24.2}"
OPENAL_REPO="${OPENAL_REPO:-https://github.com/kcat/openal-soft.git}"
ANDROID_NDK="${ANDROID_NDK:-${ANDROID_NDK_HOME:-}}"

if [[ -z "${ANDROID_NDK}" || ! -f "${ANDROID_NDK}/build/cmake/android.toolchain.cmake" ]]; then
  echo "ANDROID_NDK must point to an installed Android NDK" >&2
  exit 2
fi

mkdir -p "${WORK_DIR}"
if [[ ! -d "${WORK_DIR}/openal-soft/.git" ]]; then
  git clone --depth 1 --branch "${OPENAL_TAG}" "${OPENAL_REPO}" "${WORK_DIR}/openal-soft"
fi

cmake -S "${WORK_DIR}/openal-soft" -B "${WORK_DIR}/build-arm64" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK}/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release \
  -DLIBTYPE=SHARED \
  -DALSOFT_BACKEND_OPENSL=ON \
  -DALSOFT_BACKEND_OBOE=OFF \
  -DALSOFT_BACKEND_ALSA=OFF \
  -DALSOFT_BACKEND_PULSEAUDIO=OFF \
  -DALSOFT_BACKEND_PIPEWIRE=OFF \
  -DALSOFT_BACKEND_JACK=OFF \
  -DALSOFT_BACKEND_COREAUDIO=OFF \
  -DALSOFT_BACKEND_SDL2=OFF \
  -DALSOFT_UTILS=OFF \
  -DALSOFT_EXAMPLES=OFF \
  -DALSOFT_TESTS=OFF
cmake --build "${WORK_DIR}/build-arm64" --target OpenAL --parallel

mkdir -p "${ROOT_DIR}/ZalithLauncher/src/main/jniLibs/arm64-v8a"
cp "${WORK_DIR}/build-arm64/libopenal.so" \
  "${ROOT_DIR}/ZalithLauncher/src/main/jniLibs/arm64-v8a/libopenal.so"

nm -D --defined-only "${ROOT_DIR}/ZalithLauncher/src/main/jniLibs/arm64-v8a/libopenal.so" >/dev/null
if ! grep -a -q 'ALC_SOFT_system_events' \
  "${ROOT_DIR}/ZalithLauncher/src/main/jniLibs/arm64-v8a/libopenal.so"; then
  echo "The resulting library does not contain ALC_SOFT_system_events" >&2
  exit 1
fi

echo "Built and verified: ${ROOT_DIR}/ZalithLauncher/src/main/jniLibs/arm64-v8a/libopenal.so"
sha256sum "${ROOT_DIR}/ZalithLauncher/src/main/jniLibs/arm64-v8a/libopenal.so"
