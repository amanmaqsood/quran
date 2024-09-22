import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioControlBar extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final Duration duration;
  final Duration position;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;
  final String surahName;
  final int verseNumber; // Dynamic verse number updated in real-time
  final bool isLoading;

  const AudioControlBar({
    super.key, 
    required this.audioPlayer,
    required this.duration,
    required this.position,
    required this.onPause,
    required this.onResume,
    required this.onSeekBackward,
    required this.onSeekForward,
    required this.surahName,
    required this.verseNumber,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                surahName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Verse: $verseNumber',  // Real-time verse update
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: position.inSeconds.toDouble(),
            min: 0.0,
            max: duration.inSeconds.toDouble(),
            onChanged: (value) {
              audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: onSeekBackward,
              ),
              isLoading
                  ? const CircularProgressIndicator()
                  : IconButton(
                      icon: Icon(audioPlayer.state == PlayerState.playing ? Icons.pause : Icons.play_arrow),
                      onPressed: audioPlayer.state == PlayerState.playing ? onPause : onResume,
                    ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: onSeekForward,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  audioPlayer.stop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
