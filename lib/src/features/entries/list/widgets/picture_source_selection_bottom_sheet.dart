import 'package:flutter/material.dart';

class PictureSourceSelectionBottomSheet extends StatelessWidget {
  const PictureSourceSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      constraints: BoxConstraints(maxHeight: 150),
      builder: (BuildContext context) => Align(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
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
      ),
    );
  }
}
