# Exaroton iOS App UI/UX Guidelines

This document details the specific styling and design language ("Liquid Glass") used across the application. Any new SwiftUI views introduced into the project must conform to these paradigms.

## The "Liquid Glass" Paradigm

To achieve the premium look mentioned in the project spec, the app relies heavily on layered materials and subtle gradients rather than flat colors. 

### 1. The `GlassCard` Component
Do **NOT** use standard `RoundedRectangle().fill(.gray)` or flat white backgrounds for cards. 
Always wrap grouped content inside a `GlassCard`:
```swift
GlassCard(cornerRadius: 20, padding: 16) {
    // Your content here
}
```
The `GlassCard` handles the `.ultraThinMaterial` background, specular top-highlights, and inner-depth shadows automatically.

### 2. Interactive Elements (Buttons)
Buttons should feel tactile. Always apply the `.buttonStyle(GlassButtonStyle())` to custom buttons. This provides a subtle scale-down and opacity-dimming spring animation when the user presses them, keeping interactions feeling alive and responsive.

### 3. Loading States (Shimmer)
Do not use standard `ProgressView()` spinners inside cards or inline rows if data is loading. Instead, use the custom `.shimmer()` modifier on a placeholder shape:
```swift
RoundedRectangle(cornerRadius: 8)
    .fill(Color.white.opacity(0.1))
    .frame(height: 20)
    .shimmer() // Applies the sweeping gradient animation
```

### 4. Color Palette
Avoid hardcoded generic colors (e.g., `Color.red`). 
When conveying status, use the established gauge color tones (as seen in `AnimatedGauge.swift`):
- **Healthy / Good (0-60%):** `Color(red: 0.2, green: 0.85, blue: 0.45)`
- **Warning / Medium (60-80%):** `Color(red: 1.0, green: 0.75, blue: 0.2)`
- **Danger / High (80%+):** `Color(red: 1.0, green: 0.3, blue: 0.3)`

Always use dark-mode friendly opacities (e.g. `Color.white.opacity(0.6)` for secondary text) rather than hardcoded `.gray`.

## Typography
Rely on Apple's standard system fonts, but utilize the `.rounded` design for data-heavy readouts (like RAM percentages or TPS) to make numerals look friendlier and easier to read.
```swift
.font(.system(size: 24, weight: .bold, design: .rounded))
```
