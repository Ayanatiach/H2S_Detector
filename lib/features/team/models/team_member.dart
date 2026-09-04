import 'package:flutter/material.dart';
import '../../../models/exposure_status.dart';
import '../../../core/theme/kinetic_colors.dart';

/// Representation of an on-site industrial worker and their live dosimeter badge.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.badgeId,
    required this.name,
    required this.initials,
    required this.role,
    required this.zoneName,
    required this.currentPpm,
    required this.shiftDosePpmH,
    required this.status,
    required this.avatarColor,
  });

  final String id;
  final String badgeId;
  final String name;
  final String initials;
  final String role;
  final String zoneName;
  final double currentPpm;
  final double shiftDosePpmH;
  final ExposureStatus status;
  final Color avatarColor;

  Color get statusColor {
    switch (status) {
      case ExposureStatus.safe:
        return KineticColors.emeraldSafe;
      case ExposureStatus.warning:
        return KineticColors.amber;
      case ExposureStatus.critical:
        return KineticColors.dangerRed;
    }
  }

  String get statusLabel {
    switch (status) {
      case ExposureStatus.safe:
        return 'SAFE';
      case ExposureStatus.warning:
        return 'WARN';
      case ExposureStatus.critical:
        return 'ELEVATED';
    }
  }
}
