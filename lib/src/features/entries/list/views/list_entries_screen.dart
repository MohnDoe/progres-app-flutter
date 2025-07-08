import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/list/controllers/list_entries_controller.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/widgets/entry_item.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/entry_bottom_sheet.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/picture_source_selection_bottom_sheet.dart';

/// The screen that displays the list of progress entries.
///
/// This widget is a [ConsumerWidget], which means it can listen to providers.
/// It listens to the [listEntriesControllerProvider] to get the state of the entries list.
class ListEntriesScreen extends ConsumerWidget {
  const ListEntriesScreen({super.key});

  void _displayEntryBottomSheet(
    BuildContext context,
    ProgressEntry? entry,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return EntryBottomSheet(entry);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the listEntriesControllerProvider to get the current state.
    final entriesState = ref.watch(listEntriesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Entries")),
      // Use the `when` method to handle the different states of the provider.
      body: entriesState.when(
        data: (entries) => entries.isNotEmpty
            ? ListView.builder(
                itemCount: entries.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (ctx, index) => EntryItem(
                  entry: entries[index],
                  onTapEdit: () {
                    _displayEntryBottomSheet(context, entries[index]);
                  },
                ),
              )
            : Center(child: const Text('You have no entry.')),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _displayEntryBottomSheet(context, null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
