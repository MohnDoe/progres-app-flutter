import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/list/widgets/entry_edition.dart';

class EntryBottomSheet extends ConsumerStatefulWidget {
  const EntryBottomSheet(
    this.initialEntry, {
    super.key,
    this.isNewEntry = false,
  });

  final ProgressEntry? initialEntry;
  final bool isNewEntry;

  @override
  ConsumerState<EntryBottomSheet> createState() => _NewEntryBottomSheetState();
}

class _NewEntryBottomSheetState extends ConsumerState<EntryBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {
        // resetEntry();
      },
      builder: (BuildContext context) => EntryEdition(
        widget.initialEntry,
        canEditDate: widget.isNewEntry,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
