import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/features/pictures/data/repositories/pictures_repository.dart';
import 'package:progres/src/features/pictures/presentation/list/widgets/bottom_sheet_selection.dart';

class ListPicturesScreen extends ConsumerStatefulWidget {
  const ListPicturesScreen({super.key});

  @override
  ConsumerState createState() => _ListPicturesScreenState();
}

class _ListPicturesScreenState extends ConsumerState<ListPicturesScreen> {
  bool _loading = true;
  @override
  void initState() {
    _init();
    super.initState();
  }

  void _init() async {
    setState(() {
      _loading = true;
    });
    await ref.read(userPicturesRepositoryProvider).initPictures();
    setState(() {
      _loading = false;
    });
  }

  void _displayPickOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return const BottomSheetSelection();
      },
    );
    _init();
  }

  @override
  Widget build(BuildContext context) {
    final UserPicturesRepository userPicturesRepository = ref.watch(
      userPicturesRepositoryProvider,
    );

    final pictures = userPicturesRepository.orderedPictures;

    return Scaffold(
      appBar: AppBar(
        title: Text("Pictures"),
        actions: [
          IconButton(onPressed: _displayPickOptions, icon: Icon(Icons.add)),
        ],
      ),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : ListView.builder(
                itemCount: pictures.length,
                itemBuilder: (BuildContext context, int index) {
                  final picture = pictures[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.file(picture.file, width: 50),
                      Text(picture.date.toString()),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
