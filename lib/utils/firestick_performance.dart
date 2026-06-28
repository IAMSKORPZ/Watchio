import 'package:flutter/foundation.dart';

const bool _firestickPerformanceOverride = bool.fromEnvironment(
  'WATCHIO_FIRESTICK_MODE',
);

bool get firestickPerformanceMode =>
    _firestickPerformanceOverride &&
    defaultTargetPlatform == TargetPlatform.android;

Duration perfDuration(Duration normal) =>
    firestickPerformanceMode ? Duration.zero : normal;

double perfScale(double focusedScale) =>
    firestickPerformanceMode ? 1.0 : focusedScale;

double perfBlur(double normal) => firestickPerformanceMode ? 0.0 : normal;
