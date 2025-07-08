import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/repositories/picker/picker.dart';
import 'package:progres/src/features/entries/import/controllers/import_controller.dart';
import 'package:progres/src/features/entries/import/views/widgets/image_card.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  @override
  void initState() {
    super.initState();
    importPictures();
  }

  void importPictures() async {
    final List<ProgressPicture> selectedPictures = await Picker().pickImages();
    print(selectedPictures);
    for (ProgressPicture picture in selectedPictures) {
      ref.read(importControllerProvider.notifier).addProgressPicture(picture);
    }
  }

  @override
  Widget build(BuildContext context) {
    var temporaryImportItems = ref.watch(importControllerProvider);

    return ListView.builder(
      itemCount: temporaryImportItems.length,
      itemBuilder: (ctx, index) => ImageCard(
        picture: temporaryImportItems[index]['picture'] as ProgressPicture,
        date: temporaryImportItems[index]['date'] as DateTime,
      ),
    );
  }
}
