import 'package:flutter/material.dart';
import 'package:mads_safebox/models/category.dart';
import 'package:mads_safebox/services/category_service.dart';

import '../actionbuttonsrow.dart';
import '../custom_snack_bar.dart';

class CategoryCreateModal extends StatefulWidget {
  final List<CategorySB> categories;
  const CategoryCreateModal({super.key, required this.categories});

  @override
  State<CategoryCreateModal> createState() => _CategoryCreateModalState();
}

class _CategoryCreateModalState extends State<CategoryCreateModal> {
  CategoryService categoryService = CategoryService();
  TextEditingController textController = TextEditingController();
  String infoText = "";

  void handleCategoryCreationResult(dynamic response) {
    if (response != null) {
      Navigator.of(context).pop(response);
      showCustomSnackBar(context, "Category created");
    } else {
      Navigator.of(context).pop();
      showCustomSnackBar(context, "An error occurred when creating the category");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Write a unique category name",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: textController,
            ),
            const SizedBox(height: 8),
            infoText.isNotEmpty
                ? Text(
                    infoText,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  )
                : Container(),
            ActionButtonsRow(
              confirmText: 'Create Category',
              onConfirm: () async {
                String name = textController.text.trim();
                if (name.isEmpty) {
                  setState(() {
                    infoText = "The name cannot be empty.";
                  });
                  return;
                }

                for (int i = 0; i < widget.categories.length; i++) {
                  if (name == widget.categories[i].name) {
                    setState(() {
                      infoText =
                      "You already have a category with that name.";
                    });
                    return;
                  }
                }

                final response = await categoryService.createCategory(name);

                if (!mounted) return;
                handleCategoryCreationResult(response);
              },
              onCancel: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
