import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Compact +/- stepper used on product cards and the cart.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 34.0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, onRemove, size),
          SizedBox(
            width: compact ? 24 : 30,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          _btn(Icons.add, onAdd, size),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, double size) => InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );
}
