import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/import/views/import_screen.dart';
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
      appBar: AppBar(
        title: const Text("Entries"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ImportScreen()));
            },
            child: Text("Import"),
          ),
        ],
      ),
      // Use the `when` method to handle the different states of the provider.
      body: entriesState.when(
        data: (entries) => entries.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: entries.length + 1,
                  itemBuilder: (ctx, index) => (index != 0)
                      ? EntryItem(
                          entry: entries[index - 1],
                          onTapEdit: () {
                            _displayEntryBottomSheet(
                              context,
                              entries[index - 1],
                            );
                          },
                        )
                      : SizedBox(
                          height: 64,
                          child: FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            child: Text("Add today's photos"),
                          ),
                        ),
                  reverse: true,
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
      // floatingActionButtonLocation: ExpandableFab.location,
      // floatingActionButton: ExpandableFab(
      //   // TODO: make this shit cuter
      //   type: ExpandableFabType.up,
      //   childrenAnimation: ExpandableFabAnimation.none,
      //   distance: 80,
      //   openButtonBuilder: RotateFloatingActionButtonBuilder(
      //     child: const Icon(Icons.add),
      //     fabSize: ExpandableFabSize.regular,
      //     shape: const CircleBorder(),
      //     angle: 0,
      //   ),
      //   children: [
      //     FilledButton.icon(
      //       onPressed: () {
      //         Navigator.of(
      //           context,
      //         ).push(MaterialPageRoute(builder: (_) => const ImportScreen()));
      //       },
      //       label: Text("Import photos"),
      //       icon: const Icon(Icons.upload),
      //     ),
      //     FilledButton.icon(
      //       onPressed: () {
      //         _displayEntryBottomSheet(context, null);
      //       },
      //       label: Text("Create entry"),
      //       icon: const Icon(Icons.add),
      //     ),
      //   ],
      // ),
    );
  }
}
