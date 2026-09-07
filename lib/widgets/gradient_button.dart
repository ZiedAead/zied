import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final Color? solidColor;
  final double height;
  final double? width;
  final double borderRadius;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.solidColor,
    this.height = 52,
    this.width,
    this.borderRadius = 16,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = solidColor == null ? (gradient ?? AppColors.primaryGradient) : null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: solidColor,
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppColors.raisedShadow3D(
          color: solidColor ?? (gradient != null ? null : AppColors.primary),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
