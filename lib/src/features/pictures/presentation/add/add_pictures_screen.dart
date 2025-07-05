import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progres/src/features/pictures/data/pictures_repository.dart';
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
    final PicturesRepository picturesRepository = ref.watch(
      picturesRepositoryProvider,
    );
    final pictures = picturesRepository.orderedPictures();

    void removePicture(ProgressPicture picture) {
      setState(() {
        picturesRepository.removePicture(picture);
      });
    }

    void submitPictures() {}

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
        onPressed: () {},
        label: Text('Add ${pictures.length} pictures'),
      ),
    );
  }
}
