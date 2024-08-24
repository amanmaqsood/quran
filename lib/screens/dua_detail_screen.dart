import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../data/dua.dart'; 

class DuaDetailScreen extends StatefulWidget {
  final Dua dua;
  final int index;
  final int total;

  const DuaDetailScreen({
    super.key,
    required this.dua,
    required this.index,
    required this.total,
  });

  @override
  _DuaDetailScreenState createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> {
  Set<String> _favoriteDuas = {};
  ScreenshotController screenshotController = ScreenshotController();
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _pageController = PageController(initialPage: _currentIndex);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteDuas = prefs.getStringList('favoriteDuas')?.toSet() ?? {};
    });
  }

  void _toggleFavorite(String dua) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteDuas.contains(dua)) {
        _favoriteDuas.remove(dua);
      } else {
        _favoriteDuas.add(dua);
      }
      prefs.setStringList('favoriteDuas', _favoriteDuas.toList());
    });
  }

  void _captureAndSharePng() async {
    final customWidget = Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.dua.arabic,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'IndoPak',
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            widget.dua.transliteration,
            style: TextStyle(fontSize: 16, color: Colors.grey[300]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            widget.dua.translation,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (widget.dua.hadith != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("📓 ", style: TextStyle(fontSize: 20, color: Colors.white)),
                  Expanded(
                    child: Text(
                      widget.dua.hadith!,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final imageFile = await screenshotController.captureFromWidget(
      customWidget,
      delay: const Duration(milliseconds: 10),
    );

    final directory = (await getApplicationDocumentsDirectory()).path;
    final imagePath = '$directory/screenshot.png';
    final file = File(imagePath);
    await file.writeAsBytes(imageFile!);
    Share.shareXFiles([XFile(imagePath)], text: widget.dua.title);
  }

  void _updateTitle(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dua.title),
        actions: [
          IconButton(
            icon: Icon(_favoriteDuas.contains(widget.dua.title) ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              _toggleFavorite(widget.dua.title);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _captureAndSharePng,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.total,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 77, 145, 138)),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.total,
              onPageChanged: (index) {
                _updateTitle(index);
              },
              itemBuilder: (context, index) {
                final dua = widget.dua; // Fetch the dua corresponding to the index
                return _buildDuaDetail(context, dua);
              },
              physics: const BouncingScrollPhysics(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuaDetail(BuildContext context, Dua dua) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_currentIndex + 1}/${widget.total}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dua.arabic,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'IndoPak',
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dua.transliteration,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dua.translation,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  if (dua.hadith != null)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Text("📓 ", style: TextStyle(fontSize: 20)),
                          Expanded(
                            child: Text(
                              dua.hadith!,
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
