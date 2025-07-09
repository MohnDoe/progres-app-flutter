import 'package:flutter/material.dart';
import 'package:progres/src/features/entries/list/widgets/entry_edition.dart';

class AddTodayButton extends StatefulWidget {
  const AddTodayButton({super.key});

  @override
  State<AddTodayButton> createState() => _AddTodayButtonState();
}

class _AddTodayButtonState extends State<AddTodayButton> {
  late Widget animatedWidget;
  bool isButton = true;

  @override
  Widget build(BuildContext context) {
    void switchToAdd() {
      print('prout');
      setState(() {
        isButton = false;
      });
    }

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 250),
      child: isButton
          ? SizedBox(
              height: 64,
              width: double.infinity,
              child: FilledButton(
                onPressed: switchToAdd,
                style: FilledButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text("Add today's photos"),
              ),
            )
          : EntryEdition(
              null,
              onClose: () {
                setState(() {
                  isButton = true;
                });
              },
            ),
    );
  }
}
