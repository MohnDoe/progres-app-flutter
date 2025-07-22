import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';
import 'package:progres/src/features/entries/list/controllers/list_entries_controller.dart';
import 'package:progres/src/features/timelapse/_shared/repositories/timelapse_notifier.dart';
import 'package:progres/src/features/timelapse/player/widgets/header_infos_divider.dart';

class HeaderInfos extends ConsumerStatefulWidget {
  const HeaderInfos({super.key, required this.timelapse});

  final Timelapse timelapse;

  @override
  ConsumerState<HeaderInfos> createState() => _HeaderInfosState();
}

class _HeaderInfosState extends ConsumerState<HeaderInfos> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the listEntriesControllerProvider to get the current state.
    final int totalDays = widget.timelapse.to.difference(widget.timelapse.from).inDays;
    int totalPhotos = widget.timelapse.entries.length;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        spacing: 8,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            DateFormat.yMMMd().format(widget.timelapse.from),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const HeaderInfosDivider(),
          Column(
            children: [
              Text(
                "${NumberFormat.decimalPattern().format(totalDays)} days",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                "$totalPhotos photos!",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const HeaderInfosDivider(),
          Text(
            DateFormat.yMMMd().format(widget.timelapse.to),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
