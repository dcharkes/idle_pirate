# Asset Treeshaking and Resizing with RecordUse

We use `package:record_use` to record the intended UI sizes of icons and used translation keys in the application. The link hook uses this recorded usage information to perform treeshaking and resizing of assets.

## Icon Modeling

We differentiate between static icons (like `doubloon` and `chest` which have a fixed size) and dynamic icons (like those from items, where the size might depend on the context).

Both classes are annotated with `@RecordUse`:

```dart
@RecordUse()
final class StaticIcon {
  final String id;
  final double size;
  const StaticIcon(@mustBeConst this.id, @mustBeConst this.size);
  // ...
}

@RecordUse()
final class DynamicIcon {
  final String id;
  final double size;
  final String category;
  const DynamicIcon(this.id, @mustBeConst this.size, @mustBeConst this.category);
  // ...
}
```

For items (upgrades, crew, fleet), we use `"item"` as the `category`. This allows us to record that item icons have a specific size.

Furthermore, we `@RecordUse` the `Item` class itself. By combining the recorded usage of `Item` and `DynamicIcon`, we determine the exact size needed for each specific icon in the link hook.

## Translation Modeling

We record uses of `translate` and `translateDynamic` methods:

```dart
@RecordUse()
String translate(@mustBeConst String key) { ... }

@RecordUse()
String translateDynamic(String key, @mustBeConst String category) { ... }
```

The link hook reads the recorded keys and filters the JSON translation files accordingly.

## Rationale for Asset Processing

### Logical vs Physical Pixels in Flutter

In Flutter, dimensions like `width` and `height` in `Image.asset` are specified in **logical pixels**.

- **Logical Pixel**: A device-independent pixel.
- **Physical Pixel**: The actual pixel on the screen.
- **Relationship**: `Physical Pixels = Logical Pixels * Device Pixel Ratio (DPR)`.

If the link hook resizes images to the exact logical size (e.g., `40x40`), they will look blurry on high-density screens (Retina displays with DPR 2.0 or 3.0). To avoid this, we default to generating the largest required size targeting a `3.0x` scale and let Flutter downscale it at runtime.

### Native Asset Slicing vs Flutter Assets

Native platforms have mechanisms (App Slicing on iOS, App Bundles on Android) to exclude high-resolution assets for devices that don't need them. However, Flutter's standard asset management packages all resolution variants into the app bundle.

To avoid bloating the app with multiple variants that everyone would have to download, we generate only the largest required size (targeting `3x`) in the link hook and let Flutter downscale it at runtime.
