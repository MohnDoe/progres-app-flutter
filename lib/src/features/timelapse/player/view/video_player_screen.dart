import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:progres/src/core/services/video_service.dart';
import 'package:progres/src/core/ui/widgets/bottom_bar_button.dart';
import 'package:progres/src/core/ui/widgets/picture_rectangle.dart';
import 'package:progres/src/features/timelapse/_shared/repositories/timelapse_notifier.dart';
import 'package:progres/src/features/timelapse/configuration/views/timelapse_configuration_screen.dart';
import 'package:progres/src/features/timelapse/player/widgets/header_infos.dart';
import 'package:video_player/video_player.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

const kBottomBarSpacing = 4.0;

class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key});

  static const String name = 'timelapse-player';
  static const String path = '/timelapse';

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  bool _isDownloading = false;

  late String videoPath;

  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    final path = await VideoService().getVideoPath(
      ref.read(timelapseProvider.notifier).videoFilename,
    );
    setState(() {
      videoPath = path;
    });
    _controller = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        _controller?.play();
        _controller?.setLooping(true);
        // Ensure the first frame is shown after the video is initialized, even before the video is played.
        if (mounted) setState(() {});
      });
  }

  Future<void> _downloadVideo(String videoPath) async {
    setState(() {
      _isDownloading = true;
    });
    final filePath = await FileSaver.instance.saveFile(
      name: VideoService.kOutputVideoPrefix,
      file: File(videoPath),
      fileExtension: VideoService.kOutputVideoExt,
      mimeType: MimeType.mp4Video,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 5),
          content: const Text("Timelapse saved to gallery!"),
          action: SnackBarAction(
            label: "Open",
            onPressed: () {
              OpenFile.open(filePath);
            },
          ),
        ),
      );
    }
    setState(() {
      _isDownloading = false;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _shareVideo(String videoPath) async {
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
    Timelapse timelapse = ref.read(timelapseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timelapse'),
        actions: [
          IconButton(
            onPressed: () {
              context.goNamed(TimelapseConfigurationScreen.name);
            },
            icon: const FaIcon(FontAwesomeIcons.arrowRotateLeft),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HeaderInfos(timelapse: timelapse),
            // VIDEO
            Expanded(
              child: PictureRectangle(
                null,
                borderRadius: 64,
                highlightColor: Theme.of(context).colorScheme.primary,
                highlight: true,
                aspectRatio: _controller?.value.aspectRatio ?? 1,
                emptyWidget: _controller?.value.isInitialized ?? false
                    ? VideoPlayer(_controller!)
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            // Progress
            if (_controller != null)
              Column(
                spacing: 4,
                children: [
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                      playedColor: Theme.of(context).colorScheme.primary,
                      bufferedColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: _controller!,
                        builder: (context, VideoPlayerValue value, child) {
                          return Text(
                            _formatDuration(value.position),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                      Text(
                        _formatDuration(_controller!.value.duration),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            // VIDEO CONTROLS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: [
                IconButton.filledTonal(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  onPressed: () {
                    _controller?.seekTo(Duration.zero);
                  },
                  icon: const FaIcon(FontAwesomeIcons.backwardFast),
                ),
                IconButton.filled(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  onPressed: _controller != null && _controller!.value.isInitialized
                      ? () {
                          setState(() {
                            if (_controller?.value.isPlaying ?? false) {
                              _controller?.pause();
                            } else {
                              _controller?.play();
                            }
                          });
                        }
                      : null,
                  icon: FaIcon(
                    _controller?.value.isPlaying ?? false
                        ? FontAwesomeIcons.pause
                        : FontAwesomeIcons.solidPlay,
                  ),
                ),
                IconButton.filledTonal(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  style: _controller?.value.isLooping ?? false
                      ? IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
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
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomBarButton(
              onTap: () => _shareVideo(videoPath),
              icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 16),
              label: 'Share',
            ),
            BottomBarButton(
              onTap: !_isDownloading ? () => _downloadVideo(videoPath) : null,
              icon: _isDownloading
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : const FaIcon(FontAwesomeIcons.download, size: 16),
              label: 'Save',
            ),
            BottomBarButton(
              onTap: () => {},
              icon: const FaIcon(FontAwesomeIcons.sliders, size: 16),
              label: 'Edit',
            ),
          ],
        ),
      ),
    );
  }
}
