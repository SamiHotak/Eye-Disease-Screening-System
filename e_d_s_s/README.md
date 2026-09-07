# OSS — Ocular Screening System (Phase 2)

Flutter app that runs the Phase 1 multi-label fundus model fully on-device.
Three pages, same design system as PDDS: **Screen** (prediction), **System**
(about), **Developer**.

---

## 1. Create the project

In Android Studio: **New → New Flutter Project → Flutter Application**.

- Project name: `ocular_screener`
- Finish, let it build once so the `android/` and `ios/` folders exist.

## 2. Drop these files in

From this package, copy over the generated project:

| From here | To |
|---|---|
| `lib/` (whole folder, replacing the default one) | `<project>/lib/` |
| `pubspec.yaml` | `<project>/pubspec.yaml` |

Delete the default `lib/main.dart` first so nothing lingers.

## 3. Add the model assets

Create `<project>/assets/` and copy in the four files from
`phase1_assets.zip` (the Colab download):

```
assets/model.tflite
assets/labels.txt
assets/thresholds.json
assets/model_info.json
```

All four are already declared in `pubspec.yaml`. `model_info.json` is what
tells the app the input size and quantization parameters — if you re-export the
model at a different size, just replace the file, no code change needed.

## 4. Android configuration

**`android/app/src/main/AndroidManifest.xml`** — add above `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

And set the launcher label on `<application>`:

```xml
android:label="OSS"
```

**`android/app/build.gradle`** (or `build.gradle.kts`) — inside `defaultConfig`:

```
minSdkVersion 26
```

TFLite's delegates want 26+. If Gradle complains about `ndkVersion`, set the
version it names in the error inside the `android { }` block.

If you hit the JVM target error you saw on PDDS, add to
`android/gradle.properties`:

```
kotlin.jvm.target.validation.mode=IGNORE
```

## 5. Run

```powershell
flutter pub get
flutter run
```

---

## The model contract — do not break this

The app reproduces Phase 1's preprocessing exactly: circular fundus crop,
grey-world white balance, CLAHE on the LAB lightness channel, area-average
resize. That port was verified numerically against the OpenCV original
(mean absolute difference 1.3/255).

If you ever change `preprocess.py`, change `lib/services/preprocessor.dart`
to match — otherwise the model sees a different image distribution than it
trained on and accuracy silently drops.

Pixels go in as raw 0–255. With `--io uint8` the export has scale 1.0 and
zero point 0, so no normalisation is applied.

## Threshold modes

| Mode | Cut-off | Use |
|---|---|---|
| Sensitive | 0.30 flat | Screening: catch more, accept false alarms |
| Balanced | per-class from `thresholds.json` | Default, tuned for best F1 |
| Specific | 0.50 flat | Flag only confident findings |

The tick mark on each confidence bar shows that condition's threshold.

## Editing your details

Everything user-facing lives in `lib/data/app_info.dart` — app name, tagline,
developer name, email, phone, institution, and the performance figures shown
on the System page. Fill in `developerName`, `developerEmail`,
`developerPhone`, and replace the metric placeholders with the numbers from
your notebook's metrics cell.

To change the accent colour, edit `accent` in `lib/theme/app_theme.dart`; the
whole app follows.

## Not included, deliberately

On-device Grad-CAM is not possible — TFLite has no gradients, so the technique
cannot run on a phone. The honest substitute is occlusion sensitivity (slide a
patch across the image, watch which regions drop the score), which needs 25–36
extra inferences per heatmap. Left out to keep this build simple; it can be
added as a toggle later.
