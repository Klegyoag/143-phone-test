import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoMessagePlayer extends StatefulWidget {
  const VideoMessagePlayer({super.key, required this.url});
  final String url;

  @override
  State<VideoMessagePlayer> createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends State<VideoMessagePlayer> {
  late final VideoPlayerController controller;
  late final Future<void> ready;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    ready = controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: ready,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(width: 230, height: 150, child: Center(child: CircularProgressIndicator()));
          }
          return GestureDetector(
            onTap: () => setState(() => controller.value.isPlaying ? controller.pause() : controller.play()),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio, child: VideoPlayer(controller)),
                  if (!controller.value.isPlaying)
                    const CircleAvatar(radius: 24, backgroundColor: Colors.black54, child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32)),
                ],
              ),
            ),
          );
        },
      );
}
