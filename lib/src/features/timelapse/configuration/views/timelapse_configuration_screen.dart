import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';

class TimelapseConfigurationScreen extends ConsumerStatefulWidget {
  const TimelapseConfigurationScreen({super.key});

  static const String name = 'timelapse-configuration';
  static const String path = '/timelapse-configuration';

  @override
  ConsumerState createState() => _TimelapseConfigurationScreenState();
}

enum Quality { sd, fhd, uhd }

class _TimelapseConfigurationScreenState
    extends ConsumerState<TimelapseConfigurationScreen> {
  double _fps = 15;
  Quality _quality = Quality.fhd;
  bool _showDateOnTimelapse = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  ProgressEntryType _progressEntryType = ProgressEntryType.front;
  bool _stabilization = true;
  bool _watermark = true;

  // Dummy data for available pictures, replace with actual logic
  final int _availablePictures = 100;

  double get _minFps => _availablePictures > 0 ? 5 : 0;
  double get _maxFps => _availablePictures > 0 ? 30 : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildProgressEntryTypeSelector(),
          _buildFpsSlider(),
          _buildQualitySelector(),
          _buildBooleanSwitch(
            title: 'Show Date on Timelapse',
            value: _showDateOnTimelapse,
            onChanged: (value) => setState(() => _showDateOnTimelapse = value),
          ),
          // _buildDateRangePicker(),
          _buildBooleanSwitch(
            title: 'Enable Stabilization',
            value: _stabilization,
            onChanged: (value) => setState(() => _stabilization = value),
          ),
          _buildBooleanSwitch(
            title: 'Add Watermark',
            value: _watermark,
            onChanged: (value) => setState(() => _watermark = value),
          ),
        ],
      ),
    );
  }

  Widget _buildFpsSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FPS: ${_fps.round()}'),
        Slider(
          value: _fps,
          min: _minFps,
          max: _maxFps,
          divisions: (_maxFps - _minFps).round(),
          label: _fps.round().toString(),
          onChanged: _availablePictures > 0
              ? (double value) {
                  setState(() {
                    _fps = value;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildQualitySelector() {
    return DropdownButtonFormField<Quality>(
      decoration: const InputDecoration(labelText: 'Quality'),
      value: _quality,
      items: Quality.values.map((Quality quality) {
        return DropdownMenuItem<Quality>(
          value: quality,
          child: Text(quality.name.toUpperCase()),
        );
      }).toList(),
      onChanged: (Quality? newValue) {
        if (newValue != null) {
          setState(() {
            _quality = newValue;
          });
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

  // Widget _buildDateRangePicker() {
  // final dateFormat = DateFormat.yMMMd();
  // return null;
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: DateTimePicker(
  //           labelText: 'Start Date',
  //           selectedDate: _startDate,
  //           onSelectedDate: (date) => setState(() => _startDate = date),
  //         ),
  //       ),
  //       const SizedBox(width: 16),
  //       Expanded(
  //         child: DateTimePicker(
  //           labelText: 'End Date',
  //           selectedDate: _endDate,
  //           onSelectedDate: (date) => setState(() => _endDate = date),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildProgressEntryTypeSelector() {
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
                    label: Text(entryType.label),
                    showCheckmark: false,
                    side: BorderSide.none,
                    avatar: ProgressEntry.getIconFromType(entryType),
                    iconTheme: IconThemeData(size: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    selected: _progressEntryType == entryType,
                    onSelected: (bool _) {
                      setState(() {
                        _progressEntryType = entryType;
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
    return DropdownButtonFormField<ProgressEntryType>(
      decoration: const InputDecoration(labelText: 'Progress Entry Type'),
      value: _progressEntryType,
      items: ProgressEntryType.values.map((ProgressEntryType type) {
        return DropdownMenuItem<ProgressEntryType>(
          value: type,
          child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
        );
      }).toList(),
      onChanged: (ProgressEntryType? newValue) {
        if (newValue != null) {
          setState(() {
            _progressEntryType = newValue;
          });
        }
      },
    );
  }
}
