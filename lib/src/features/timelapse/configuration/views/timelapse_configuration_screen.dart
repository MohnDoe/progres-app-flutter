import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:progres/font_awesome_flutter/lib/font_awesome_flutter.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';
import 'package:progres/src/features/entries/list/controllers/list_entries_controller.dart';
import 'package:progres/src/features/timelapse/_shared/repositories/timelapse_notifier.dart';
import 'package:progres/src/features/timelapse/configuration/widgets/date_histogram.dart';
import 'package:progres/src/features/timelapse/generation/view/generation_screen.dart';
import 'package:progres/src/features/timelapse/player/widgets/header_infos_divider.dart';

const idealDurationRange = [Duration(seconds: 1), Duration(seconds: 5)];

class TimelapseConfigurationScreen extends ConsumerStatefulWidget {
  const TimelapseConfigurationScreen({super.key});

  static const String name = 'timelapse-configuration';
  static const String path = '/timelapse-configuration';

  @override
  ConsumerState createState() => _TimelapseConfigurationScreenState();
}

class _TimelapseConfigurationScreenState
    extends ConsumerState<TimelapseConfigurationScreen> {
  // Dummy data for available pictures, replace with actual logic

  @override
  Widget build(BuildContext context) {
    Timelapse conf = ref.watch(timelapseProvider);

    final entries = ref.watch(progressEntriesRepositoryProvider).orderedEntries;

    final Map<ProgressEntryType, int> entriesCountByEntryType = ref
        .watch(listEntriesControllerProvider.notifier)
        .getEntriesCountByEntryType(conf.from, conf.to);

    double minFps = 1;
    double maxFps = 30;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 16,
            children: <Widget>[
              ConfigurationContainer(
                label: 'Select a range',
                child: _buildDateRangePicker(conf, entries.last.date, entries.first.date),
              ),
              ConfigurationContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildProgressEntryTypeSelector(conf, entriesCountByEntryType),
              ),
              ConfigurationContainer(
                label: 'Framerate',
                child: _buildFpsSlider(conf, minFps: minFps, maxFps: maxFps),
              ),
              ConfigurationContainer(child: _buildQualitySelector(conf)),
              ConfigurationContainer(
                padding: const EdgeInsets.all(4),
                child: _buildBooleanSwitch(
                  title: 'Show Date on Timelapse',
                  value: conf.showDateOnTimelapse,
                  onChanged: (value) =>
                      ref.read(timelapseProvider.notifier).setShowDateOnTimelapse(value),
                ),
              ),
              ConfigurationContainer(
                padding: const EdgeInsets.all(4),
                child: _buildBooleanSwitch(
                  title: 'Enable Stabilization',
                  value: conf.stabilization,
                  onChanged: (value) =>
                      ref.read(timelapseProvider.notifier).setStabilization(value),
                ),
              ),
              ConfigurationContainer(
                padding: const EdgeInsets.all(4),
                child: _buildBooleanSwitch(
                  title: 'Add Watermark',
                  value: conf.watermark,
                  onChanged: (value) =>
                      ref.read(timelapseProvider.notifier).setWatermark(value),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref
              .read(timelapseProvider.notifier)
              .setEntries(
                ref
                    .watch(listEntriesControllerProvider.notifier)
                    .getEntriesBetweenDates(conf.from, conf.to, conf.type),
              );
          context.goNamed(GenerationScreen.name);
        },
        icon: FaIcon(FontAwesomeIcons.solidPlay, size: 16),
        label: Text("Generate now"),
      ),
    );
  }

  Widget _buildFpsSlider(Timelapse conf, {double minFps = 5, double maxFps = 30}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Slider(
            value: conf.fps.toDouble(),
            min: minFps,
            max: maxFps,
            divisions: (maxFps - minFps).round(),
            label: conf.fps.toString(),
            onChanged: (value) =>
                ref.read(timelapseProvider.notifier).setFps(value.round()),
          ),
        ),
        Text('${conf.fps.round()}'),
      ],
    );
  }

  Widget _buildQualitySelector(Timelapse conf) {
    return DropdownButtonFormField<Quality>(
      decoration: const InputDecoration(labelText: 'Quality'),
      value: conf.quality,
      items: Quality.values.map((Quality quality) {
        return DropdownMenuItem<Quality>(
          value: quality,
          child: Text(quality.name.toUpperCase()),
        );
      }).toList(),
      onChanged: (Quality? newValue) {
        if (newValue != null) {
          ref.read(timelapseProvider.notifier).setQuality(newValue);
        }
      },
    );
  }

  Widget _buildBooleanSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      visualDensity: VisualDensity.compact,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildProgressEntryTypeSelector(
    Timelapse conf,
    Map<ProgressEntryType, int> entriesCountByEntryType,
  ) {
    return Row(
      spacing: 16,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: ProgressEntryType.values
          .map(
            (entryType) => ChoiceChip(
              visualDensity: VisualDensity.comfortable,
              label: Text("${entryType.label} - ${entriesCountByEntryType[entryType]}"),
              showCheckmark: false,
              side: BorderSide.none,
              avatar: ProgressEntry.getIconFromType(entryType),
              iconTheme: IconThemeData(size: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              selected: conf.type == entryType,
              onSelected: entriesCountByEntryType[entryType]! > 0
                  ? (bool _) {
                      ref.read(timelapseProvider.notifier).setType(entryType);
                    }
                  : null,
            ),
          )
          .toList(),
    );
  }

  Widget _buildDateRangePicker(
    Timelapse conf,
    DateTime firstEntryDate,
    DateTime lastEntryDate,
  ) {
    final dateFormatter = DateFormat.yMMMd();

    print('First entry date: $firstEntryDate');
    print('Last entry date: $lastEntryDate');

    print('[Before binding] Conf from: ${conf.from}');
    print('[Before binding] Conf to: ${conf.to}');
    if (conf.from.isBefore(firstEntryDate)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(timelapseProvider.notifier).setFrom(firstEntryDate),
      );
    }
    if (conf.to.isAfter(lastEntryDate)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(timelapseProvider.notifier).setTo(lastEntryDate),
      );
    }

    final int totalDays = conf.to.difference(conf.from).inDays;

    print('Conf from: ${conf.from}');
    print('Conf to: ${conf.to}');

    return firstEntryDate.isAtSameMomentAs(DateTime.now())
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(dateFormatter.format(conf.from)),
                  const HeaderInfosDivider(count: 4, size: 8),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity(
                        horizontal: VisualDensity.minimumDensity,
                        vertical: VisualDensity.comfortable.vertical,
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
                    ),
                    onPressed: () => _selectDateRange(
                      context,
                      ref,
                      conf,
                      firstEntryDate,
                      lastEntryDate,
                    ),
                    child: Text(
                      "${NumberFormat.decimalPattern().format(totalDays)} days",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const HeaderInfosDivider(count: 4, size: 8),
                  Text(dateFormatter.format(conf.to)),
                ],
              ),
              RangeSlider(
                values: RangeValues(
                  conf.from.millisecondsSinceEpoch.toDouble(),
                  conf.to.millisecondsSinceEpoch.toDouble(),
                ),
                min: firstEntryDate.millisecondsSinceEpoch.toDouble(),
                max: lastEntryDate.millisecondsSinceEpoch.toDouble(),
                labels: null,
                onChanged: (RangeValues values) {
                  ref
                      .read(timelapseProvider.notifier)
                      .setFrom(DateTime.fromMillisecondsSinceEpoch(values.start.round()));
                  ref
                      .read(timelapseProvider.notifier)
                      .setTo(DateTime.fromMillisecondsSinceEpoch(values.end.round()));
                },
              ),
              const DateHistogram(),
              // TODO: create input for each date
              // TextButton(
              //   onPressed: () =>
              //       _selectDateRange(context, ref, conf, firstEntryDate, lastEntryDate),
              //   child: const Text("Select Date Range with Picker"),
              // ),
            ],
          );
  }

  Future<void> _selectDate(
    BuildContext context,
    WidgetRef ref,
    DateTime firstDate,
    DateTime lastDate,
    Timelapse conf, {
    bool isFrom = true,
  }) async {
    final DateTime lastPossibleDate = isFrom ? conf.to : lastDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? conf.from : conf.to,
      firstDate: firstDate,
      lastDate: lastPossibleDate,
    );

    if (picked != null) {
      final timelapseNotifier = ref.read(timelapseProvider.notifier);
      if (isFrom) {
        timelapseNotifier.setFrom(picked);
      } else {
        timelapseNotifier.setTo(picked);
      }
    }
  }

  Future<void> _selectDateRange(
    BuildContext context,
    WidgetRef ref,
    Timelapse conf,
    DateTime firstDate,
    DateTime lastDate,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: conf.from, end: conf.to),
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: DateTime.now(),
      saveText: "Set range",
    );
    if (picked != null) {
      final timelapseNotifier = ref.read(timelapseProvider.notifier);
      timelapseNotifier.setFrom(picked.start);
      timelapseNotifier.setTo(picked.end);
    }
  }
}

class ConfigurationContainer extends StatelessWidget {
  const ConfigurationContainer({
    super.key,
    required this.child,
    this.label,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final String? label;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          label == null
              ? const SizedBox.shrink()
              : Text(label!, style: Theme.of(context).textTheme.titleMedium),
          child,
        ],
      ),
    );
  }
}
