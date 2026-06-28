import 'package:flutter/foundation.dart';

bool get firestickPerformanceMode =>
    defaultTargetPlatform == TargetPlatform.android;

Duration perfDuration(Duration normal) =>
    firestickPerformanceMode ? Duration.zero : normal;

double perfScale(double focusedScale) =>
    firestickPerformanceMode ? 1.0 : focusedScale;

double perfBlur(double normal) => firestickPerformanceMode ? 0.0 : normal;
