import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PictureRectangle(
              null,
              width: double.infinity,
              height: double.infinity,
              borderRadius: 64,
              highlightColor: Theme.of(context).colorScheme.primary,
              highlight: true,
              aspectRatio: _controller.value.aspectRatio,
              emptyWidget: _controller.value.isInitialized
                  ? VideoPlayer(_controller)
                  : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 32),
            VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Theme.of(context).colorScheme.primary,
                bufferedColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: [
                IconButton.filledTonal(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  onPressed: () {
                    _controller.seekTo(Duration.zero);
                  },
                  icon: const FaIcon(FontAwesomeIcons.backwardFast),
                ),
                IconButton.filled(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  icon: FaIcon(
                    _controller.value.isPlaying
                        ? FontAwesomeIcons.pause
                        : FontAwesomeIcons.play,
                  ),
                ),
                IconButton.filledTonal(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  style: _controller.value.isLooping
                      ? IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        )
                      : null,
                  onPressed: () {
                    setState(() {
                      _controller.setLooping(!_controller.value.isLooping);
                    });
                  },
                  icon: FaIcon(
                    FontAwesomeIcons.repeat,
                    color: _controller.value.isLooping
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(),
    );
  }
}
