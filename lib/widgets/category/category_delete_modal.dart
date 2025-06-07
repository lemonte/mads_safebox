import 'package:flutter/material.dart';
import 'package:mads_safebox/services/file_service.dart';
import 'package:mads_safebox/widgets/loading.dart';

import '../../global/default_values.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../actionbuttonsrow.dart';
import '../custom_snack_bar.dart';
import 'category_dropdownbutton.dart';

class CategoryDeleteModal extends StatefulWidget {
  final Future<List<CategorySB>> categories;
  final int idCategoryToDelete;
  const CategoryDeleteModal(
      {super.key, required this.categories, required this.idCategoryToDelete});

  @override
  State<CategoryDeleteModal> createState() => _CategoryDeleteModalState();
}

class _CategoryDeleteModalState extends State<CategoryDeleteModal> {
  CategoryService categoryService = CategoryService();
  FileService fileService = FileService();
  CategorySB currentCategory = defaultCategory;
  TextEditingController textController = TextEditingController();
  String title = "Are you sure you want to delete this category?";
  bool isDeleting = false;

  void handleCategoryDeletionResult(dynamic response, dynamic responseFiles) {
    if(!mounted) return;
    if (response && responseFiles) {
      Navigator.of(context).pop(response);
      showCustomSnackBar(context, "Category deleted");
      return;
    } else {
      Navigator.of(context).pop();
      showCustomSnackBar(
          context, "An error occurred when deleting the category");
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
        child: buildDialogBody(),
      ),
    );
  }

  Column buildDialogBody() {
    if (isDeleting) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Loading(),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "This category's files will be moved to:",
          style: TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        buildCategoryDropdown(
            categoriesFuture: widget.categories,
            selectedCategory: currentCategory,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  currentCategory = value;
                });
              }
            }),
        const SizedBox(height: 8),
        ActionButtonsRow(
          confirmText: 'Delete Category',
          onConfirm: () async {
            setState(() {
              title = "Moving Files";
              isDeleting = true;
            });
            final responseFiles = await fileService.changeFilesCategory(
                widget.idCategoryToDelete, currentCategory.id);
            final response = await categoryService
                .deleteCategory(widget.idCategoryToDelete);
            if(mounted) {
              handleCategoryDeletionResult(response, responseFiles);
            }
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
