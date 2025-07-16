import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/ui/widgets/picture_rectangle.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entry_provider.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/picture_source_selection_bottom_sheet.dart';

class EntryTypePictureCard extends ConsumerStatefulWidget {
  const EntryTypePictureCard({super.key, required this.type});

  final ProgressEntryType type;

  @override
  ConsumerState<EntryTypePictureCard> createState() =>
      _EntryTypePictureCardState();
}

class _EntryTypePictureCardState extends ConsumerState<EntryTypePictureCard> {
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
    ProgressEntry entry = ref.watch(progressEntryStateNotifierProvider);

    return Column(
      children: [
        Text(widget.type.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        PictureRectangle(
          entry.pictures[widget.type],
          width: 80,
          height: 80,
          borderRadius: 32,
          highlight: entry.pictures[widget.type] == null,
          highlightWidth: 2,
          highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          onTap: () => _displayPictureSourceOptions(),
          emptyWidget: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            child: Center(child: ProgressEntry.getIconFromType(widget.type)),
          ),
        ),
      ],
    );
  }
}
