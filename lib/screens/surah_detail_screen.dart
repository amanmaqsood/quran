import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../data/surahs.dart';
import '../widgets/surah_header.dart';
import '../widgets/audio_control_bar.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahIndex;
  final int initialAyat;
  final List<Surah> surahs;

  const SurahDetailScreen({super.key, required this.surahIndex, this.initialAyat = 1, required this.surahs});

  @override
  _SurahDetailScreenState createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  int _playingIndex = -1;
  int _globalVerseIndex = 0;  // Global verse index to track across files
  final ScrollController _scrollController = ScrollController();
  Set<String> _favoriteVerses = {};
  Set<int> _favoriteSurahs = {};
  ScreenshotController screenshotController = ScreenshotController();
  String _currentSurahTitle = '';
  final bool _deepMeaningExpanded = false;
  Duration _duration = const Duration();
  Duration _position = const Duration();
  String _currentSurahName = '';
  int _currentVerseNumber = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialSurah();
    _scrollController.addListener(_onScroll);
    _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_calculateInitialScrollOffset());
    });

    _audioPlayer.onDurationChanged.listen((Duration d) {
      if (mounted) {
        setState(() => _duration = d);
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      if (mounted) {
        setState(() {
          _position = p;
          _updateCurrentVerse();
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (!_isPlaying) {
            _isLoading = false;
          }
        });
      }
    });

    _currentSurahName = widget.surahs[widget.surahIndex].name;
  }

  void _loadInitialSurah() {
    setState(() {
      _currentSurahTitle = widget.surahs[widget.surahIndex].name;
    });
  }

  double _calculateInitialScrollOffset() {
    return (widget.initialAyat - 1) * 100.0;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentSurah();
    });
  }

  void _updateCurrentSurah() {
    // Do nothing here as we will handle it using VisibilityDetector
  }

  void _onVisibilityChanged(VisibilityInfo info, int surahIndex) {
    if (info.visibleFraction > 0.5) {
      if (mounted) {
        setState(() {
          _currentSurahTitle = widget.surahs[surahIndex].name;
        });
        _saveLastRead(surahIndex, (info.key as ValueKey<int>).value + 1);
      }
    }
  }

  _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _favoriteVerses = prefs.getStringList('favoriteVerses')?.toSet() ?? {};
        _favoriteSurahs = prefs.getStringList('favoriteSurahs')?.map(int.parse).toSet() ?? {};
      });
    }
  }

  _toggleFavoriteVerse(int surahIndex, int verseIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = '${widget.surahs[surahIndex].name} Verse ${verseIndex + 1}';
    if (_favoriteVerses.contains(key)) {
      _favoriteVerses.remove(key);
    } else {
      _favoriteVerses.add(key);
    }
    prefs.setStringList('favoriteVerses', _favoriteVerses.toList());
    if (mounted) {
      setState(() {});
    }
  }

  _toggleFavoriteSurah(int surahIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_favoriteSurahs.contains(surahIndex + 1)) {
      _favoriteSurahs.remove(surahIndex + 1);
    } else {
      _favoriteSurahs.add(surahIndex + 1);
    }
    prefs.setStringList('favoriteSurahs', _favoriteSurahs.map((e) => e.toString()).toList());
    if (mounted) {
      setState(() {});
    }
  }

  void _captureAndSharePng(Verse verse) async {
    final verseWidget = Screenshot(
      controller: screenshotController,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/background.jpg'), // Ensure you have this image in your assets
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Container()), // Spacer to push content to center
            Text(
              verse.arabic,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'IndoPak'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              verse.transliteration,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              verse.translation,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            Expanded(child: Container()), // Spacer to push content to center
            const Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Powered by Quran App',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final capturedImage = await screenshotController.captureFromWidget(verseWidget, delay: const Duration(milliseconds: 10));
      final directory = (await getApplicationDocumentsDirectory()).path;
      final imagePath = '$directory/shared_verse.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(capturedImage);

      Share.shareXFiles([XFile(imagePath)], text: 'Check out this verse from the Quran!');
    } catch (error) {
      print('Error capturing screenshot: $error');
    }
  }

  Future<String> _getAudioUrl(String fileName) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    try {
      String url = await storage.ref('audio/$fileName').getDownloadURL();
      return url;
    } catch (e) {
      print('Error getting audio URL: $e');
      return '';
    }
  }

  void _playSurahAudio(int surahIndex) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    String audioPath = 'surah_${surahIndex + 1}.mp3';
    String url = await _getAudioUrl(audioPath);
    if (url.isNotEmpty) {
      await _audioPlayer.play(UrlSource(url));
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _currentSurahName = widget.surahs[surahIndex].name;
          _currentVerseNumber = 1;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _playVerseAudio(int surahIndex, int verseIndex) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _globalVerseIndex = verseIndex; // Track the global verse index
      });
    }

    String audioFileName = _getAudioFileName(surahIndex, verseIndex);
    String url = await _getAudioUrl(audioFileName);

    if (url.isNotEmpty) {
      int startTimestamp = widget.surahs[surahIndex].verses[verseIndex].audioTimestamp ?? 0;
      await _audioPlayer.setSourceUrl(url);
      await _audioPlayer.seek(Duration(seconds: startTimestamp));
      await _audioPlayer.resume();
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _currentVerseNumber = verseIndex + 1;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getAudioFileName(int surahIndex, int verseIndex) {
    const int versesPerFile = 20;
    int fileNumber = (verseIndex ~/ versesPerFile) + 1;
    return 'surah_${surahIndex + 1}_$fileNumber.mp3';
  }

  _saveLastRead(int surahIndex, int ayatIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lastReadSurah', widget.surahs[surahIndex].name);
    prefs.setInt('lastReadAyat', ayatIndex);
  }

  _updateLastReadOnTap(int surahIndex, int ayatIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lastReadSurah', widget.surahs[surahIndex].name);
    prefs.setInt('lastReadAyat', ayatIndex);
  }

  _updateCurrentVerse() {
    final surah = widget.surahs[widget.surahIndex];
    for (int i = 0; i < surah.verses.length; i++) {
      if (i < surah.verses.length - 1) {
        if (_position.inSeconds >= surah.verses[i].audioTimestamp! &&
            _position.inSeconds < surah.verses[i + 1].audioTimestamp!) {
          if (mounted) {
            setState(() {
              _currentVerseNumber = _globalVerseIndex + 1;  // Use global verse index here
            });
          }
          break;
        }
      } else {
        if (_position.inSeconds >= surah.verses[i].audioTimestamp!) {
          if (mounted) {
            setState(() {
              _currentVerseNumber = _globalVerseIndex + 1;  // Use global verse index here
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> surahWidgets = [];
    for (int i = widget.surahIndex; i < widget.surahs.length; i++) {
      surahWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SurahHeader(
              name: widget.surahs[i].name,
              number: i + 1,
              type: widget.surahs[i].isMeccan ? 'Meccan' : 'Medinan',
              verses: widget.surahs[i].numberOfVerses,
              onPlay: () {
                _playSurahAudio(i);
              },
            ),
            if (i != 0 && i != 8)
              Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Image.asset(
                    'assets/bismillah_calligraphy.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: widget.surahs[i].verses.length,
              itemBuilder: (context, index) {
                String verseKey = '${widget.surahs[i].name} Verse ${index + 1}';
                bool isFavorite = _favoriteVerses.contains(verseKey);
                bool hasDeepMeaning = (widget.surahs[i].verses[index].deepMeaning ?? '').isNotEmpty;

                return VisibilityDetector(
                  key: ValueKey<int>(index),
                  onVisibilityChanged: (info) => _onVisibilityChanged(info, i),
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: VerseContainer(
                      verse: widget.surahs[i].verses[index],
                      verseNumber: index + 1,
                      isFavorite: isFavorite,
                      onFavoriteToggle: () => _toggleFavoriteVerse(i, index),
                      onPlayToggle: () async {
                        if (_isPlaying && _playingIndex == index) {
                          await _audioPlayer.pause();
                          setState(() {
                            _isPlaying = false;
                          });
                        } else {
                          _playVerseAudio(i, index);
                          _saveLastRead(i, index + 1);
                        }
                      },
                      onShare: () => _captureAndSharePng(widget.surahs[i].verses[index]),
                      onDropdownToggle: hasDeepMeaning
                          ? () {
                              setState(() {
                                widget.surahs[i].verses[index].deepMeaningExpanded =
                                    !widget.surahs[i].verses[index].deepMeaningExpanded;
                              });
                            }
                          : null,
                      deepMeaningExpanded: widget.surahs[i].verses[index].deepMeaningExpanded,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSurahTitle),
        actions: [
          IconButton(
            icon: Icon(
              _favoriteSurahs.contains(widget.surahIndex + 1) ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: () => _toggleFavoriteSurah(widget.surahIndex),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        children: surahWidgets,
      ),
      bottomNavigationBar: _isLoading || _isPlaying
          ? AudioControlBar(
              audioPlayer: _audioPlayer,
              duration: _duration,
              position: _position,
              onPause: () {
                _audioPlayer.pause();
                setState(() {
                  _isPlaying = false;
                });
              },
              onResume: () {
                _audioPlayer.resume();
                setState(() {
                  _isPlaying = true;
                });
              },
              onSeekBackward: () {
                _audioPlayer.seek(Duration(seconds: _position.inSeconds - 10));
              },
              onSeekForward: () {
                _audioPlayer.seek(Duration(seconds: _position.inSeconds + 10));
              },
              surahName: _currentSurahName,
              verseNumber: _currentVerseNumber,  // Display the global verse number
              isLoading: _isLoading,
            )
          : const SizedBox.shrink(),
    );
  }
}


class VerseContainer extends StatelessWidget {
  final Verse verse;
  final int verseNumber;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onPlayToggle;
  final VoidCallback onShare;
  final VoidCallback? onDropdownToggle;
  final bool deepMeaningExpanded;

  const VerseContainer({
    super.key,
    required this.verse,
    required this.verseNumber,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onPlayToggle,
    required this.onShare,
    this.onDropdownToggle,
    required this.deepMeaningExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                verse.arabic,
                style: const TextStyle(fontSize: 30, color: Colors.black87, fontFamily: 'IndoPak'),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const Divider(thickness: 1),
          Text(
            verse.transliteration,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.left,
          ),
          const Divider(thickness: 1),
          Text(
            verse.translation,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.left,
          ),
          const Divider(thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verse $verseNumber',
                style: const TextStyle(color: Colors.black45),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: onPlayToggle,
                  ),
                  IconButton(
                    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                    onPressed: onFavoriteToggle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: onShare,
                  ),
                  if (onDropdownToggle != null)
                    IconButton(
                      icon: Icon(
                        deepMeaningExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: Colors.blue,
                      ),
                      onPressed: onDropdownToggle,
                    ),
                ],
              ),
            ],
          ),
          if (deepMeaningExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: Text(
                verse.deepMeaning ?? 'No deep meaning available.',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.left,
              ),
            ),
        ],
      ),
    );
  }
}


// class AudioPlayerControl extends StatelessWidget {
//   final AudioPlayer audioPlayer;
//   final VoidCallback onPause;
//   final VoidCallback onResume;

//   const AudioPlayerControl({super.key, 
//     required this.audioPlayer,
//     required this.onPause,
//     required this.onResume,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         IconButton(
//           icon: const Icon(Icons.pause),
//           onPressed: onPause,
//         ),
//         StreamBuilder<Duration>(
//           stream: audioPlayer.onPositionChanged,
//           builder: (context, snapshot) {
//             final duration = snapshot.data ?? Duration.zero;
//             return Text('${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}');
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.play_arrow),
//           onPressed: onResume,
//         ),
//       ],
//     );
//   }
// }
