import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/providers/entries_provider.dart';
import 'package:progres/src/features/entries/_shared/repositories/picker.dart';

class PictureSourceSelectionBottomSheet extends ConsumerWidget {
  const PictureSourceSelectionBottomSheet(this.type, {super.key});

  final ProgressEntryType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ProgressEntry entry = ref.watch(progressEntryProvider);

    void closeSourceSelectionBottomSheet() {
      // close source selection bottom sheet
      Navigator.of(context).pop();
    }

    void pictureSelectionDone(ProgressPicture picture) {
      ref
          .read(progressEntryProvider.notifier)
          .setProgressPictureToType(type, picture);
      closeSourceSelectionBottomSheet();
    }

    void pickImage(ImageSource source) async {
      final picture = await Picker().pickImage(source);
      if (picture != null) {
        pictureSelectionDone(picture);
      }
    }

    void removeImage() {
      ref.read(progressEntryProvider.notifier).removePicture(type);
      closeSourceSelectionBottomSheet();
    }

    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => pickImage(ImageSource.gallery),
              label: Text("Upload image"),
              icon: Icon(Icons.upload),
            ),
            TextButton.icon(
              onPressed: () => pickImage(ImageSource.camera),
              label: Text("Take a picture"),
              icon: Icon(Icons.camera),
            ),
            if (entry.pictures[type] != null)
              TextButton.icon(
                onPressed: removeImage,
                label: Text("Remove"),
                icon: Icon(Icons.remove_circle),
              ),
          ],
        ),
      ),
    );
  }
}
