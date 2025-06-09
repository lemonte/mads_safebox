import 'package:flutter/material.dart';

class ActionButtonsRow extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String confirmText;
  final String cancelText;
  final bool isLoading;
  final Color confirmColor;

  const ActionButtonsRow({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    required this.confirmText,
    this.cancelText = 'Cancel',
    this.confirmColor = Colors.green,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        isLoading
            ? const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
            : ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size(80, 36),
          ),
          child: Text(confirmText),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onCancel,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size(80, 36),
          ),
          child: Text(cancelText),
        ),
      ],
    );
  }
}
