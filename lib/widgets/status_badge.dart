import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exposure_status.dart';

/// Compact pill badge displaying an [ExposureStatus] label with its colour.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.large = false,
  });

  final ExposureStatus status;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 18.0 : 11.0;
    final horizontalPad = large ? 20.0 : 12.0;
    final verticalPad = large ? 10.0 : 5.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
          horizontal: horizontalPad, vertical: verticalPad),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        border: Border.all(color: status.color.withValues(alpha: 0.6), width: 1.5),
        borderRadius: BorderRadius.circular(large ? 12 : 30),
        boxShadow: [
          BoxShadow(
            color: status.color.withValues(alpha: 0.2),
            blurRadius: large ? 20 : 8,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: large ? 22 : 13),
          SizedBox(width: large ? 8 : 5),
          Text(
            status.label,
            style: GoogleFonts.jetBrainsMono(
              color: status.color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: large ? 2.5 : 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
