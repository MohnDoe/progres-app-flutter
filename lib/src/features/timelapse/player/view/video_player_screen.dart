import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progres/src/core/services/video_service.dart';
import 'package:progres/src/core/ui/widgets/picture_rectangle.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

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

  bool _isDownloading = false;

  VideoPlayerController? _controller;

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
        _controller?.play();
        _controller?.setLooping(true);
        // Ensure the first frame is shown after the video is initialized, even before the video is played.
        if (mounted) setState(() {});
      });
  }

  Future<void> _downloadVideo() async {
    setState(() {
      _isDownloading = true;
    });
    await FileSaver.instance.saveFile(
      name: "${VideoService.kOutputVideoPrefix}_front",
      file: File(videoPath),
      fileExtension: VideoService.kOutputVideoExt,
      mimeType: MimeType.mp4Video,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Video saved to gallery")));
    }
    setState(() {
      _isDownloading = false;
    });
  }

  Future<void> _shareVideo() async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Body timelapse video',
        files: [XFile(videoPath)],
        previewThumbnail: XFile(videoPath),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
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
              aspectRatio: _controller?.value.aspectRatio ?? 1,
              emptyWidget: _controller?.value.isInitialized ?? false
                  ? VideoPlayer(_controller!)
                  : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 32),
            if (_controller != null)
              VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLow,
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
                    _controller?.seekTo(Duration.zero);
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
                      if (_controller?.value.isPlaying ?? false) {
                        _controller?.pause();
                      } else {
                        _controller?.play();
                      }
                    });
                  },
                  icon: FaIcon(
                    _controller?.value.isPlaying ?? false
                        ? FontAwesomeIcons.solidPause
                        : FontAwesomeIcons.play,
                  ),
                ),
                IconButton.filledTonal(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  style: _controller?.value.isLooping ?? false
                      ? IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        )
                      : null,
                  onPressed: () {
                    setState(() {
                      final isLooping = _controller?.value.isLooping ?? false;
                      _controller?.setLooping(!isLooping);
                    });
                  },
                  icon: FaIcon(
                    _controller?.value.isLooping ?? false
                        ? FontAwesomeIcons.solidRepeat1
                        : FontAwesomeIcons.solidRepeat,
                    color: _controller?.value.isLooping ?? false
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              icon: _isDownloading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
              label: Text(!_isDownloading ? "Save to gallery" : "Saving..."),
              onPressed: !_isDownloading ? _downloadVideo : null,
            ),
            IconButton(
              iconSize: 16,
              icon: const FaIcon(FontAwesomeIcons.arrowUpFromBracket),
              onPressed: _shareVideo,
            ),
          ],
        ),
      ),
    );
  }
}
