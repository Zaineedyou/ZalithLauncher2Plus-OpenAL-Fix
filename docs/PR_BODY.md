## Native OpenAL-Soft fix for Minecraft 26.1.2 on Android arm64

### Summary

This updates the arm64-v8a OpenAL library from the bundled OpenAL Soft 1.20.1 build to OpenAL-Soft 1.24.2 and removes the `ALSOFT_DISABLE_EVENTS=1` workaround.

### Root cause

Minecraft 26.1.2 calls LWJGL's `org.lwjgl.openal.SOFTSystemEvents.alcEventIsSupportedSOFT`. The previous bundled arm64 `libopenal.so` identified itself as OpenAL Soft 1.20.1 and did not contain `ALC_SOFT_system_events` or `alcEventIsSupportedSOFT`. LWJGL consequently received an unresolved native function address and failed during `SoundEngine` initialization.

This was not a backend event-support result being returned incorrectly. The extension implementation was missing from the old native library.

### Fix

OpenAL-Soft 1.24.2 is built for `arm64-v8a` with the Android OpenSL backend. OpenAL-Soft now includes the system-events API. Android/OpenSL reports `ALC_EVENT_NOT_SUPPORTED_SOFT` through the default backend implementation when device hotplug events are unavailable; event support is not globally disabled, and a capable backend can still report support.

The updated library is included in both packaging paths:

- `ZalithLauncher/src/main/jniLibs/arm64-v8a/libopenal.so`
- `ZalithLauncher/libs/openal-soft-release.aar` (`jni/arm64-v8a/libopenal.so`)

The reproducible build is documented in `tools/build-openal-soft-android.sh` and `docs/openal-soft-android.md`.

### Validation

The rebuilt library is an AArch64 Android ELF shared object and contains the `ALC_SOFT_system_events` marker. The launcher no longer sets `ALSOFT_DISABLE_EVENTS`.

The Gradle APK build could not be completed in the isolated environment because no Android SDK was installed; the native OpenAL build and binary/AAR checks passed. This change currently covers arm64-v8a. The remaining ABI entries should be rebuilt from OpenAL-Soft 1.24.2 before a multi-ABI release.
