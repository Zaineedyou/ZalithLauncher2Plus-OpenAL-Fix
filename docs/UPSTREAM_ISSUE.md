## Android arm64: bundled OpenAL Soft 1.20.1 lacks ALC_SOFT_system_events

### Environment

- ZalithLauncher2 / ZalithLauncher2Plus
- Android arm64-v8a
- Minecraft 26.1.2
- LWJGL 3.3.6 snapshot
- Java 25

### Crash

Minecraft crashes during client initialization at:

```text
org.lwjgl.system.Checks.check(Checks.java:188)
org.lwjgl.openal.SOFTSystemEvents.alcEventIsSupportedSOFT(SOFTSystemEvents.java:61)
com.mojang.blaze3d.audio.CallbackDeviceTracker.isSupportedForPlaybackDevice(CallbackDeviceTracker.java:76)
```

### Findings

The bundled arm64 library identifies itself as OpenAL Soft 1.20.1. Its exported API includes `alcGetProcAddress`, `alcIsExtensionPresent`, and `alcOpenDevice`, but the binary contains neither `ALC_SOFT_system_events` nor `alcEventIsSupportedSOFT`. OpenAL-Soft 1.20.1 source also has no system-events implementation. Minecraft 26.1.2 nevertheless asks LWJGL for this API during `SoundEngine` construction.

The failure is therefore caused by an outdated native OpenAL library, not by a supported backend returning the wrong event result. Setting `ALSOFT_DISABLE_EVENTS=1` masks the problem and should not be required.

### Proposed fix

Update the Android OpenAL-Soft dependency to 1.24.2 or a later compatible release. Build the arm64-v8a library with the OpenSL backend. The newer implementation exposes `ALC_SOFT_system_events`; on Android/OpenSL, unsupported hotplug events correctly return `ALC_EVENT_NOT_SUPPORTED_SOFT` through the default backend behavior, while capable backends remain able to report support.

A reproducible build script and validation notes are included in the corresponding ZalithLauncher2Plus patch. The same dependency update should be applied to the upstream launcher so all forks receive a native library compatible with current Minecraft/LWJGL clients.

### Attachments / evidence

- Crash report: `crash-2026-09-05_00.57.29-client.txt`
- Old library version marker: `1.20.1`
- Rebuilt library version marker: `1.24.2`
- Rebuilt library contains: `ALC_SOFT_system_events`, `alcEventIsSupportedSOFT`
