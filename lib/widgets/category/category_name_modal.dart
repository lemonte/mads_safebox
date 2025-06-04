import 'package:flutter/material.dart';
import 'package:mads_safebox/models/category.dart';

import '../actionbuttonsrow.dart';
import '../custom_snack_bar.dart';

class CategoryNameModal extends StatefulWidget {
  final List<CategorySB> categories;
  final String title;
  final String confirmText;
  final Future<dynamic> Function(String name) onSubmit;
  final String? initialName;

  const CategoryNameModal({
    super.key,
    required this.categories,
    required this.title,
    required this.confirmText,
    required this.onSubmit,
    this.initialName,
  });

  @override
  State<CategoryNameModal> createState() => _CategoryNameModalState();
}

class _CategoryNameModalState extends State<CategoryNameModal> {
  final TextEditingController textController = TextEditingController();
  String infoText = "";

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) {
      textController.text = widget.initialName!;
    }
  }

  void handleSubmit(dynamic response, String name) {
    if (!mounted) return;
    if (response != null) {
      Navigator.of(context).pop(response is bool ? name : response);
      showCustomSnackBar(context, response is bool ? "Category renamed" : "Category created");
    } else {
      Navigator.of(context).pop();
      showCustomSnackBar(context, "An error occurred while saving the category");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(controller: textController),
            const SizedBox(height: 8),
            if (infoText.isNotEmpty)
              Text(infoText, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ActionButtonsRow(
              confirmText: widget.confirmText,
              onConfirm: () async {
                String name = textController.text.trim();
                if (name.isEmpty) {
                  setState(() => infoText = "The name cannot be empty.");
                  return;
                }

                if (widget.categories.any((cat) => cat.name == name)) {
                  setState(() => infoText = "You already have a category with that name.");
                  return;
                }

                final response = await widget.onSubmit(name);
                if (mounted) handleSubmit(response, name);
              },
              onCancel: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
