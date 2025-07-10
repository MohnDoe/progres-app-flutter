import 'package:flutter/material.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';

class TodayEntryHighlight extends StatefulWidget {
  const TodayEntryHighlight(this.entry, {super.key, required this.onTapEdit});

  final ProgressEntry entry;
  final void Function() onTapEdit;

  @override
  State<TodayEntryHighlight> createState() => _TodayEntryHighlightState();
}

class _TodayEntryHighlightState extends State<TodayEntryHighlight> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            children: [
              Text(
                "Today's photos",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "Looking great!",
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                primary: false,
                shrinkWrap: true, // Allow GridView to size itself vertically
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling if it's not desired within this small grid
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8, // Added for spacing between columns
                childAspectRatio: 1.0,
                children: widget.entry.pictures.keys
                    .map(
                      (ProgressEntryType entryType) => ClipPath(
                        clipBehavior: Clip.antiAlias,
                        clipper: ShapeBorderClipper(
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(32)),
                          ),
                        ),
                        child: Container(
                          child: widget.entry.pictures[entryType] != null
                              ? Image.file(
                                  widget.entry.pictures[entryType]!.file,
                                  fit: BoxFit.cover,
                                )
                              : SizedBox(width: 80),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Positioned(
            left: 0,
            child: IconButton.filled(
              onPressed: widget.onTapEdit,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.edit,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
