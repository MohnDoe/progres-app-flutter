import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/pictures/_shared/widget/picture_grid.dart';
import 'package:progres/src/features/pictures/list_pictures/viewmodels/list_pictures_view_model.dart';
import 'package:progres/src/features/pictures/list_pictures/widgets/bottom_sheet_selection.dart';
import 'package:progres/src/features/video/generation/view/generation_screen.dart';

/// The screen that displays the list of progress pictures.
///
/// This widget is a [ConsumerWidget], which means it can listen to providers.
/// It listens to the [picturesViewModelProvider] to get the state of the pictures list.
class ListPicturesScreen extends ConsumerWidget {
  const ListPicturesScreen({super.key});

  /// Displays the bottom sheet for picking new pictures.
  ///
  /// After the bottom sheet is dismissed, it reloads the pictures.
  void _displayPickOptions(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return const BottomSheetSelection();
      },
    );
    // ref.read(picturesViewModelProvider.notifier).loadPictures();
  }

  void removePicture(WidgetRef ref, ProgressPicture picture) {
    ref.read(picturesViewModelProvider.notifier).removePicture(picture);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the picturesViewModelProvider to get the current state.
    final picturesState = ref.watch(picturesViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pictures"),
        actions: [
          IconButton(
            onPressed: () => _displayPickOptions(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      // Use the `when` method to handle the different states of the provider.
      body: picturesState.when(
        data: (pictures) => PictureGrid(pictures: pictures),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
      ),
      floatingActionButton: FilledButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => GenerationScreen()));
        },
        child: Text("Generate"),
      ),
    );
  }
}
