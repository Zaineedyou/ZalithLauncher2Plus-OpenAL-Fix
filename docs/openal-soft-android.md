# OpenAL-Soft Android arm64 build

The bundled OpenAL library previously identified itself as **OpenAL Soft 1.20.1** and did not contain the `ALC_SOFT_system_events` implementation required by Minecraft 26.1.2's LWJGL binding. The launcher workaround set `ALSOFT_DISABLE_EVENTS=1`; that only bypassed the failure and was removed.

This fork now bundles an **OpenAL-Soft 1.24.2** arm64-v8a build. OpenAL-Soft 1.24.2 includes `alcEventIsSupportedSOFT` and advertises `ALC_SOFT_system_events`. The Android OpenSL backend does not provide device hotplug events, so the backend inherits the normal `ALC_EVENT_NOT_SUPPORTED_SOFT` result. A backend that supports events can still report `ALC_EVENT_SUPPORTED_SOFT`; the extension is not globally disabled.

## Rebuild

Install an Android NDK and set `ANDROID_NDK` (or `ANDROID_NDK_HOME`), then run:

```sh
ANDROID_NDK=/path/to/android-ndk ./tools/build-openal-soft-android.sh
```

The script uses the `1.24.2` tag from [OpenAL-Soft](https://github.com/kcat/openal-soft), configures the `arm64-v8a` ABI with the OpenSL backend, builds `libopenal.so`, and verifies that the resulting binary contains `ALC_SOFT_system_events`.

The binary is copied to both launcher packaging paths: `ZalithLauncher/src/main/jniLibs/arm64-v8a/libopenal.so` and the arm64 entry inside `ZalithLauncher/libs/openal-soft-release.aar`.

## Verification performed

The old arm64 library exported `alcGetProcAddress`, `alcIsExtensionPresent`, and `alcOpenDevice`, but contained neither `ALC_SOFT_system_events` nor `alcEventIsSupportedSOFT`. The rebuilt library contains both strings and is an `ELF 64-bit LSB shared object, ARM aarch64` linked against Android's OpenSL ES library. The launcher no longer sets `ALSOFT_DISABLE_EVENTS`.

This change was built and verified for **arm64-v8a only**. The other ABI entries in the existing AAR remain unchanged and should be rebuilt from the same OpenAL-Soft tag before a multi-ABI release.
