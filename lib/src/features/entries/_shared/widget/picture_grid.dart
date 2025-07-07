import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

class ProgressEntriesList extends StatefulWidget {
  const ProgressEntriesList({super.key, required this.entries});

  final List<ProgressEntry> entries;

  @override
  State<ProgressEntriesList> createState() => ProgressEntriesListState();
}

class ProgressEntriesListState extends State<ProgressEntriesList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.entries.length,
      itemBuilder: (BuildContext context, int index) =>
          Text(widget.entries[index].date.toString()),
    );
  }
}
