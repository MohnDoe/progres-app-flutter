import 'dart:io';

import 'package:flutter/material.dart';
import 'package:progres/src/core/ui/widgets/picture_rectangle.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.videoPath});

  static const String name = 'timelapse-player';
  static const String path = '/timelapse';

  final String videoPath;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
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
    return Center(
      child: _controller.value.isInitialized
          ? Material(
              child: PictureRectangle(
                null,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 64,
                highlight: true,
                emptyWidget: VideoPlayer(_controller),
              ),
            )
          : const CircularProgressIndicator(),
    );
  }
}
