import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/features/entries/list/viewmodels/list_entries_view_model.dart';
import 'package:progres/src/features/entries/list/widgets/entry_item.dart';
import 'package:progres/src/features/entries/list/widgets/new_entry_bottom_sheet.dart';
import 'package:progres/src/features/entries/list/widgets/picture_source_selection_bottom_sheet.dart';

/// The screen that displays the list of progress entries.
///
/// This widget is a [ConsumerWidget], which means it can listen to providers.
/// It listens to the [picturesViewModelProvider] to get the state of the entries list.
class ListEntriesScreen extends ConsumerWidget {
  const ListEntriesScreen({super.key});

  void _displayAddEntryBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return NewEntryBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the picturesViewModelProvider to get the current state.
    final entriesState = ref.watch(picturesViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Entries"),
        actions: [
          IconButton(
            onPressed: () => _displayAddEntryBottomSheet(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      // Use the `when` method to handle the different states of the provider.
      body: entriesState.when(
        data: (entries) => ListView.builder(
          itemCount: entries.length,
          padding: EdgeInsets.all(8),
          itemBuilder: (ctx, index) => EntryItem(entry: entries[index]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Column(
          children: [
            Center(child: Text(error.toString())),
            TextButton(
              onPressed: () {
                ref.read(picturesViewModelProvider.notifier).loadEntries();
              },
              child: Text("reload"),
            ),
          ],
        ),
      ),
      floatingActionButton: IconButton(onPressed: () {}, icon: Icon(Icons.add)),
    );
  }
}
