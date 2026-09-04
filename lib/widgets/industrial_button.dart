import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// Primary industrial-styled gradient button for H₂S Detector CTAs.
///
/// Features:
///   • Gradient background (accent or custom)
///   • Subtle border glow
///   • Animated press effect (scale + opacity)
///   • Optional leading icon
class IndustrialButton extends StatefulWidget {
  const IndustrialButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = AppColors.accentGradient,
    this.height = 56.0,
    this.width = double.infinity,
    this.isLoading = false,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LinearGradient gradient;
  final double height;
  final double width;
  final bool isLoading;
  final bool isDestructive;

  @override
  State<IndustrialButton> createState() => _IndustrialButtonState();
}

class _IndustrialButtonState extends State<IndustrialButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final gradient = widget.isDestructive
        ? const LinearGradient(
            colors: [Color(0xFFFF1744), Color(0xFFB71C1C)],
          )
        : widget.gradient;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            gradient: widget.onPressed != null
                ? gradient
                : const LinearGradient(
                    colors: [Color(0xFF2E3A54), Color(0xFF252D40)],
                  ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                      color: (widget.isDestructive
                              ? AppColors.critical
                              : AppColors.accent)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.jetBrainsMono(
                        color: widget.onPressed != null
                            ? Colors.white
                            : AppColors.textDisabled,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary outlined ghost button.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.textSecondary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18, color: color) : const SizedBox.shrink(),
      label: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
