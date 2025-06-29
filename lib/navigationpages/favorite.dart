import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:pdfreaderk/pages/pdf_viewer_screen.dart';
import 'package:path/path.dart' as path;

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<String> favorites = [];

  @override
  void initState() {
    super.initState();
    loadFav();
  }

  Future<void> loadFav() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList("favorite_pdfs") ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: favorites.isEmpty
          ? const Center(child: Text("No favorites yet", style: TextStyle(color: Colors.white)))
          : ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final filePath = favorites[index];
          final fileName = path.basename(filePath);
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(fileName),
              leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      pdfName: fileName,
                      pdfPath: filePath,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
