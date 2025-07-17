import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/ui/widgets/picture_rectangle.dart';
import 'package:progres/src/features/gallery/views/gallery_screen.dart';

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
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
            blurRadius: 64,
            spreadRadius: -16,
          ),
        ],
      ),
      child: ClipPath(
        clipBehavior: Clip.antiAlias,
        clipper: ShapeBorderClipper(
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32)),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            // borderRadius: BorderRadius.all(Radius.circular(16)),
            color: Theme.of(context).colorScheme.primary,
          ),
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
          child: Stack(
            children: [
              Column(
                children: [
                  Text(
                    "Today's photos",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "Looking great!",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    primary: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                    children: widget.entry.pictures.keys
                        .map(
                          (ProgressEntryType entryType) => PictureRectangle(
                            key: ValueKey(
                              "${widget.entry.date.millisecondsSinceEpoch}_$entryType",
                            ),
                            widget.entry.pictures[entryType],
                            height: 80,
                            width: 80,
                            borderRadius: 48,
                            onTap: () => context.goNamed(
                              GalleryScreen.name,
                              extra: widget.entry,
                              pathParameters: {'entryType': entryType.name},
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              Positioned(
                right: 8,
                child: FilledButton.icon(
                  style: Theme.of(context).filledButtonTheme.style!.copyWith(
                    shape: WidgetStateProperty.all<ContinuousRectangleBorder>(
                      ContinuousRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                    ),
                    backgroundColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  onPressed: widget.onTapEdit,
                  label: Text(
                    "Edit",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  icon: Icon(
                    Icons.edit,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
