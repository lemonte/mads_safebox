import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mads_safebox/models/file.dart';
import 'package:mads_safebox/services/file_service.dart';
import 'package:mads_safebox/widgets/custom_snack_bar.dart';

import '../global/default_values.dart';

class ExpireDateChangeModal extends StatefulWidget {
  final FileSB fileSB;
  const ExpireDateChangeModal({super.key, required this.fileSB});

  @override
  State<ExpireDateChangeModal> createState() => _ExpireDateChangeModalState();
}

class _ExpireDateChangeModalState extends State<ExpireDateChangeModal> {
  DateTime? expiringDate = DateTime.now().add(const Duration(days: 1));
  bool noExpiration = false;
  Duration? selectedDuration;

  final Map<String, Duration?> options = {
    'No Notification': null,
    '1 Day Before': const Duration(days: 1),
    '1 Week Before': const Duration(days: 7),
    '1 Month Before': const Duration(days: 31),
  };

  @override
  void initState() {
    super.initState();

    try {
      if (widget.fileSB.expireDate != null) {
        noExpiration = false;
        expiringDate = widget.fileSB.expireDate!;
        if (widget.fileSB.notificationDate != null) {
          debugPrint("Notification date initialized: ${DateFormat('dd/MM/yyyy').format(widget.fileSB.notificationDate!)}");
          debugPrint("Expire date initialized: ${DateFormat('dd/MM/yyyy').format(expiringDate!)}");
          final diff = widget.fileSB.expireDate!.difference(widget.fileSB.notificationDate!);
          selectedDuration = options.values.firstWhere(
                (d) => d == null ? diff.inSeconds == 0 : d.inDays == diff.inDays,
            orElse: () => null,
          );
          debugPrint("Expiring date initialized: $selectedDuration");
        }
      }
      else {
        expiringDate = null;
        noExpiration = true;
      }
    } on Exception catch (e) {
      debugPrint("Error initializing expiration date: $e");
    }
  }

  void handleExpireDateChangeResult(bool error) {
    if (!mounted) return;
    if (!error) {
      setState(() {
        widget.fileSB.expireDate = noExpiration ? null : expiringDate;
        widget.fileSB.notificationDate = !noExpiration && selectedDuration != null ? expiringDate!.subtract(selectedDuration!) : null;
      });
      showCustomSnackBar(context, noExpiration ? 'Expiration date removed' :
      'Expiration date changed to ${DateFormat('dd/MM/yyyy').format(expiringDate!)}');
      Navigator.of(context).pop();
      return;
    }
    showCustomSnackBar(context, 'An error occurred while changing the expiration date');
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Change Expiration Date",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Date Picker
            GestureDetector(
              onTap: () async {
                if (noExpiration) return;
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: expiringDate,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
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
                      noExpiration
                          ? 'dd/mm/yyyy'
                          : DateFormat('dd/MM/yyyy').format(expiringDate!),
                      style: const TextStyle(
                        color:
                        Colors.black,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                const Text('No Expiration:'),
                Checkbox(
                  value: noExpiration,
                  onChanged: (bool? value) {
                    setState(() {
                      noExpiration = value!;
                      if (noExpiration) {
                        expiringDate = null;
                      } else {
                        expiringDate = DateTime.now().add(const Duration(days: 1));
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Expiring File Notification'),

            IgnorePointer(
              ignoring: noExpiration,
              child: Opacity(
                opacity: noExpiration ? 0.5 : 1.0,
                child: DropdownButton<Duration?>(
                  value: selectedDuration,
                  onChanged: (Duration? newValue) {
                    setState(() {
                      selectedDuration = newValue;
                    });
                  },
                  items: options.entries.map((entry) {
                    return DropdownMenuItem<Duration?>(
                      value: entry.value,
                      child: Text(entry.key),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                FileService fileService = FileService();
                try {
                  DateTime? notificationDate = noExpiration ? null : expiringDate!.subtract(selectedDuration ?? Duration.zero);
                  await fileService.changeFileExpireDate(
                    widget.fileSB.id,
                    expiringDate,
                    selectedDuration != null ? notificationDate : null
                  );
                  handleExpireDateChangeResult(false);
                } on Exception catch (e) {
                  debugPrint("Error changing expiration date: $e");
                  handleExpireDateChangeResult(true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Change Date', style: TextStyle(color: mainTextColor),),
            ),
          ],
        ),
      ),
    );
  }
}
