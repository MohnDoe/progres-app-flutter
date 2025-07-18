import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progres/src/core/services/video_service.dart';
import 'package:progres/src/core/ui/widgets/picture_rectangle.dart';
import 'package:video_player/video_player.dart';

import 'package:path/path.dart' as p;

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.videoPath});

  static const String name = 'timelapse-player';
  static const String path = '/timelapse';

  final String videoPath;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late String videoPath;

  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    videoPath = p.join(
      (await getTemporaryDirectory()).path,
      "${VideoService.kOutputVideoPrefix}_front.${VideoService.kOutputVideoExt}",
    );

    _controller = VideoPlayerController.file(File(videoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _controller.value.isInitialized
                ? Material(
                    child: PictureRectangle(
                      null,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 64,
                      highlightColor: Theme.of(context).colorScheme.primary,
                      highlight: true,
                      emptyWidget: VideoPlayer(_controller),
                    ),
                  )
                : const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
