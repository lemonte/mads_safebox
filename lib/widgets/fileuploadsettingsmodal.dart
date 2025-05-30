import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mads_safebox/services/category_service.dart';
import 'package:mads_safebox/widgets/loading.dart';

import '../models/category.dart';
import '../services/file_service.dart';
import 'category/category_create_modal.dart';
import 'category/category_dropdownbutton.dart';
import 'custom_snack_bar.dart';

class FileUploadSettingsModal extends StatefulWidget {
  final List<File> selectedFiles;
  const FileUploadSettingsModal({super.key, required this.selectedFiles});

  @override
  State<FileUploadSettingsModal> createState() =>
      _FileUploadSettingsModalState();
}

class _FileUploadSettingsModalState extends State<FileUploadSettingsModal> {
  final int defaultCategoryID = 1; // Default category ID if none is selected
  CategoryService categoryService = CategoryService();
  FileService fileService = FileService();
  DateTime? expiringDate;
  bool isUploading = false;
  late Future<List<CategorySB>> categories;

  CategorySB? selectedCategory;

  @override
  void initState() {
    super.initState();
    categories = categoryService.getCategories();
  }

  Future<void> uploadFiles() async {
    if (widget.selectedFiles.isNotEmpty && !isUploading) {
      setState(() {
        isUploading = true;
      });

      try {
        await fileService.uploadFile(
            widget.selectedFiles, selectedCategory?.id ?? defaultCategoryID, expiringDate);

        if (!mounted) return;
        showCustomSnackBar(context, "Files uploaded successfully");
        Navigator.pop(context);

      } catch (e) {
        debugPrint("Error uploading file: $e");
        showCustomSnackBar(context, "Error uploading file: $e");

      }
      Navigator.pop(context);
      setState(() {
        isUploading = false;
      });
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Category Dropdown
          buildCategoryDropdown(
            categoriesFuture: categories,
            selectedCategory: selectedCategory,
            onChanged: (CategorySB? value) {
              setState(() {
                selectedCategory = value;
              });
            },
          ),

            // Create new category button
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () async {
                  List<CategorySB> catValue = await categories;
                  if (!mounted) return;
                  _showCreateCategoryDialog(catValue);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "Create new Category",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text('Expiring Date'),
            const SizedBox(height: 4),

            // Date Picker
            GestureDetector(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: expiringDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    expiringDate = pickedDate;
                  });
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      expiringDate != null
                          ? DateFormat('dd/MM/yyyy').format(expiringDate!)
                          : 'dd/mm/yyyy',
                      style: TextStyle(
                        color:
                            expiringDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                isUploading
                    ? const Loading()
                    : ElevatedButton(
                        onPressed: () async {
                          await uploadFiles();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(80, 36),
                        ),
                        child: const Text('Upload'),
                      ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(80, 36),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCategoryDialog(List<CategorySB> catValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CategoryCreateModal(categories: catValue);
      },
    ).then((value) async {
      if (value != null) {
        (await categories).add(value);
        selectedCategory = (await categories).last;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

}
