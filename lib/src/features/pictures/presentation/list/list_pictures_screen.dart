import 'package:flutter/material.dart';
import 'package:progres/src/features/pictures/presentation/list/widgets/bottom_sheet_selection.dart';

class ListPicturesScreen extends StatefulWidget {
  const ListPicturesScreen({super.key});

  @override
  State<ListPicturesScreen> createState() => _ListPicturesScreenState();
}

class _ListPicturesScreenState extends State<ListPicturesScreen> {
  void _displayPickOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return const BottomSheetSelection();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pictures"),
        actions: [
          IconButton(onPressed: _displayPickOptions, icon: Icon(Icons.add)),
        ],
      ),
      body: Center(child: Text("No picture.")),
    );
  }
}
