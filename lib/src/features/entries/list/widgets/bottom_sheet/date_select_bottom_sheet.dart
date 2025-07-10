import 'package:flutter/material.dart';

class DateSelectBottomSheet extends StatefulWidget {
  const DateSelectBottomSheet({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<DateSelectBottomSheet> createState() => _DateSelectBottomSheetState();
}

class _DateSelectBottomSheetState extends State<DateSelectBottomSheet> {
  late DateTime pickedDate;

  @override
  void initState() {
    setState(() {
      pickedDate = widget.initialDate;
    });
    super.initState();
  }

  void _cancel() {
    Navigator.of(context).pop(widget.initialDate);
  }

  void _saveDate() {
    Navigator.of(context).pop(pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      elevation: 2,
      onClosing: () {},
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: Text(
                "Select a date",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Divider(),
            CalendarDatePicker(
              initialCalendarMode: DatePickerMode.day,
              onDateChanged: (DateTime value) {
                setState(() {
                  pickedDate = value;
                });
              },
              initialDate: widget.initialDate,
              firstDate: DateTime.now().subtract(Duration(days: 365 * 125)),
              lastDate: DateTime.now(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _cancel, child: Text("Cancel")),
                const SizedBox(width: 16),
                FilledButton(onPressed: _saveDate, child: Text("Save")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
