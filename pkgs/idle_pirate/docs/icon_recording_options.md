# Design Exploration: Recording Icon Sizes with RecordUse

## Problem Description

We want to record the intended UI sizes of icons used in the application (for asset tree shaking or resizing) using `package:record_use`. Currently, `GameIcon` is defined with only an `id` string and is used directly in the `Upgrade` model (business logic).

If we want to record the size of the icon when used, we have a few challenges:
1. **Separation of Concerns**: Adding UI-specific information like `size` to `GameIcon` (which is used in business logic) violates the separation of concerns between business logic and UI.
2. **Duplication**: If we separate them, we might end up duplicating identifiers (e.g., string IDs) and need to manually match them up, which is error-prone.

Here we explore different options for structuring the code to achieve this goal, listing their pros and cons.

---

## Option 1: Separate UI Icon from Business Logic ID

Keep `GameIcon` in `Upgrade` as a pure business logic identifier (just containing the string ID). Create a new type for UI rendering, e.g., `UiGameIcon` or `IconResource`, which contains both the `GameIcon` and the `size`.

### Code Example

```dart
// models/upgrade.dart
final class GameIcon {
  final String id;
  const GameIcon(this.id);
}

// ui/screens/game_screen.dart
@RecordUse()
final class UiGameIcon {
  final GameIcon icon;
  final double size;
  const UiGameIcon(this.icon, this.size);
}
```

### Pros
- **Strict separation of concerns**: UI sizes stay in UI code.
- `Upgrade` remains clean and independent of how it's rendered.

### Cons
- **Verbosity**: When using an upgrade in the UI, you need to map its `GameIcon` to a `UiGameIcon` with a size, or pass the size explicitly.
- **Duplication**: You effectively create a new instance for every size, but you still need to match the `GameIcon.id` to find the asset.

---

## Option 2: String IDs in Business Logic, Centralized Icon Map in UI

`Upgrade` uses simple string IDs for icons. The UI defines a map or list of `const GameIcon` instances that map these strings to their display properties (including size).

### Code Example

```dart
// models/upgrade.dart
class Upgrade {
  final String iconId;
  // ...
}

// ui/icons.dart
@RecordUse()
class GameIcon {
  final String id;
  final double size;
  const GameIcon(this.id, this.size);
}

const icons = {
  'sharper_hooks': GameIcon('sharper_hooks', 40),
  ...
};
```

### Pros
- **Separation of concerns**: `Upgrade` only cares about the identifier string.
- All icon rendering configuration is in one place.

### Cons
- **Less type safety**: `Upgrade` uses raw strings instead of a specific type.
- **Manual matching**: Need to manually match string IDs in Upgrades with keys in the UI map.

---

## Option 3: Shared Concept with Optional Size

Accept that `GameIcon` is a bridge between business logic and UI. It has an `id` and an optional `size` (defaulting to a standard size or null).

### Code Example

```dart
@RecordUse()
final class GameIcon {
  final String id;
  final double? size;
  const GameIcon(this.id, [this.size]);
}
```

### Pros
- **Simple**: Leverages existing structure.
- **Minimal code change**: Easy to implement.

### Cons
- **Slight concern violation**: Business logic instances of `Upgrade` will hold `GameIcon` objects that could potentially contain UI sizes (though they likely won't).

---

## Option 4: Metadata Annotation purely for Recording

Use a separate class purely for recording usage of sizes, unrelated to the actual rendering path, but used alongside it.

### Code Example

```dart
@RecordUse()
class IconUsage {
  final String id;
  final double size;
  const IconUsage(this.id, this.size);
}

// Used in UI:
const _ = IconUsage('chest', 40);
```

### Pros
- **Decoupled**: Decouples the recording mechanism from core types.
- Flexible for recording any kind of usage.

### Cons
- **Developer discipline**: Requires developers to remember to create these instances whenever an icon size is used.

---

## Option 5: Icon Types instead of Sizes in Code

Instead of recording sizes in the code, record "icon types" or categories (e.g., `'upgrade'`, `'currency'`, `'generator'`) and define the size mapping directly in the link hook.

### Code Example

```dart
@RecordUse()
class GameIcon {
  final String id;
  final String type;
  const GameIcon(this.id, this.type);
}

// In link hook:
const sizeMap = {
  'upgrade': 40.0,
  'currency': 30.0,
  'generator': 60.0,
};
```

### Pros
- **Semantic**: Code records the *meaning* or *category* of the icon, not the UI representation.
- **Flexibility**: Centralized sizing logic in the link hook.

### Cons
- **Implicit**: Sizes are not visible in the UI code, leading to potential mismatch if the UI expects a different size.

---

## Option 6: Maximum Size Fallback

Ignore sizes in the code and simply generate/keep the maximum needed size for all icons in the link hook.

### Pros
- **Simplest**: No changes to code required for size recording.
- Guarantees high quality if the maximum size is used.

### Cons
- **No Optimization**: Defeats the purpose of resizing if all icons are kept at max size.

---

## Appendix: Logical vs Physical Pixels in Flutter

In Flutter, dimensions like `width` and `height` in `Image.asset` are specified in **logical pixels**.

- **Logical Pixel**: A device-independent pixel. One logical pixel is roughly 1/38th of an inch, or 0.7 millimeters.
- **Physical Pixel**: The actual pixel on the screen.
- **Relationship**: `Physical Pixels = Logical Pixels * Device Pixel Ratio (DPR)`.

### Implications for Resizing

If you specify an icon size of `40` in the UI:
- On a standard display (`DPR = 1.0`), it uses `40x40` physical pixels.
- On a Retina display or high-density screen (`DPR = 2.0` or `3.0`), it uses `80x80` or `120x120` physical pixels.

If the link hook resizes images to `40x40` physical pixels based on logical pixel usage, the images will look blurry on high-density screens. To support all devices correctly:
1. Generate assets at multiple scales (`1x`, `2x`, `3x`) and place them in corresponding folders (e.g., `2.0x/`, `3.0x/`).
2. Or target the highest expected resolution (e.g., `3x` or max size) and let Flutter downscale it at runtime.

---

## Native Asset Slicing vs Flutter Assets

Native platforms have mechanisms to exclude high-resolution assets for devices that don't need them:
- **iOS**: Uses **App Slicing** (part of App Thinning) with Asset Catalogs. The store delivers only the `@2x` or `@3x` assets needed for the device.
- **Android**: Uses **Android App Bundles** (`.aab`). Google Play generates configuration APKs split by screen density, delivering only the relevant folder (e.g., `xxhdpi`) to the device.

### Flutter Limitation
Flutter's standard asset management (listing files in `pubspec.yaml`) does **not** support this native slicing automatically. All resolution variants (`2.0x`, `3.0x`) placed in the Flutter asset bundle are packaged into the app and downloaded by all users, regardless of their device's density.

To bypass this and use native slicing, one would have to:
- Put images in native folders ([Assets.xcassets](https://developer.apple.com/documentation/xcode/managing-assets-with-asset-catalogs) for iOS, [res/drawable-...](https://developer.android.com/guide/topics/resources/providing-resources) for Android).
- Load them via **Method Channels** or specific packages, which complicates the cross-platform code.

### Conclusion for This Project
Since we want to keep a simple, unified cross-platform codebase without Method Channels for assets, we cannot rely on app stores to exclude unused large assets.

Therefore, we default to **generating only the largest required size** (e.g., targeting `3x` or a specific max size) in the link hook and letting Flutter downscale it at runtime. This avoids bloating the app with multiple variants that everyone would have to download.
