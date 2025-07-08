import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

import 'image_card.dart';

class DayGroup extends StatefulWidget {
  const DayGroup({super.key, required this.date, required this.pictures});

  final DateTime date;
  final List<ProgressPicture> pictures;

  @override
  State<DayGroup> createState() => _DayGroupState();
}

class _DayGroupState extends State<DayGroup> {
  @override
  Widget build(BuildContext context) {
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
                  style: Theme.of(context).textTheme.headlineSmall,
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
                  onPressed: () {},
                  icon: Icon(Icons.delete_outline, size: 16),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            padding: EdgeInsets.all(8),
            child: Column(
              children: widget.pictures
                  .map(
                    (picture) => Container(
                      margin: const EdgeInsets.only(bottom: 4),
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
