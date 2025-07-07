import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/repositories/picker.dart';

class PictureSourceSelectionBottomSheet extends StatelessWidget {
  const PictureSourceSelectionBottomSheet({
    super.key,
    required this.onSelectionDone,
  });

  final void Function(ProgressPicture progressPicture) onSelectionDone;

  void uploadPicture() async {
    print('uploadPicture');
    final picture = await Picker().pickImage(ImageSource.gallery);
    print('Upload done');
    if (picture != null) {
      onSelectionDone(picture);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: uploadPicture,
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
