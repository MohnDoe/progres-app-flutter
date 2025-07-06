import 'package:flutter/material.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/pictures/add_pictures/views/add_pictures_screen.dart';
import 'package:progres/src/features/pictures/_shared/repositories/picker.dart';

class BottomSheetSelection extends StatelessWidget {
  const BottomSheetSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      width: double.infinity,
      child: Column(
        children: [
          TextButton.icon(
            onPressed: () {},
            label: Text("Take a picture"),
            icon: Icon(Icons.camera),
          ),
          TextButton.icon(
            onPressed: () async {
              final List<ProgressPicture> pictures =
                  await Picker.selectImages();

              if (pictures.isNotEmpty) {
                // Close the bottom sheet before navigating to AddPicturesScreen
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) =>
                        AddPicturesScreen(initialPictures: pictures),
                  ),
                );
              }
            },
            label: Text("Choose images"),
            icon: Icon(Icons.file_copy_outlined),
          ),
        ],
      ),
    );
  }
}
