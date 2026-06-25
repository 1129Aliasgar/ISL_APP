import 'package:flutter/material.dart';
import 'package:g_one/utils/constants.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        AppConstants.logoAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            color: const Color(0xFF7B61FF),
            alignment: Alignment.center,
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.45,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
