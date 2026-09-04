---
name: Kinetic Hazard Protocol
colors:
  surface: '#131315'
  surface-dim: '#131315'
  surface-bright: '#39393b'
  surface-container-lowest: '#0e0e10'
  surface-container-low: '#1c1b1d'
  surface-container: '#201f21'
  surface-container-high: '#2a2a2c'
  surface-container-highest: '#353437'
  on-surface: '#e5e1e4'
  on-surface-variant: '#e5beb2'
  inverse-surface: '#e5e1e4'
  inverse-on-surface: '#313032'
  outline: '#ac897e'
  outline-variant: '#5c4037'
  surface-tint: '#ffb59c'
  primary: '#ffb59c'
  on-primary: '#5c1900'
  primary-container: '#ff5708'
  on-primary-container: '#511500'
  inverse-primary: '#aa3600'
  secondary: '#d3fbff'
  on-secondary: '#00363a'
  secondary-container: '#00eefc'
  on-secondary-container: '#00686f'
  tertiary: '#dec800'
  on-tertiary: '#373100'
  tertiary-container: '#bfac00'
  on-tertiary-container: '#484000'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdbcf'
  primary-fixed-dim: '#ffb59c'
  on-primary-fixed: '#390c00'
  on-primary-fixed-variant: '#822700'
  secondary-fixed: '#7df4ff'
  secondary-fixed-dim: '#00dbe9'
  on-secondary-fixed: '#002022'
  on-secondary-fixed-variant: '#004f54'
  tertiary-fixed: '#fde400'
  tertiary-fixed-dim: '#dec800'
  on-tertiary-fixed: '#201c00'
  on-tertiary-fixed-variant: '#504700'
  background: '#131315'
  on-background: '#e5e1e4'
  surface-variant: '#353437'
typography:
  display-hero:
    fontFamily: barlowCondensed
    fontSize: 96px
    fontWeight: '900'
    lineHeight: 90px
    letterSpacing: -0.02em
  display-hero-mobile:
    fontFamily: barlowCondensed
    fontSize: 64px
    fontWeight: '900'
    lineHeight: 60px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: barlowCondensed
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: barlowCondensed
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: barlowCondensed
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 30px
    letterSpacing: 0.02em
  headline-sm:
    fontFamily: barlowCondensed
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 22px
    letterSpacing: 0.04em
  metric-readout:
    fontFamily: barlowCondensed
    fontSize: 72px
    fontWeight: '900'
    lineHeight: 68px
    letterSpacing: -0.01em
  metric-readout-mobile:
    fontFamily: barlowCondensed
    fontSize: 48px
    fontWeight: '900'
    lineHeight: 46px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: inter
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-telemetry:
    fontFamily: jetbrainsMono
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.08em
  label-pill:
    fontFamily: barlowCondensed
    fontSize: 13px
    fontWeight: '800'
    lineHeight: 14px
    letterSpacing: 0.06em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  space-2xs: 0.125rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-base: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
  space-3xl: 4rem
  layout-margin-mobile: 1rem
  layout-margin-tablet: 1.5rem
  layout-margin-desktop: 2.5rem
  grid-gutter: 1rem
---

## Brand & Style

This design system translates the high-velocity, adrenaline-fueled aesthetic of elite athletic tracking into mission-critical industrial hazard and dosimeter monitoring. The personality is hyper-vigilant, authoritative, and visceral—treating radiation, chemical, and environmental exposure not as passive data points, but as active performance metrics to be managed with relentless precision.

The visual style unites **High-Contrast Bold Athletic Expression** with **Technical Tactical Telemetry**. It deploys aggressive kinetic typography, massive condensed readouts, and high-visibility safety neon accents against deep void backgrounds. The emotional tone delivers urgency, absolute clarity under extreme physical conditions, and empowering confidence for operators navigating hazardous environments.

## Colors

The palette operates in high-contrast dark mode to conserve battery life on rugged field devices, prevent night blindness, and ensure absolute legibility under direct sunlight or zero-light containment scenarios.

- **Primary (`#FF5500` / `#FF6600`)**: Blaze Velocity Orange. Used for critical thresholds, active tracking states, primary CTAs, and peak dosimeter spikes.
- **Secondary (`#00F0FF`)**: Ion Electric Cyan. Represents active sensor links, baseline ambient sweeps, tactical telemetry overlays, and stable dosimeter readings.
- **Tertiary (`#FFE600`)**: Radiation Caution Yellow. Reserved exclusively for Tier-2 hazard warnings, time-to-limit countdowns, and advisory state flags.
- **Neutral Deep (`#0A0A0C`)**: Midnight Black. Ground surface for the canvas, absorbing light and driving maximum visual punch.
- **Surface Elevation Slates**: `#141418` (Surface Container Low), `#1E1E24` (Surface Container Mid), and `#2B2B36` (Surface High / Borders).
- **Text & Accents**: `#FFFFFF` (Peak Optical White) for high-impact condensed metrics; `#8E8E9F` for secondary telemetry labels.

