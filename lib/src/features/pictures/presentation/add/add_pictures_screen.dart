import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progres/src/features/pictures/data/repositories/pictures_repository.dart';
import 'package:progres/src/features/pictures/data/services/file_service.dart';
import 'package:progres/src/features/pictures/domain/progress_picture.dart';

class AddPicturesScreen extends ConsumerStatefulWidget {
  const AddPicturesScreen({super.key, required this.initialPictures});

  final List<ProgressPicture> initialPictures;

  @override
  ConsumerState createState() => _AddPicturesScreenState();
}

class _AddPicturesScreenState extends ConsumerState<AddPicturesScreen> {
  @override
  void initState() {
    ref.read(picturesRepositoryProvider).addPictures(widget.initialPictures);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final PicturesRepository temporaryPicturesRepository = ref.watch(
      picturesRepositoryProvider,
    );
    final PicturesFileService picturesFileService = PicturesFileService();

    bool _isSaving = false;

    final pictures = temporaryPicturesRepository.orderedPictures;

    void removePicture(ProgressPicture picture) {
      setState(() {
        temporaryPicturesRepository.removePicture(picture);
      });

      if (pictures.isEmpty) {
        Navigator.of(context).pop();
      }
    }

    void savePictures() async {
      setState(() {
        _isSaving = true;
      });
      final newFiles = await picturesFileService.savePictures(pictures);
      setState(() {
        _isSaving = false;
      });
      Navigator.of(context).pop();
    }

    return Scaffold(
      appBar: AppBar(title: Text("Add pictures")),
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
                icon: Icon(Icons.delete_forever),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: pictures.isNotEmpty || !_isSaving ? savePictures : null,
        label: Text('Add ${pictures.length} pictures'),
      ),
    );
  }
}
