# H₂S Detector

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.0-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.13.0-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-success?style=for-the-badge" />
  <img src="https://img.shields.io/badge/SIH%202026-Problem%20SIH26118-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" />
</p>

<p align="center">
  <strong>AI-based quantitative colorimetric dosimeter reader for industrial H₂S safety monitoring.</strong><br/>
  A Smart India Hackathon 2026 solution for problem statement <strong>SIH26118</strong>, sponsored by <strong>Mangalore Refinery and Petrochemicals Limited (MRPL)</strong>.
</p>

---

## Table of Contents

- [Problem Statement — SIH26118](#problem-statement--sih26118)
- [Our Solution](#our-solution)
- [How It Works](#how-it-works)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [OSHA Compliance](#osha-compliance)
- [Project Structure](#project-structure)
- [Running Tests](#running-tests)

---

## Problem Statement — SIH26118

**Title:** Passive Colorimetric H₂S Exposure-Dosimeter Wristband with AI-Based Quantitative Reading

**Sponsored by:** Mangalore Refinery and Petrochemicals Limited (MRPL)

**Track:** Hardware · **Theme:** Miscellaneous

### Background

Hydrogen Sulfide (H₂S) is an extremely hazardous gas encountered in petroleum refineries, sewage treatment plants, paper mills, and natural gas operations. It is colourless, heavier than air, and carries a distinctive smell of rotten eggs at low concentrations — but critically, **it paralyses the olfactory nerve at concentrations above ~100 ppm**, meaning workers can no longer smell it just when it becomes most dangerous.

MRPL workers are exposed to H₂S during routine operations, maintenance, and emergency situations. Conventional active gas detectors are:

- Expensive (require battery replacement, calibration services, and periodic certification)
- Bulky (not comfortable for continuous wear across an 8–12 hour shift)
- Single-point (measure instantaneous concentration, not cumulative dosage)

### The Challenge

Design a **passive wearable wristband** incorporating a colorimetric H₂S dosimeter strip — a chemically treated paper that permanently darkens in proportion to cumulative H₂S dose — and pair it with a **smartphone application** that:

1. Photographs the dosimeter strip through the device camera
2. Quantitatively interprets the colour change using computer vision
3. Maps the measured colour shift to an estimated H₂S exposure in **parts per million (ppm)**
4. Classifies the result against OSHA 29 CFR 1910.1000 permissible exposure limits
5. Logs readings with timestamps to a cloud backend for safety officer review
6. Operates reliably in offline / intermittent-connectivity field environments

### Why It Is Hard

The problem is classified **"high risk, high reward"** by SIH evaluators because it requires:

- **Chemical domain expertise** — the dosimeter formulation must react reproducibly to H₂S within the 1–50 ppm range of interest and resist interference from humidity, temperature, and other gases.
- **Photometric precision** — colour readings are highly sensitive to ambient lighting, camera white balance, and strip angle. A naïve approach produces wildly inconsistent readings.
- **Calibration mathematics** — a pixel-accurate colour space conversion (sRGB → CIE XYZ → CIELAB) followed by a perceptually-uniform distance metric (ΔE*) is required to produce stable, reproducible results across different smartphones and lighting conditions.
- **Regulatory mapping** — the estimated ppm must be traceable to OSHA ceiling limits and communicated clearly to non-technical workers.

---

## Our Solution

The **H₂S Detector** app is the mobile software half of the SIH26118 system. It is built in **Flutter** for cross-platform deployment (Android and iOS) and implements a full colorimetric analysis pipeline entirely on-device — no GPU server or external AI API is needed.

### Key Design Decisions

| Decision | Rationale |
|---|---|
| **CIELAB colour space** | Perceptually uniform — equal ΔE values correspond to equal perceived colour differences, independent of hue. Critical for accurate ppm mapping. |
| **CIE76 ΔE metric** | Standard, well-understood, computationally cheap. Provides sufficient accuracy for ppm ranges of interest without CIEDE2000 complexity. |
| **Centred ROI crop** | Eliminates edge artefacts and background contamination from the strip holder. Only the reaction zone is sampled. |
| **BT.601 luminance check** | Detects insufficient ambient lighting before capture, preventing systematic low-light errors. |
| **Offline-first sync** | Supabase writes are queued locally (SharedPreferences JSON) when offline and flushed when connectivity is restored. No readings are ever lost. |
| **Worker ID isolation** | Each device generates a persistent UUID identifying the worker. Readings are tagged so safety officers can filter by individual. |

---

## How It Works

### End-to-End Pipeline

```
Worker wears dosimeter wristband during shift
           │
           ▼
Worker opens H₂S Detector app (any time during shift)
           │
           ▼
┌──────────────────────────────────────────────┐
│            DOSIMETER SCANNER                 │
│                                              │
│  Camera preview ──► Lighting check (BT.601)  │
│                           │                  │
│              Low light? ──► Warning banner    │
│                           │                  │
│              OK ──► Worker taps CAPTURE       │
└──────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────┐
│            VISION PIPELINE (on-device)       │
│                                              │
│  1. Capture JPEG frame from rear camera      │
│  2. Crop central 35×35% ROI                  │
│  3. Average all pixel R, G, B channels       │
│  4. Convert sRGB → XYZ → CIELAB (D65)        │
│  5. Compute ΔE*₇₆ vs. calibrated baseline    │
│  6. Map ΔE → estimated ppm (calibration curve)│
│  7. Classify ppm vs. OSHA limits             │
└──────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────┐
│            SCAN RESULT SCREEN                │
│                                              │
│  • Status badge: SAFE / ELEVATED / DANGER    │
│  • ΔE gauge (0 – 30 scale)                   │
│  • Estimated ppm                             │
│  • CIELAB (L*, a*, b*) raw values            │
│  • OSHA regulatory note                      │
│  • SAVE or DISCARD                           │
└──────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────┐
│            SYNC ENGINE                       │
│                                              │
│  Online  ──► Upload to Supabase immediately  │
│  Offline ──► Enqueue locally (JSON queue)    │
│  Reconnect ──► Auto-flush queue to Supabase  │
└──────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────┐
│            SAFETY DASHBOARD                  │
│                                              │
│  • Latest reading status card                │
│  • Shift exposure timeline chart             │
│  • Full reading history list                 │
│  • Sync status indicator                     │
└──────────────────────────────────────────────┘
```

### The Colour Science in Detail

#### Step 1 — Region of Interest (ROI) Extraction

The camera frame is cropped to a centred **35% × 35%** rectangle. This ensures only the coloured reaction zone of the dosimeter strip contributes to the measurement — not the white strip border, wristband, or background.

#### Step 2 — Colour Space Conversion (sRGB → CIELAB)

Raw camera pixels are in sRGB, which is a non-linear, device-dependent colour space. To get a perceptually uniform measurement:

1. **Linearise sRGB** — reverse the gamma curve: if C ≤ 0.04045 then `C/12.92`, else `((C+0.055)/1.055)^2.4`
2. **Convert to CIE XYZ** — multiply by the sRGB-to-XYZ matrix (D65 illuminant)
3. **Convert XYZ to CIELAB** — using the CIE standard cube-root approximation with D65 white point (X_n=95.047, Y_n=100.000, Z_n=108.883)

#### Step 3 — ΔE Calculation (CIE76)

The Euclidean colour difference from the unexposed baseline is computed as:

```
ΔE*₇₆ = √[ (L*_scan − L*_baseline)² + (a*_scan − a*_baseline)² + (b*_scan − b*_baseline)² ]
```

The **baseline** is either the factory default (L\*=95, a\*=0, b\*=5) or a user-calibrated scan of a fresh unexposed strip.

#### Step 4 — ppm Estimation (Calibration Curve)

A piecewise-linear mapping translates ΔE to estimated cumulative H₂S exposure:

| ΔE Range | ppm Range | Zone |
|---|---|---|
| 0 – 5 | 0 – 0.9 ppm | SAFE |
| 5 – 18 | 1 – 19 ppm | WARNING |
| 18 – 30 | 20 – 50 ppm | CRITICAL |

> **Note:** This calibration curve is a simplified linear model for demonstration. Production deployment requires an empirical polynomial fit derived from controlled H₂S exposure chamber experiments with the specific dosimeter formulation used.

---

## Features

### 📷 Dosimeter Scanner

The live camera scanner screen is the primary interface for taking readings.

- **Live camera preview** — Full-screen rear camera feed rendered at native resolution
- **Targeting reticle** — An animated overlay guides the worker to align the dosimeter strip within the measurement zone
- **Real-time lighting analysis** — Every preview frame is assessed for luminance using BT.601 perceptual weighting; if lighting is insufficient a `⚠ LOW LIGHT` banner appears to prevent inaccurate readings
- **One-tap capture** — A single "CAPTURE & ANALYZE" button triggers the entire vision pipeline
- **Haptic feedback** — Medium-intensity vibration confirms capture on supported devices
- **Calibration mode** — A secondary calibration flow allows scanning a clean (unexposed) dosimeter to set a device-specific baseline, correcting for camera colour temperature variations

### 📊 Scan Result Screen

Detailed breakdown of every individual reading immediately after capture.

- **Status badge** — Large, colour-coded badge displaying `SAFE`, `ELEVATED`, or `DANGER`
- **ΔE gauge** — Animated arc gauge showing the raw CIE76 colour difference on a 0–30 scale
- **Estimated ppm** — Translated exposure estimate in parts per million
- **CIELAB values** — Raw L\*, a\*, b\* values for quality assurance and advanced analysis
- **OSHA regulatory note** — Contextual compliance statement mapped to the specific exposure zone
- **Save or Discard** — Worker can review the result before committing it to the database

### 🛡️ Safety Dashboard

The home screen summarising the worker's exposure status for the current shift.

- **Status header card** — Prominent card showing the most recent reading's hazard level with colour-coded gradient (green/amber/red)
- **Shift exposure timeline** — Line chart plotting all ΔE readings across the current shift, allowing trends and sudden spikes to be identified at a glance
- **Reading history list** — Scrollable list of all readings with timestamps, ΔE values, and ppm estimates
- **Sync status indicator** — Live indicator showing whether readings are synced to the cloud, currently syncing, offline-queued, or sync-failed

### ☁️ Offline-First Cloud Sync

Designed for industrial environments where connectivity is unreliable.

- **Immediate upload** — When the device is online, a reading is pushed to Supabase (PostgreSQL) immediately after saving
- **Offline queue** — When offline, readings are serialised to a local JSON queue in SharedPreferences and never lost
- **Auto-flush** — When connectivity is restored, the queue is automatically drained and all pending readings are uploaded
- **Sync status transparency** — The dashboard always shows exactly how many readings are pending upload

### 🔧 Baseline Calibration

Accounts for real-world variability in camera hardware and ambient colour temperature.

- **Custom calibration scan** — Scan a fresh (unexposed) dosimeter strip to capture the true baseline colour for this specific device and lighting environment
- **Persistent calibration** — The calibrated baseline (L\*, a\*, b\*) is saved to device storage and survives app restarts
- **Default fallback** — If no calibration has been performed, the factory default (L\*=95, a\*=0, b\*=5) is used — appropriate for standard indoor industrial lighting conditions
- **Reset option** — Calibration can be reset to factory default at any time

### 👷 Worker Identification

- Each installation generates a **unique persistent UUID** for the worker on first launch
- All readings are tagged with this Worker ID in the database
- Enables per-worker exposure history tracking by safety officers through the Supabase dashboard

### 🔬 Standalone Color Science Engine (`CIELabEngine`)

In addition to the camera-integrated live vision pipeline, the codebase includes [`lib/core/vision/cielab_engine.dart`](lib/core/vision/cielab_engine.dart) — a self-contained, pure-Dart color science engine built without external UI or Flutter widget dependencies:

- **Direct Byte Stream Analysis** — Ingests raw `Uint8List` image bytes (JPEG / PNG) via `CIELabEngine.analyzeImage(bytes)`, automatically crops the central 50 × 50 px region of interest, extracts average sRGB channels, and computes the full exposure assessment.
- **IEC 61966-2-1:1999 Gamma Expansion** — Piecewise inverse gamma curve linearising sRGB non-linear channel values to linear-light intensities:
  $$u = \frac{C}{255}, \quad \text{linear} = \begin{cases} \frac{u}{12.92} & \text{if } u \le 0.04045 \\ \left(\frac{u + 0.055}{1.055}\right)^{2.4} & \text{if } u > 0.04045 \end{cases}$$
- **CIE Publication 15:2004 Colorimetry** — Rigorous linear RGB to CIE XYZ matrix conversion under the D65 standard illuminant ($X_n = 95.047, Y_n = 100.000, Z_n = 108.883$) and standard cube-root compression with $\epsilon = \left(\frac{6}{29}\right)^3 \approx 0.008856$ and $\kappa = \left(\frac{29}{3}\right)^3 \approx 903.3$.
- **ISO 11664-4 / CIE 76 Distance** — Computes Euclidean $\Delta E^*_{76}$ colour difference against the pure-white unexposed baseline ($L^* = 100, a^* = 0, b^* = 0$) or reference standards.
- **OSHA Hazard Classification** — Maps raw $\Delta E$ to standardized alert tiers: `SAFE` ($\Delta E < 5.0$), `WARNING` ($5.0 \le \Delta E < 18.0$), and `DANGER` ($\Delta E \ge 18.0$).
- **Direct Flutter Color Evaluation** — `calculateExposure(Color)` and `calculateExposureWithAlert(Color)` for instant colorimetry directly from Flutter `Color` values.
- **Modular Step-by-Step Helpers** — `srgbToLinear()`, `linearRgbToXyz()`, `xyzToLab()`, `deltaE76()`, and `extractRoiFromImage()` exposed for modular unit testing and independent validation.

---

## Tech Stack

| Component | Technology | Purpose |
|---|---|---|
| **UI Framework** | Flutter 3.47 / Dart 3.13 | Cross-platform mobile app (Android + iOS + Web) |
| **State Management** | flutter_riverpod ^2.5.1 | Reactive providers for camera, scan, sync, and baseline state |
| **Camera** | camera ^0.12.0 | Live preview, still capture, device enumeration |
| **Image Processing** | image ^4.2.0 | In-memory pixel manipulation, ROI cropping, channel averaging |
| **Cloud Backend** | supabase_flutter ^2.6.0 | PostgreSQL database, real-time sync, REST API |
| **Charting** | fl_chart ^0.69.0 | Shift exposure timeline line chart |
| **Typography** | google_fonts ^6.2.1 | JetBrains Mono + Inter industrial typefaces |
| **Offline Queue** | shared_preferences ^2.3.0 | Local JSON persistence of unsynced readings |
| **Network Detection** | connectivity_plus ^6.0.3 | Online/offline state monitoring for auto-sync |
| **Permissions** | permission_handler ^11.3.1 | Camera and storage permission requests |
| **Worker ID** | uuid ^4.0.0 | Persistent UUID generation for worker identification |

---

## Architecture

The app follows a **layered architecture** with clear separation of concerns:

```
lib/
├── main.dart                         # App entry point, Supabase init, orientation lock
├── app.dart                          # Root widget, OLED theme, MaterialApp
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart           # OLED-optimised colour palette
│   │   ├── app_strings.dart          # All user-facing strings, Supabase config keys
│   │   └── exposure_thresholds.dart  # ΔE thresholds, ppm calibration curve, OSHA limits
│   └── vision/
│       ├── cielab_engine.dart        # Standalone pure-Dart CIE-LAB & ΔE*₇₆ math engine
│       ├── color_extractor.dart      # ROI cropping, pixel averaging
│       ├── color_space_converter.dart # sRGB → XYZ → CIELAB conversion
│       ├── delta_e_calculator.dart   # CIE76 ΔE computation + ppm mapping
│       └── lighting_analyzer.dart    # BT.601 luminance / low-light detection
│
├── models/
│   ├── dosimeter_reading.dart        # Data model + JSON serialisation (Supabase schema)
│   └── exposure_status.dart          # OSHA zone enum (SAFE / WARNING / CRITICAL)
│
├── providers/
│   ├── camera_provider.dart          # Camera lifecycle (init, capture, release)
│   ├── scan_provider.dart            # Scan pipeline orchestration
│   ├── baseline_provider.dart        # Calibration baseline (persist + reset)
│   ├── readings_provider.dart        # Local readings list state
│   ├── sync_provider.dart            # Cloud sync, offline queue, connectivity
│   └── worker_provider.dart          # Worker UUID
│
├── features/
│   ├── dashboard/                    # Home screen, status card, chart, history
│   ├── scanner/                      # Camera UI, overlay reticle, scan result
│   └── sync/                         # Supabase service, offline queue service
│
└── widgets/                          # Shared: IndustrialButton, StatusBadge, ΔE gauge
```

---

## Getting Started

### Prerequisites

- Flutter SDK **3.47+** (`flutter --version`)
- Android Studio (for Android emulator) or Xcode (for iOS simulator)
- A [Supabase](https://supabase.com) project (free tier is sufficient)

### 1. Clone the repository

```bash
git clone https://github.com/Ayanatiach/H2S_Detector.git
cd H2S_Detector
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

Open `lib/core/constants/app_strings.dart` and replace the placeholder values:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

Create the readings table in your Supabase project using the SQL below:

```sql
create table dosimeter_logs (
  id            uuid primary key,
  worker_id     text not null,
  delta_e       numeric not null,
  estimated_ppm numeric not null,
  status        text not null,   -- 'safe' | 'warning' | 'critical'
  lab_l         numeric,
  lab_a         numeric,
  lab_b         numeric,
  created_at    timestamptz default now()
);

-- Enable Row Level Security (recommended for production)
alter table dosimeter_logs enable row level security;
```

### 4. Run the app

**Android emulator:**

```bash
flutter emulators --launch medium_phone   # start emulator
flutter run -d emulator-5554
```

**Physical Android device** (USB debugging enabled):

```bash
flutter run
```

**iOS Simulator:**

```bash
flutter emulators --launch apple_ios_simulator
flutter run -d iPhone
```

---

## Configuration

### Exposure Thresholds

Thresholds are defined in [`lib/core/constants/exposure_thresholds.dart`](lib/core/constants/exposure_thresholds.dart) and can be adjusted to match a different dosimeter formulation:

| Constant | Default | Meaning |
|---|---|---|
| `safeMaxDeltaE` | `5.0` | ΔE below this → SAFE (< 1 ppm) |
| `warningMaxDeltaE` | `18.0` | ΔE below this → WARNING (1–19 ppm) |
| `baselineL` | `95.0` | Default unexposed strip L\* value |
| `baselineA` | `0.0` | Default unexposed strip a\* value |
| `baselineB` | `5.0` | Default unexposed strip b\* value |
| `minAcceptableLuminance` | `60.0` | Minimum frame luminance for valid capture |

### ROI Fraction

Defined in [`lib/core/vision/color_extractor.dart`](lib/core/vision/color_extractor.dart):

```dart
static const double roiFraction = 0.35;  // 35% of width × 35% of height
```

Adjust this if the dosimeter reaction zone occupies a different proportion of the frame.

---

## OSHA Compliance

Exposure classifications are based on **OSHA 29 CFR 1910.1000 Table Z-2** limits for Hydrogen Sulfide:

| Zone | ΔE Range | Estimated ppm | OSHA Status |
|---|---|---|---|
| 🟢 **SAFE** | 0 – 5 | < 1 ppm | Within permissible limits |
| 🟡 **ELEVATED** | 5 – 18 | 1 – 19 ppm | Approaching OSHA ceiling — monitor closely |
| 🔴 **DANGER** | ≥ 18 | ≥ 20 ppm | **OSHA ceiling BREACHED — evacuate & report** |

> The OSHA ceiling limit for H₂S is **20 ppm** (maximum peak: 50 ppm for 10 minutes once per 8-hour shift, provided no other measurable exposure occurs).

---

## Project Structure

```
H2S Detector/
├── android/          # Android platform project
├── ios/              # iOS platform project
├── web/              # Web platform assets & manifest
├── lib/              # Dart source code (see Architecture above)
├── test/
│   ├── vision_engine_test.dart  # Unit tests: sRGB→CIELAB, ΔE, OSHA mapping
│   └── widget_test.dart         # Widget smoke test
├── pubspec.yaml      # Dependencies
└── README.md         # This file
```

---

## Running Tests

```bash
flutter test
```

The test suite covers:

- `sRGB → XYZ → CIELAB` colour space conversion and inverse gamma expansion
- `ΔE*₇₆` calculation accuracy and zero-delta baseline behaviour
- Monotonic ppm estimation across exposure thresholds
- OSHA status mapping across `SAFE`, `WARNING`, and `CRITICAL` / `DANGER` zones
- `DosimeterReading` JSON serialization / deserialization integrity for offline queuing
- Widget smoke test confirming the Riverpod state tree and dashboard render without crash

---

## Disclaimer

This application is a **research and demonstration prototype** developed for the Smart India Hackathon 2026. The ppm calibration curve is a simplified linear model and **must be replaced** with empirically validated data from controlled H₂S exposure chamber tests before use in any real industrial safety context. Always comply with your organisation's safety protocols and use certified instrumentation for life-safety decisions.

---

<p align="center">
  Built for <strong>Smart India Hackathon 2026</strong> · Problem Statement <strong>SIH26118</strong><br/>
  Sponsored by <strong>Mangalore Refinery and Petrochemicals Limited (MRPL)</strong>
</p>
