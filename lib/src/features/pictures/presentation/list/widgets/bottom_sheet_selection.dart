import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progres/src/features/pictures/data/picker.dart';
import 'package:progres/src/features/pictures/domain/progress_picture.dart';
import 'package:progres/src/features/pictures/presentation/add/add_pictures_screen.dart';

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
