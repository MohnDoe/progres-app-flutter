import 'package:flutter/material.dart';

class NewEntryBottomSheet extends StatefulWidget {
  const NewEntryBottomSheet({super.key, required this.onSelectSide});

  final void Function(String side) onSelectSide;

  @override
  State<NewEntryBottomSheet> createState() => _NewEntryBottomSheetState();
}

class _NewEntryBottomSheetState extends State<NewEntryBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      constraints: BoxConstraints(maxHeight: 250),
      builder: (BuildContext context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Progress photos",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Front', 'Side', 'Back']
                    .map(
                      (side) => Column(
                        children: [
                          Text(
                            side,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          SizedBox(height: 4),
                          InkWell(
                            onTap: () => widget.onSelectSide(side),
                            child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHigh,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
