import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/file_service.dart';
import 'package:progres/src/features/pictures/add_pictures/viewmodels/add_pictures_view_model.dart';
import 'package:progres/src/features/pictures/list_pictures/viewmodels/list_pictures_view_model.dart';

/// The screen for adding new pictures.
///
/// This widget is a [ConsumerWidget], which means it can listen to providers.
/// It uses the [addPicturesViewModelProvider] to manage the state of the pictures being added.
class AddPicturesScreen extends ConsumerWidget {
  const AddPicturesScreen({super.key, required this.initialPictures});

  final List<ProgressPicture> initialPictures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the addPicturesViewModelProvider to get the current state.
    final pictures = ref.watch(addPicturesViewModelProvider(initialPictures));
    // Read the notifier to call methods on the view model.
    final picturesNotifier = ref.read(
      addPicturesViewModelProvider(initialPictures).notifier,
    );
    final PicturesFileService picturesFileService = PicturesFileService();

    bool isSaving = false;

    /// Removes a picture from the list.
    void removePicture(ProgressPicture picture) {
      picturesNotifier.removePicture(picture);
      if (pictures.isEmpty) {
        Navigator.of(context).pop();
      }
    }

    /// Saves the pictures to the file system.
    void savePictures() async {
      isSaving = true;
      await picturesFileService.savePictures(pictures);
      isSaving = false;
      // Invalidate the picturesViewModelProvider to force a reload of the pictures list
      ref.invalidate(picturesViewModelProvider);
      Navigator.of(context).pop();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Add pictures")),
      body: ListView.builder(
        itemCount: pictures.length,
        itemBuilder: (BuildContext context, int index) {
          final picture = pictures[index];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.file(picture.file, width: 50),
              Text(picture.date.toString()),
              IconButton(
                onPressed: () {
                  removePicture(picture);
                },
                icon: const Icon(Icons.delete_forever),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: pictures.isNotEmpty || !isSaving ? savePictures : null,
        label: Text('Add ${pictures.length} pictures'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
