# Gait Analysis Pro

A comprehensive Flutter app for real-time gait analysis and health monitoring using device camera and machine learning.

## Features

### 🏃‍♂️ Real-time Gait Analysis
- **30-second camera scan** with live pose detection
- **Real-time feedback** with voice coaching and visual overlays
- **Instant posture corrections** during walking

### 📊 Comprehensive Analytics
- **Gait Health Score** (0-100) based on multiple parameters
- **Future Injury Heat Map** showing risk areas
- **Detailed gait metrics** including stride length, cadence, symmetry
- **Progress tracking** over time with charts

### 🎯 Key Metrics Analyzed
- Walking speed and cadence
- Stride length and step width
- Joint angles (knee, hip, ankle)
- Posture alignment
- Step symmetry and balance
- Stance/swing phase percentages

### 🎨 Modern UI/UX
- Beautiful gradient design with health-focused green theme
- Smooth animations and transitions
- Intuitive dashboard with quick actions
- Tabbed results view with detailed analysis

## Technical Stack

- **Flutter** - Cross-platform mobile development
- **Camera** - Real-time video capture
- **TensorFlow Lite** - Pose detection and ML models
- **Provider** - State management
- **Flutter Animate** - Smooth animations
- **FL Chart** - Data visualization
- **Flutter TTS** - Voice feedback

## Getting Started

1. **Prerequisites**
   - Flutter SDK (3.10.0+)
   - Android Studio / VS Code
   - Android device or emulator

2. **Installation**
   ```bash
   git clone <repository-url>
   cd startup
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Usage

1. **Landing Page** - View your overall health score and recent scans
2. **Run Scan** - Tap "Start Scan" and walk naturally for 30 seconds
3. **Real-time Feedback** - Get live posture corrections and coaching
4. **View Results** - Analyze your gait health score and injury risk areas
5. **Track Progress** - Monitor improvements over time

## App Flow

```
Landing Page (Dashboard)
    ↓
Scan Mode (Camera + Live Feedback)
    ↓
Analysis Results
    - Health Score
    - Injury Heat Map
    - Detailed Metrics
    - Recommendations
```

## Future Enhancements

- [ ] Advanced ML models for more accurate pose detection
- [ ] Cloud sync for data backup
- [ ] Social features and challenges
- [ ] Integration with fitness trackers
- [ ] Professional therapist dashboard
- [ ] Custom exercise recommendations

## Contributing

This is a startup project focused on gait analysis and health monitoring. Contributions are welcome!

## License

Private project - All rights reserved.
