import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/entry_status_provider.dart';
import 'package:progres/src/features/entries/import/views/import_screen.dart';
import 'package:progres/src/features/entries/list/controllers/list_entries_controller.dart';
import 'package:progres/src/features/entries/list/widgets/add_today_button.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/widgets/entry_item.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/entry_bottom_sheet.dart';

/// The screen that displays the list of progress entries.
///
/// This widget is a [ConsumerWidget], which means it can listen to providers.
/// It listens to the [listEntriesControllerProvider] to get the state of the entries list.
class ListEntriesScreen extends ConsumerWidget {
  const ListEntriesScreen({super.key});

  void _displayEditEntryBottomSheet(
    BuildContext context,
    ProgressEntry? entry,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return EntryBottomSheet(entry, isNewEntry: entry == null);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the listEntriesControllerProvider to get the current state.
    final entriesState = ref.watch(listEntriesControllerProvider);

    final bool alreadyEntryForToday = ref.watch(
      doesEntryExistForDateProvider(DateTime.now()),
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton(
            icon: FaIcon(FontAwesomeIcons.plus),
            iconSize: 16,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: TextButton.icon(
                  icon: FaIcon(FontAwesomeIcons.plus, size: 16),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _displayEditEntryBottomSheet(context, null);
                  },
                  label: Text("New entry"),
                ),
              ),
              PopupMenuItem(
                child: TextButton.icon(
                  icon: FaIcon(FontAwesomeIcons.upload, size: 16),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ImportScreen()),
                    );
                  },
                  label: Text("Import photos"),
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      // Use the `when` method to handle the different states of the provider.
      body: entriesState.when(
        data: (entries) {
          final List<Widget> listItems = [
            if (!alreadyEntryForToday) AddTodayButton(),
          ];

          listItems.addAll(
            entries.map(
              (ProgressEntry entry) => EntryItem(
                key: ObjectKey(entry),
                highlight: alreadyEntryForToday && entries.indexOf(entry) == 0,
                entry: entry,
                onTapEdit: () {
                  _displayEditEntryBottomSheet(context, entry);
                },
              ),
            ),
          );

          listItems.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Center(
                child: Text(
                  "Your journey began here.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          );

          return entries.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListView.separated(
                    itemCount: listItems.length,
                    itemBuilder: (ctx, index) => listItems[index],
                    reverse: true,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                  ),
                )
              : Center(child: const Text('You have no entry.'));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Column(
          children: [
            Center(child: Text(error.toString())),
            TextButton(
              onPressed: () {
                ref.read(listEntriesControllerProvider.notifier).loadEntries();
              },
              child: const Text("reload"),
            ),
          ],
        ),
      ),
    );
  }
}
