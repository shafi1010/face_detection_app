import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class StatusIndicator extends StatelessWidget {
  final bool isActive;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const StatusIndicator({
    super.key,
    this.isActive = true,
    this.size = 10,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? (activeColor ?? AppTheme.online) : (inactiveColor ?? AppTheme.offline),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: (activeColor ?? AppTheme.online).withValues(alpha: 0.5),
                  blurRadius: size * 1.5,
                  spreadRadius: size * 0.3,
                ),
              ]
            : null,
      ),
    );
  }
}
