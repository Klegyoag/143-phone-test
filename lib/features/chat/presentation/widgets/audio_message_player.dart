import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioMessagePlayer extends StatefulWidget {
  const AudioMessagePlayer({super.key, required this.url, required this.foreground});
  final String url;
  final Color foreground;

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final player = AudioPlayer();
  bool prepared = false;
  bool busy = false;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (!prepared) {
        await player.setUrl(widget.url);
        prepared = true;
      }
      if (player.playing) {
        await player.pause();
      } else {
        if (player.processingState == ProcessingState.completed) await player.seek(Duration.zero);
        await player.play();
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String durationText(Duration? value) {
    final d = value ?? Duration.zero;
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<PlayerState>(
        stream: player.playerStateStream,
        builder: (context, state) {
          final playing = state.data?.playing == true;
          return SizedBox(
            width: 220,
            child: Row(
              children: [
                IconButton(
                  onPressed: toggle,
                  icon: busy
                      ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: widget.foreground))
                      : Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: widget.foreground),
                ),
                Expanded(
                  child: StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, p) => StreamBuilder<Duration?>(
                      stream: player.durationStream,
                      builder: (context, total) {
                        final max = (total.data?.inMilliseconds ?? 1).toDouble().clamp(1.0, double.infinity).toDouble();
                        final value = (p.data?.inMilliseconds ?? 0).toDouble().clamp(0.0, max).toDouble();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Slider(
                              value: value,
                              max: max,
                              onChanged: prepared ? (v) => player.seek(Duration(milliseconds: v.round())) : null,
                            ),
                            Text('${durationText(p.data)} / ${durationText(total.data)}', style: TextStyle(fontSize: 10, color: widget.foreground.withValues(alpha: .78))),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
