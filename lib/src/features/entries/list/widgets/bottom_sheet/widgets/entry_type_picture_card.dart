import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/ui/widgets/picture_rectangle.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
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
    ProgressEntryType type = widget.type;
    ProgressEntry entry = ref.watch(progressEntryStateNotifierProvider);

    final ProgressPicture? picture = entry.pictures[type];
    final progressEntryNotifier = ref.read(
      progressEntryStateNotifierProvider.notifier,
    );

    Widget cardVisualContent = PictureRectangle(
      picture,
      width: 80,
      height: 80,
      borderRadius: 32,
      highlight: picture == null,
      highlightWidth: 2,
      highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      onTap: () => _displayPictureSourceOptions(),
      emptyWidget: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Center(child: ProgressEntry.getIconFromType(widget.type)),
      ),
    );

    if (picture != null) {
      Widget draggableCard = LongPressDraggable<ProgressEntryType>(
        data: type,
        feedback: Opacity(
          opacity: 0.75,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
            child: cardVisualContent,
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: cardVisualContent),
        onDragStarted: () {
          // HapticFeedback.mediumImpact();
        },
        child: cardVisualContent,
      );
      cardVisualContent = draggableCard;
    }

    return Column(
      children: [
        Text(type.label, style: Theme.of(context).textTheme.labelLarge),
        SizedBox(height: 8),
        DragTarget<ProgressEntryType>(
          builder:
              (
                BuildContext context,
                List<ProgressEntryType?> candidateData,
                rejectedData,
              ) {
                // TODO: change the appearance if a valid draggable is hovering.
                bool isHoveringAndCanAccept =
                    candidateData.isNotEmpty &&
                    candidateData.first != null &&
                    candidateData.first != type;

                return InkWell(
                  onTap: () => _displayPictureSourceOptions(),
                  child: cardVisualContent,
                );
              },
          // Called when a Draggable is first dragged over this target.
          // `data` is the `data` property from the Draggable.
          onWillAcceptWithDetails: (details) {
            final ProgressEntryType draggedType = details.data;
            // Accept the drop if the dragged item is of type ProgressEntryType
            // and it's not being dropped onto itself.
            // Also, the source (draggedType) must have a picture.
            final sourcePicture = ref
                .read(progressEntryStateNotifierProvider)
                .pictures[draggedType];

            return sourcePicture != null && draggedType != type;
          },
          // Called when an accepted Draggable is dropped onto this target.
          onAcceptWithDetails: (details) {
            final ProgressEntryType draggedType = details.data;
            final ProgressEntryType targetType = type;

            progressEntryNotifier.movePicture(
              fromType: draggedType,
              toType: targetType,
            );
          },
        ),
      ],
    );
  }
}
