import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:progres/font_awesome_flutter/lib/font_awesome_flutter.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/list/controllers/list_entries_controller.dart';
import 'package:progres/src/features/timelapse/_shared/repositories/timelapse_notifier.dart';
import 'package:progres/src/features/timelapse/generation/view/generation_screen.dart';

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

    final entriesState = ref.watch(listEntriesControllerProvider);

    final Map<ProgressEntryType, int> entriesCountByEntryType = ref
        .watch(listEntriesControllerProvider.notifier)
        .getEntriesCountByEntryType(conf.from, conf.to);

    int availablePictures = entriesCountByEntryType[conf.type]!;

    double minFps = 1;

    double maxFps = 30;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: SingleChildScrollView(
        child: entriesState.when(
          data: (_) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 16,
              children: <Widget>[
                _buildProgressEntryTypeSelector(conf, entriesCountByEntryType),
                _buildFpsSlider(conf, minFps: minFps, maxFps: maxFps),
                _buildQualitySelector(conf),
                _buildBooleanSwitch(
                  title: 'Show Date on Timelapse',
                  value: conf.showDateOnTimelapse,
                  onChanged: (value) =>
                      ref.read(timelapseProvider.notifier).setShowDateOnTimelapse(value),
                ),
                // _buildDateRangePicker(),
                _buildBooleanSwitch(
                  title: 'Enable Stabilization',
                  value: conf.stabilization,
                  onChanged: (value) =>
                      ref.read(timelapseProvider.notifier).setStabilization(value),
                ),
                _buildBooleanSwitch(
                  title: 'Add Watermark',
                  value: conf.watermark,
                  onChanged: (value) =>
                      ref.read(timelapseProvider.notifier).setWatermark(value),
                ),
              ],
            ),
          ),
          error: (error, stackTrace) => Column(
            children: [
              Center(child: Text(error.toString())),
              TextButton(
                onPressed: () {
                  ref.read(listEntriesControllerProvider.notifier).loadEntries();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushReplacementNamed(GenerationScreen.name),
        icon: FaIcon(FontAwesomeIcons.solidPlay, size: 16),
        label: Text("Generate now"),
      ),
    );
  }

  Widget _buildFpsSlider(Timelapse conf, {double minFps = 5, double maxFps = 30}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FPS: ${conf.fps.round()}'),
        Slider(
          value: conf.fps.toDouble(),
          min: minFps,
          max: maxFps,
          divisions: (maxFps - minFps).round(),
          label: conf.fps.toString(),
          onChanged: (value) =>
              ref.read(timelapseProvider.notifier).setFps(value.round()),
        ),
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
    return SwitchListTile(title: Text(title), value: value, onChanged: onChanged);
  }

  Widget _buildProgressEntryTypeSelector(
    Timelapse conf,
    Map<ProgressEntryType, int> entriesCountByEntryType,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            spacing: 16,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: ProgressEntryType.values
                .map(
                  (entryType) => ChoiceChip(
                    visualDensity: VisualDensity.comfortable,
                    label: Text(
                      "${entryType.label} - ${entriesCountByEntryType[entryType]}",
                    ),
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
          ),
        ),
      ],
    );
    // return DropdownButtonFormField<ProgressEntryType>(
    //   decoration: const InputDecoration(labelText: 'Progress Entry Type'),
    //   value: _progressEntryType,
    //   items: ProgressEntryType.values.map((ProgressEntryType type) {
    //     return DropdownMenuItem<ProgressEntryType>(
    //       value: type,
    //       child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
    //     );
    //   }).toList(),
    //   onChanged: (ProgressEntryType? newValue) {
    //     if (newValue != null) {
    //       setState(() {
    //         _progressEntryType = newValue;
    //       });
    //     }
    //   },
    // );
  }
}
