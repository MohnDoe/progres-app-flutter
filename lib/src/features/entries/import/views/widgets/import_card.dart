import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/import/controllers/import_controller.dart';

class ImportCard extends ConsumerStatefulWidget {
  const ImportCard(this.importItem, {super.key, required this.disabled});

  final ImportItem importItem;
  final bool disabled;

  @override
  ConsumerState<ImportCard> createState() => _ImportCardState();
}

class _ImportCardState extends ConsumerState<ImportCard> {
  void _onDelete(ProgressPicture picture) {
    ref
        .read(importControllerProvider.notifier)
        .removePictureFromImports(picture);
  }

  void _onSelectedType(ProgressEntryType entryType) {
    ref
        .read(importControllerProvider.notifier)
        .updatePictureEntryType(widget.importItem.picture, entryType);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: widget.disabled ? 4 : 8,
      children: [
        Expanded(
          child: Container(
            width: widget.disabled ? 100 : 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Stack(
                  children: [
                    Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
                    ),
                    Opacity(
                      opacity: widget.disabled ? .75 : 1,
                      child: Image.file(
                        width: double.infinity,
                        height: double.infinity,
                        widget.importItem.picture.file,
                        fit: BoxFit.cover,
                        colorBlendMode: widget.disabled
                            ? BlendMode.saturation
                            : null,
                        color: widget.disabled ? Colors.grey : null,
                      ),
                    ),
                  ],
                ),
                if (!widget.disabled)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      style: Theme.of(context).filledButtonTheme.style!
                          .copyWith(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.surface,
                            ),
                          ),
                      onPressed: () {
                        _onDelete(widget.importItem.picture);
                      },
                      icon: FaIcon(
                        FontAwesomeIcons.trash,
                        size: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!widget.disabled)
          Material(
            color: Colors.transparent,
            child: Row(
              spacing: 4,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: ProgressEntryType.values
                  .map(
                    (entryType) => ChoiceChip(
                      visualDensity: VisualDensity(
                        horizontal: VisualDensity.minimumDensity,
                        vertical: VisualDensity.minimumDensity,
                      ),
                      label: Text(entryType.label),
                      showCheckmark: false,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      selected: widget.importItem.type == entryType,
                      onSelected: (bool _) {
                        _onSelectedType(entryType);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
