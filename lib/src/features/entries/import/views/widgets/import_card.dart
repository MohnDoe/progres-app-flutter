import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/import/controllers/import_controller.dart';

class ImportCard extends ConsumerStatefulWidget {
  const ImportCard(this.importItem, {super.key});

  final ImportItem importItem;

  @override
  ConsumerState<ImportCard> createState() => _ImportCardState();
}

class _ImportCardState extends ConsumerState<ImportCard> {
  ProgressEntryType? selectedType;

  void _onDelete(ProgressPicture picture) {
    ref
        .read(importControllerProvider.notifier)
        .removePictureFromImports(picture);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Image.file(
                  widget.importItem.picture.file,
                  width: 120,
                  fit: BoxFit.cover,
                  height: 120,
                ),
                Positioned(
                  bottom: 0,
                  child: IconButton.filled(
                    onPressed: () {
                      _onDelete(widget.importItem.picture);
                    },
                    icon: Icon(Icons.delete_outline),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: ProgressEntryType.values
                  .map(
                    (entryType) => ChoiceChip(
                      visualDensity: VisualDensity(
                        horizontal: VisualDensity.minimumDensity,
                        vertical: VisualDensity.minimumDensity,
                      ),
                      label: Text(entryType.name),
                      showCheckmark: false,
                      selected: selectedType == entryType,
                      onSelected: (bool _) {
                        setState(() {
                          selectedType = entryType;
                        });
                        ref
                            .read(importControllerProvider.notifier)
                            .updatePictureEntryType(
                              widget.importItem.picture,
                              entryType,
                            );
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
