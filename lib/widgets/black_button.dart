import 'package:flutter/material.dart';

import '../shared/theme/dims.dart';
import '../shared/theme/typography.dart';

const double _borderRadius = 24;

class BlackButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;

  const BlackButton({required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius)),
      elevation: 0,
      onPressed: onTap,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: Dim.d24),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          text,
          style: AppTypography.extraBold24,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
