# Retinal Disease Screening

An offline-capable Android application that screens colour fundus photographs for multiple
retinal diseases, reports calibrated confidence scores, and explains its predictions with
visual attention maps — all running on-device via LiteRT.

<!-- Add badges once your repo is public, e.g.
![License](https://img.shields.io/badge/license-MIT-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![PyTorch](https://img.shields.io/badge/PyTorch-2.x-EE4C2C?logo=pytorch)
-->

---

> ### ⚠️ Not a medical device
>
> This is a **screening triage aid built as a portfolio and research project**. It is not a
> regulated medical device, has not been validated on prospective clinical data, and must
> not be used to make clinical decisions. Any result it produces requires confirmation by a
> qualified ophthalmologist.
>
> It also requires a **fundus lens adapter** (such as a 20D indirect ophthalmoscopy lens or
> a commercial smartphone attachment). A bare smartphone camera cannot image the retina.

---

## Screenshots

<!-- Replace with real screenshots — this is the first thing anyone looks at.
     Recommended: capture screen, results screen with confidence bars, Grad-CAM overlay.

| Capture | Results | Explainability |
|---|---|---|
| <img src="docs/screenshots/capture.png" width="240"> | <img src="docs/screenshots/results.png" width="240"> | <img src="docs/screenshots/gradcam.png" width="240"> |
-->

## What it does

Point the camera through a fundus lens at a patient's retina. The app captures the image,
rejects it if it isn't a gradable fundus photograph, runs inference entirely on-device, and
returns:

1. **A referral decision** — does this eye need to be seen by an ophthalmologist?
2. **Per-condition probabilities** across the detectable disease set
3. **A diabetic retinopathy severity grade** (0–4, ICDR scale)
4. **A visual attention map** showing which retinal regions drove the prediction

No network connection required. No images leave the device.

## Results

<!-- FILL THESE IN from results/final_evaluation.json — do not leave placeholder values. -->

**Internal test set** (held-out patients from the training distribution)

| Metric | Value |
|---|---|
| Referable-disease AUROC | `0.XXX` (95% CI `0.XXX–0.XXX`) |
| Sensitivity @ operating point | `0.XXX` |
| Specificity @ operating point | `0.XXX` |
| Multi-label macro AUROC | `0.XXX` |
| DR quadratic weighted kappa | `0.XXX` |

**External validation** — Messidor-2 and IDRiD, never seen during training, validation,
threshold selection, or model selection.

| Metric | Value |
|---|---|
| Referable-DR AUROC (Messidor-2) | `0.XXX` (95% CI `0.XXX–0.XXX`) |
| **Internal → external drop** | **`0.XXX`** |

That drop is the most honest number in this repository. Cross-dataset degradation of
roughly 0.05–0.20 AUROC is the expected and healthy behaviour of a model that learned
pathology rather than dataset artefacts. Published benchmarks on this task report external
Messidor-2 performance in the 0.67–0.85 range.

Accuracy is deliberately absent from every headline metric. On a screening dataset where
most eyes are normal, predicting "normal" for everything scores well and detects nothing.

### On-device performance

| Variant | Size | Latency (mid-range Android) |
|---|---|---|
| Float16 | `XX MB` | `XXX ms` |
| INT8 | `XX MB` | `XXX ms` |

<!-- Name the actual test device, e.g. "Samsung Galaxy A54, CPU + XNNPACK" -->

## How it works

### One encoder, three heads

Rather than a single flat classifier, the model shares one visual encoder across three
clinically distinct tasks. This lets each public dataset contribute exactly what its labels
actually support, instead of forcing incompatible label schemes into one space.

```
                      ┌──────────────────────┐
   fundus image ─────▶│   shared encoder     │
                      └──────────┬───────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          ▼                      ▼                      ▼
    ┌───────────┐         ┌─────────────┐        ┌─────────────┐
    │  HEAD A   │         │   HEAD B    │        │   HEAD C    │
    │  binary   │         │ multi-label │        │ DR ordinal  │
    │ referable │         │ conditions  │        │    0 – 4    │
    └───────────┘         └─────────────┘        └─────────────┘
     PRIMARY               SECONDARY              SECONDARY
```

### Missing labels are masked, not invented

Each dataset labels different things. The unified manifest stores `NaN` where a source
carries no label, and every loss function takes a mask so those entries contribute **zero
gradient**. Treating "not labelled" as "not present" is the most common silent bug in
multi-dataset training — it teaches the model that most diseases are absent in most images
and destroys the rare classes.

### Preprocessing

Applied identically during training and in the app. Any deviation between the two is a
domain shift the model was never trained for.

1. **Retina localisation and circular crop** — standardises effective resolution across
   cameras with wildly different amounts of black border
2. **Pad to square** — preserves aspect ratio; stretching distorts lesion geometry
3. **CLAHE on the L channel in LAB space** — local contrast without hue distortion
4. **Ben Graham background subtraction** — removes vignetting and inter-camera colour cast,
   making small red lesions visible

### Calibrated confidence, not raw softmax

The app displays a confidence score, so those probabilities have to be honest. Modern
networks are systematically overconfident, and training uses a balanced sampler while real
screening prevalence is far lower.

Plain temperature scaling **cannot fix the second problem** — it rescales confidence but
cannot move the base rate. This project uses Platt scaling (temperature **and** bias),
fitted on the validation set only and baked directly into the exported graph so the app
cannot get it wrong.

### Explainability, measured rather than asserted

Most projects show a Grad-CAM overlay and assert it looks correct. This one scores the
attention maps against **IDRiD's pixel-level lesion masks** using pointing-game accuracy,
IoU, and saliency mass concentrated on lesion pixels versus chance.

<!-- FILL: report your actual numbers here, whatever they are.
     A weak result is a legitimate finding and more credible than three
     cherry-picked overlays. -->

## Methodological safeguards

These are the things that separate this from a notebook that reports 97% accuracy:

- **Patient-level splits** with a hard assertion that no patient spans two splits. ODIR and
  EyePACS contain both eyes per patient; a random image-level split leaks a patient across
  train and test and inflates every metric.
- **Perceptual-hash deduplication** across all sources before splitting. Kaggle mirrors
  contain re-encodings of the same images.
- **External validation** on two datasets never touched during development.
- **Bootstrap confidence intervals** on every primary metric.
- **Per-source breakdowns**, never only pooled numbers — pooled metrics hide the case where
  a model works on one dataset and fails on another.
- **Data-derived class list.** Conditions below a pre-registered support threshold are
  folded into an "other finding" label rather than reported with meaningless per-class
  metrics on a handful of positives. The excluded tail is documented, not hidden.
- **Post-quantisation re-evaluation.** Quantisation shifts the output distribution and
  moves the operating threshold; shipping float-derived thresholds with an INT8 model is a
  real and common bug.
- **Input gating.** A screening app that confidently grades a photograph of a ceiling is
  worse than useless, so images are rejected if they aren't gradable fundus photographs.

## Tech stack

**Machine learning**
PyTorch · timm · albumentations · OpenCV · scikit-learn · LiteRT (`litert-torch`)

**Application**
Flutter · Dart · `camera` · LiteRT Android runtime (`com.google.ai.edge.litert`)

<!-- Adjust to match your actual pubspec.yaml — list the real inference plugin you used. -->

## Repository structure

```
├── ml/                            Phase 1 — machine learning
│   ├── retina/
│   │   ├── config.py              paths, taxonomy, hyperparameters
│   │   ├── data/
│   │   │   ├── sources.py         download + harmonise 5 label schemes
│   │   │   ├── prepare.py         inventory, dedup, splits
│   │   │   ├── preprocess.py      crop → square → CLAHE → Ben Graham
│   │   │   └── dataset.py         masked multi-task targets, augmentation
│   │   ├── models/model.py        shared encoder + 3 heads, EMA
│   │   ├── train/                 masked losses, CORAL ordinal, trainer
│   │   ├── eval/                  screening metrics, bootstrap CIs, calibration
│   │   ├── explain/gradcam.py     Grad-CAM + quantitative validation
│   │   └── export/                quantisation, LiteRT export, app metadata
│   ├── scripts/
│   │   ├── conversion_smoke_test.py
│   │   └── final_evaluation.py
│   └── notebooks/phase1_pipeline.ipynb
│
├── app/                           Phase 2 — Flutter application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/               capture, results, explanation, history
│   │   ├── services/              inference, preprocessing, quality gate
│   │   ├── models/                prediction result types
│   │   └── widgets/               confidence bars, heatmap overlay
│   └── assets/models/             .tflite + model_metadata.json
│
├── docs/                          stage documents, screenshots
└── DATA_LICENSES.md
```

<!-- Adjust to match your actual layout. -->

## Getting started

### Running the app

```bash
cd app
flutter pub get
flutter run
```

Requires a fundus lens adapter to capture usable images. A demo mode with sample images is
available for evaluation without hardware.

<!-- Delete the demo-mode line if you didn't build one. -->

### Reproducing the model

```bash
cd ml
pip install -r requirements.txt
```

Then open `notebooks/phase1_pipeline.ipynb`. Run it in order — each stage checkpoints, so a
disconnected session resumes rather than restarting.

Two things worth knowing before you start:

- **Run the conversion smoke test first.** It converts untrained architectures to LiteRT to
  verify they export at all. The PyTorch converter has partial operator coverage, and a
  backbone that trains well but cannot export is worthless here.
- **Data preparation needs no GPU.** Run those stages on a CPU runtime.

## Datasets

| Dataset | Role | Contribution |
|---|---|---|
| RFMiD | Training | Multi-disease labels, adjudicated specialist consensus, 3 cameras |
| APTOS 2019 | Training | DR severity grades, Indian screening population |
| ODIR-5K | Training | Broad disease categories, Chinese population, both eyes per patient |
| Messidor-2 | **External test only** | European cameras, standard published benchmark |
| IDRiD | **External test only** | DR grades **plus pixel-level lesion masks** for XAI validation |

**No dataset images are committed to this repository.** APTOS is governed by Kaggle
competition rules permitting non-commercial academic and educational use only, with
redistribution prohibited. Messidor-2 carries a custom research licence that prohibits
redistribution and unauthorised commercial use. Download scripts fetch from official
sources. See [`DATA_LICENSES.md`](DATA_LICENSES.md).

## Known limitations

Stated plainly, because a portfolio project that hides its constraints is less credible than
one that names them:

- **Full EyePACS (~88k images) was not used** — infeasible on the available compute. The DR
  grading head trains on a smaller dataset than the literature standard.
- **No transformer or hybrid backbone is deployed**, though published benchmarks indicate
  Swin and hybrid architectures lead on this task. This is a compute constraint.
- **ODIR labels are patient-level and keyword-derived**, which sets a label-noise floor —
  a diagnosis attached to a patient is applied to both eyes even when only one is affected.
- **Optic disc cupping is used as a proxy for glaucoma** when harmonising RFMiD and ODIR
  label schemes. This is an imperfect mapping and a known source of noise.
- **Rare conditions perform poorly.** Conditions with few positive examples are reported
  honestly rather than excluded to make the averages look better.
- **Trained on fundus-camera images, deployed on smartphone-adapter captures.** The
  literature shows this transfer is viable but degrades, and narrower fields of view
  degrade it further. Not independently validated here.
- **No prospective clinical validation.** Retrospective public datasets only.

## Roadmap

- [ ] Prospective validation on real smartphone-adapter captures
- [ ] Test-time augmentation for improved calibration
- [ ] Knowledge distillation from a retinal foundation model teacher
- [ ] iOS support
- [ ] Multi-language UI

<!-- Trim to what you actually intend to do. An honest short list beats a long aspirational one. -->

## References

1. Gulshan V. et al. Development and validation of a deep learning algorithm for detection
   of diabetic retinopathy in retinal fundus photographs. *JAMA*, 2016.
2. Graham B. Kaggle Diabetic Retinopathy Detection competition report, 2015.
3. Zhou Y., Alexander D.C., Keane P.A. et al. A foundation model for generalizable disease
   detection from retinal images. *Nature*, 2023.
4. Pachade S. et al. RFMiD: Retinal Fundus Multi-disease Image Dataset. RIADD challenge,
   ISBI 2021.
5. Decencière E. et al. Feedback on a publicly distributed image database: the Messidor
   database. 2014.
6. Porwal P. et al. IDRiD: Indian Diabetic Retinopathy Image Dataset.
7. Ridnik T. et al. Asymmetric Loss for Multi-Label Classification. ICCV, 2021.
8. Cao W., Mirjalili V., Raschka S. Rank consistent ordinal regression for neural networks.
   *Pattern Recognition Letters*, 2020.

## Licence

Code released under the MIT Licence — see [`LICENSE`](LICENSE).

Dataset licences are separate and more restrictive; see
[`DATA_LICENSES.md`](DATA_LICENSES.md). This project is non-commercial research and
educational work.

## Author

**Ezat** — [xvisionstudios.com](https://xvisionstudios.com)

<!-- Add GitHub / LinkedIn links. -->
