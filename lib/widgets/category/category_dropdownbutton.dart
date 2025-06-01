import 'package:flutter/material.dart';

import '../../models/category.dart';

Widget buildCategoryDropdown({
  required Future<List<CategorySB>> categoriesFuture,
  required CategorySB? selectedCategory,
  required ValueChanged<CategorySB?> onChanged,
}) {
  return FutureBuilder<List<CategorySB>>(
    future: categoriesFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Text("Loading your categories");
      }
      if (snapshot.hasError) {
        return const Text("Error occurred getting categories, showing all files.");
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Text("No categories found, showing all files.");
      }



      final categories = snapshot.data!;
      final currentCategory = selectedCategory ?? categories.first;


      return Flexible(
        fit: FlexFit.loose,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CategorySB>(
              isExpanded: true,
              value: currentCategory,
              hint: const Text('Category'),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: BorderRadius.circular(8),
              icon: const Icon(Icons.arrow_drop_down),
              items: categoryMenuItemBuilder(categories),
              onChanged: onChanged,
            ),
          ),
        ),
      );
    },
  );
}


List<DropdownMenuItem<CategorySB>> categoryMenuItemBuilder(
    List<CategorySB> categories) {
  List<DropdownMenuItem<CategorySB>> buttons = [];

  for (CategorySB cat in categories) {
    buttons.add(DropdownMenuItem(
      value: cat,
      child: Text(cat.name, overflow: TextOverflow.ellipsis,),
    ));
  }

  return buttons;
}