import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/timelapse/_shared/repositories/timelapse_notifier.dart';
import 'package:progres/src/features/timelapse/configuration/widgets/date_histogram.dart';

const double kDefaultBorderWidth = 2;
const double kPressedBorderWidth = 4;

class DateSlider extends ConsumerStatefulWidget {
  const DateSlider({
    super.key,
    required this.lastEntryDate,
    required this.firstEntryDate,
    required this.allEntries,
    required this.validEntries,
  });

  final DateTime firstEntryDate;
  final DateTime lastEntryDate;
  final List<ProgressEntry> allEntries;
  final List<ProgressEntry> validEntries;

  @override
  ConsumerState<DateSlider> createState() => _DateSliderState();
}

class _DateSliderState extends ConsumerState<DateSlider> {
  double leftBorderWidth = kDefaultBorderWidth;
  double rightBorderWidth = kDefaultBorderWidth;

  @override
  Widget build(BuildContext context) {
    Timelapse conf = ref.watch(timelapseProvider);

    return Stack(
      children: [
        Positioned(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double horizontalPadding = 24;
              final availableWidth = constraints.maxWidth - (horizontalPadding * 2);

              final selectedStartDate = conf.from;
              final selectedEndDate = conf.to;

              // Ensure totalDays is not zero to avoid division by zero.
              final double overallDateRangeInDays = max(
                1,
                widget.lastEntryDate.difference(widget.firstEntryDate).inDays.toDouble(),
              );

              final selectionStartOffset =
                  (selectedStartDate.difference(widget.firstEntryDate).inDays /
                      overallDateRangeInDays) *
                  availableWidth;

              final selectionEndOffset =
                  (selectedEndDate.difference(widget.firstEntryDate).inDays /
                      overallDateRangeInDays) *
                  availableWidth;

              final selectionWidth = selectionEndOffset - selectionStartOffset;

              return Container(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      top: 8,
                      bottom: 8,
                      left: selectionStartOffset,
                      child: Container(
                        width: selectionWidth,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.secondary.withAlpha((255.0 * 0.2).round()),
                              Theme.of(
                                context,
                              ).colorScheme.secondary.withAlpha((255.0 * 0.5).round()),
                              Theme.of(
                                context,
                              ).colorScheme.secondary.withAlpha((255.0 * 0.2).round()),
                            ],
                          ),
                          border: BoxBorder.fromLTRB(
                            left: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: leftBorderWidth,
                            ),
                            right: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: rightBorderWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: DateHistogram(
                        entries: widget.allEntries.map((entry) => entry.date).toList(),
                        validEntriesDates: widget.validEntries
                            .map((entry) => entry.date)
                            .toList(),
                        selectedFirstDate: conf.from,
                        selectedLastDate: conf.to,
                        dotColor: Theme.of(context).colorScheme.surfaceContainer,
                        dotRadius: 2,
                        validDotColor: Theme.of(context).colorScheme.secondary,
                        validDotRadius: 2,
                        highlightedDotColor: Theme.of(context).colorScheme.primary,
                        highlightedDotRadius: 4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // THE HIDDEN SLIDER
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: RangeSlider(
              values: RangeValues(
                conf.from.millisecondsSinceEpoch.toDouble(),
                conf.to.millisecondsSinceEpoch.toDouble(),
              ),
              min: widget.firstEntryDate.millisecondsSinceEpoch.toDouble(),
              max: widget.lastEntryDate.millisecondsSinceEpoch.toDouble(),
              labels: null,
              onChanged: (RangeValues values) {
                ref
                    .read(timelapseProvider.notifier)
                    .setFrom(DateTime.fromMillisecondsSinceEpoch(values.start.round()));
                ref
                    .read(timelapseProvider.notifier)
                    .setTo(DateTime.fromMillisecondsSinceEpoch(values.end.round()));
              },
              onChangeStart: (RangeValues values) {
                setState(() {
                  leftBorderWidth = rightBorderWidth = kPressedBorderWidth;
                });
              },
              onChangeEnd: (RangeValues values) {
                setState(() {
                  leftBorderWidth = rightBorderWidth = kDefaultBorderWidth;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
