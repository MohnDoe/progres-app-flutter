import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/providers/entries_provider.dart';
import 'package:progres/src/features/entries/list/widgets/picture_source_selection_bottom_sheet.dart';

class EntryTypeSelection extends ConsumerStatefulWidget {
  const EntryTypeSelection({super.key, required this.type});

  final ProgressEntryType type;

  @override
  ConsumerState<EntryTypeSelection> createState() => _EntryTypeSelectionState();
}

class _EntryTypeSelectionState extends ConsumerState<EntryTypeSelection> {
  void _displayPictureSourceOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return PictureSourceSelectionBottomSheet(widget.type);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ProgressEntry entry = ref.watch(progressEntryProvider);

    return Column(
      children: [
        Text(widget.type.name, style: Theme.of(context).textTheme.labelLarge),
        SizedBox(height: 4),
        InkWell(
          onTap: () => _displayPictureSourceOptions(),
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.all(Radius.circular(8)),
              border: Border.all(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                width: 2,
              ),
            ),
            child: entry.pictures[widget.type] != null
                ? Image(
                    image: FileImage(entry.pictures[widget.type]!.file),
                    fit: BoxFit.cover,
                  )
                : Text('R'),
          ),
        ),
      ],
    );
  }
}
