# iPhone and iPad build setup

The same Godot scene, physics, mode selector, touch controls, cosmetics, and local score storage are used on Android and iOS. There are no Android-specific runtime plugins or APIs. The existing Compatibility renderer is supported by Godot's native iOS OpenGL ES backend; its Android rendering settings have not been changed.

An **iOS** export preset is included for iPhone and iPad, with iOS 14.0 minimum, portrait orientation inherited from the project, bundle identifier `org.skybounce.keepitup`, version 1.2.0, and build number 4. It exports an Xcode project so signing can be configured by the owner. Godot generates icon sizes from the existing vector app icon.

## Build/install on an iPhone or iPad

1. Use a Mac with Xcode and its iOS SDK installed. Open Xcode once to complete component setup and accept its terms.
2. Install Godot 4.6.3 Standard and its matching export templates. Import `project.godot`.
3. In **Project → Export → iOS**, enter your Apple development Team ID. This is intentionally blank in the repository; no signing identity or provisioning profile is fabricated or committed. Set a bundle identifier registered/available for your team if needed.
4. Keep **Application → Export Project Only** enabled. Create a local output folder under `builds/ios/`, then export the project.
5. Open the generated `.xcodeproj` in Xcode. Select your team under **Signing & Capabilities**, allow automatic signing, select a connected iPhone/iPad, and press Run. Xcode will explain any account/device provisioning steps still needed. Enable Developer Mode on the device if required.

An Apple ID can support limited local device testing through Xcode; distribution/TestFlight has additional Apple enrollment and signing requirements. An Android APK cannot be installed on iOS.

## What was checked here

- Godot imports the shared scene and scripts, and all 85 headless gameplay/regression checks pass.
- The iOS preset successfully produces a game-data PCK containing the shared game controller and mode adapter.
- Native Xcode compilation, Apple signing/provisioning, Metal/OpenGL behavior on hardware, and an iPhone/iPad installation **were not run** in this Linux environment.

## Device smoke test

Check both Classic and Reverse at different phone/tablet sizes: dragging in the playfield, pause buttons and score visibility near safe areas, background/resume, bounce direction, miss/loss edge, level colors, sound, and saved mode scores after closing and reopening. Reverse's HUD reserves bottom space for gesture navigation; Classic retains its existing layout. Inspect cutouts/Dynamic Island areas on an actual iPhone before distributing an iOS build.
