import 'package:flutter/material.dart';

class PictureSourceSelectionBottomSheet extends StatelessWidget {
  const PictureSourceSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) => Column(
        children: [
          TextButton.icon(
            onPressed: () {},
            label: Text("Upload image"),
            icon: Icon(Icons.upload),
          ),
          TextButton.icon(
            onPressed: () {},
            label: Text("Take a picture"),
            icon: Icon(Icons.camera),
          ),
        ],
      ),
    );
  }
}
