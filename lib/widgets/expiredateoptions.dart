import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../global/default_values.dart';

class ExpireDateOptions extends StatelessWidget {
  final bool noExpiration;
  final DateTime? expiringDate;
  final Duration? selectedDuration;
  final void Function(bool) onExpirationChanged;
  final void Function(Duration?) onDurationChanged;
  final void Function(DateTime) onDatePicked;

  final Map<String, Duration?> options = const {
    'No Notification': null,
    '1 Day Before': Duration(days: 1),
    '1 Week Before': Duration(days: 7),
    '1 Month Before': Duration(days: 31),
  };

  const ExpireDateOptions({
    super.key,
    required this.noExpiration,
    required this.expiringDate,
    required this.selectedDuration,
    required this.onExpirationChanged,
    required this.onDurationChanged,
    required this.onDatePicked,
  });

  void _handlePickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: expiringDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDatePicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Expiring Date'),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            if (!noExpiration) _handlePickDate(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  expiringDate != null
                      ? DateFormat(dateFormatToDisplay).format(expiringDate!)
                      : dateFormatToDisplay,
                  style: TextStyle(
                    color: expiringDate != null ? Colors.black : Colors.grey,
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
                if (value != null) onExpirationChanged(value);
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
              onChanged: onDurationChanged,
              items: options.entries
                  .map((entry) => DropdownMenuItem<Duration?>(
                value: entry.value,
                child: Text(entry.key),
              ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
