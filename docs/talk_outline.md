# Talk Outline: Step-by-Step Tree Shaking in Flutter with Native Assets

This outline describes a live talk/demonstration showing how `package:record_use` and the new Native Assets hook system enable deep, multi-layered tree shaking of diverse asset types (audio, images, translations, and native C libraries).

## Demo Progression & Steps

### Step 0: Base Application (No Tree Shaking)
* **State:** All toggles set to disabled.
* **Toggles:**
  * `enableAudioTreeShaking = false;`
  * `imageTreeShakingLevel = 'none';`
  * `enableTranslationTreeShaking = false;`
  * `enableNativeTreeShaking = false;`
* **Key Concept:** Every single asset file, translation key, and native library symbol is bundled into the application, resulting in the maximum possible app size (~18.5MB).

### Step 1: Audio Tree Shaking (Asset Filtering)
* **State:** Enable audio tree shaking. Unused audio clips are excluded.
* **Toggles:**
  * `enableAudioTreeShaking = true;`
* **Key Concept:** Introduce `@RecordUse` annotation on the `Sound` class. Explain how constant usages are tracked by the compiler and exposed to the package's link hook via `input.recordedUses`, allowing the hook to filter out assets completely before bundling.

### Step 2: Image Tree Shaking (Filtering & Advanced Transformation)
* **State:** Move image tree shaking from `none` to `filterOnly`, then to `filterAndResize`.
* **Toggles:**
  * `imageTreeShakingLevel = 'filterAndResize';`
* **Key Concept:** Tree shaking can be more than just binary inclusion/exclusion. With `Item` abstractions, the link hook can look up the exact metadata (like required logical sizes), filter out unused images, and invoke external tools (like `magick`) to downsample and optimize the remaining images to the exact dimensions needed by the app.

### Step 3: Translation Tree Shaking (Crossing Package Boundaries)
* **State:** Enable translation tree shaking.
* **Toggles:**
  * `enableTranslationTreeShaking = true;`
* **Key Concept:** Demonstrates how assets can cross package boundaries. The `pirate_speak` package provides the translations, but the application package defines which `Item` IDs are actually in use. Using the data asset routing mechanism, the parent package routes category IDs into the `pirate_speak` link hook, which then filters out unused translation keys from its internal JSON files.

### Step 4: Native Library Tree Shaking (C Symbol Stripping)
* **State:** Enable native library tree shaking.
* **Toggles:**
  * `enableNativeTreeShaking = true;`
* **Key Concept:** Reusing the exact same `package:record_use` and link hook architecture for compiled code. The `mini_audio` package link hook inspects which Dart FFI methods were invoked, maps them to the corresponding C symbols via a recorded use mapping, and instructs `LinkerOptions.treeshake` to strip away all unused compiled functions from the final `.dylib`/`.so` binary.
