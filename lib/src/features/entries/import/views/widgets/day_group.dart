import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/import/controllers/import_controller.dart';

import 'image_card.dart';

class DayGroup extends ConsumerStatefulWidget {
  const DayGroup({super.key, required this.date, required this.pictures});

  final DateTime date;
  final List<ProgressPicture> pictures;

  @override
  ConsumerState<DayGroup> createState() => _DayGroupState();
}

class _DayGroupState extends ConsumerState<DayGroup> {
  @override
  Widget build(BuildContext context) {
    void onDeleteDayGroup(DateTime date) {
      ref.read(importControllerProvider.notifier).removeDay(date);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Text(
                  DateFormat.yMMMMd().format(widget.date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Spacer(),
                Row(
                  children: [
                    Text(
                      '${widget.pictures.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '/${ProgressEntryType.values.length}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => onDeleteDayGroup(widget.date),
                  icon: Icon(Icons.delete_outline, size: 16),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: widget.pictures
                  .map(
                    (picture) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: ImageCard(picture: picture, date: widget.date),
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