## Typography

Typography establishes athletic momentum and field legibility. 

- **Display & Headlines**: Driven by `barlowCondensed` set in heavy weights (800–900) with a signature 8-to-12 degree forward italic slant for real-time velocity metrics. Headlines must default to `uppercase` with tight tracking.
- **Body & Data Descriptive**: Handled cleanly by `inter` for multi-line instructions, checklist items, and post-shift logs to balance condensed tension with neutral clarity.
- **Telemetry & Dosimetry Readouts**: Handled by `jetbrainsMono` for raw units (e.g., `mSv/h`, `RAD/m`, sensor IDs, and GPS coordinates), ensuring strict numerical alignment across shifting dynamic values.

## Layout & Spacing

The layout is built upon a rigid, fluid 4-column (mobile), 8-column (tablet), and 12-column (desktop) modular grid with an underlying 4px base rhythm. Spacing around performance metrics is intentionally compressed vertically to create visual mass, while horizontal whitespace isolates live dosimeter feeds from peripheral diagnostics.

- **Mobile (<768px)**: Edge-to-edge full-bleed metric containers. 16px lateral safety margins, with pinned action zones (e.g., floating trigger buttons and bottom nav).
- **Tablet (768px - 1024px)**: Split viewport balancing a tactical map zone (60% width) with a persistent real-time telemetric HUD panel (40% width).
- **Desktop (>1024px)**: Multi-column operations console featuring pinned spatial zone maps, operator roster telemetry streams, and live radiation dose trajectory curves.

## Elevation & Depth

Depth is defined through sharp tonal contrasts, luminescent neon edge borders, and dark ambient layering rather than traditional soft drop shadows.

- **Base Layer (`#0A0A0C`)**: Void space holding tactical gridlines, map imagery, and vector vector paths.
- **Tier 1 (Surface Mid - `#141418`)**: Primary card panels and list rows featuring a 1px crisp outline (`#2B2B36`).
- **Tier 2 (Floating Pills & Hazard Badges)**: Cast a directional 0px 8px 24px glow tinted by the active hazard state (e.g., `#FF5500` with 25% opacity for critical spikes; `#00F0FF` with 20% opacity for tactical beacons).
- **Tactical Map Overlays**: Semi-transparent midnight panels with high-contrast vector grid rasters (40% opacity) floating directly over satellite and floorplan imagery.

## Shapes

The interface blends athletic aerodynamic pill geometries with hyper-technical chamfered micro-accents. 

- Primary interactive chips, status badges, and trigger buttons use complete pill curvature (1000px radius) to reflect performance athletic hardware and wearable trackers.
- Content card containers balance this fluidity with structured `0.75rem` (12px) radii, retaining an industrial tactical silhouette without feeling sterile.

## Components

### Buttons
- **Primary Athletic Trigger**: Full-pill container, vibrant Blaze Orange (`#FF5500`) fill with optical white, bold condensed uppercase text (`barlowCondensed`, 900 weight, italic). On press, it scales down smoothly (`scale(0.97)`).
- **Secondary Ghost Action**: Pill shape with a 1.5px high-visibility slate or cyan border, completely transparent fill, and monospaced tracking label.

### Hazard Badges & Floating Pills
- **Radiation/Bio-Hazard Badges**: High-visibility pill capsules displaying current status (e.g., `CRITICAL EXPOSURE 12.4 mSv/h`). Features a pulsing 6px neon indicator dot paired with uppercase italic typography.
- **Pill Context Badges**: Floating floating chips anchored at screen tops or over tactical maps, indicating real-time zones (`SECTOR 04 - CORE`) with semi-translucent midnight backdrops.

### Cards & Telemetry Containers
- Built on `#141418` with 1px `#2B2B36` borders. 
- Headers feature a two-part split: left-aligned micro-monospace label (`DOSIMETER 01 // BETA-GAMMA`) and right-aligned numeric live trend delta.
- Inner readouts display massive numbers (`metric-readout`) directly adjoining monospaced unit identifiers.

### Tactical Map Overlays
- Layered over muted, desaturated industrial geospatial schematics.
- Uses high-contrast Neon Orange hazard cones, Cyan operator tracking vectors, and circular pill-based zone labels with hairline crosshairs.

### Input Fields & Controls
- Low-profile dark slate surfaces (`#1E1E24`) accented with high-contrast bottom underline boundaries that illuminate in `#00F0FF` or `#FF5500` upon focus. Monospaced numeric entry with integrated unit suffixes.

### Athletic Bottom Tab Bar
- Pinned midnight-black docking bar with subtle top divider (`#2B2B36`).
- Features thick-stroke, dynamic athletic-inspired icons (Pulse/Wave, Vector Map, Dosimeter Dial, Operator Shield).
- Active state highlights the icon with blaze orange and illuminates a concentrated 4px neon pill dash directly underneath.