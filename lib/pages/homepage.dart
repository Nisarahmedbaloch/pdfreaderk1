import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:pdfreaderk/pages/pdf_viewer_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final List<String> _pdfFile = [];
  List<String> _filteredFile = [];
  List<String> _favoriteFiles = [];
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    requestStoragePermissionAndLoad();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteFiles = prefs.getStringList("favorite_pdfs") ?? [];
  }

  Future<void> toggleFavorite(String file) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteFiles.contains(file)) {
        _favoriteFiles.remove(file);
      } else {
        _favoriteFiles.add(file);
      }
    });
    await prefs.setStringList("favorite_pdfs", _favoriteFiles);
  }

  Future<void> requestStoragePermissionAndLoad() async {
    final storage = await Permission.storage.request();
    final manage = await Permission.manageExternalStorage.request();
    if (storage.isGranted || manage.isGranted) {
      final rootPath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOAD);
      await getFiles(rootPath);
    } else {
      openAppSettings();
    }
  }

  Future<void> getFiles(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) return;

      final entities = dir.listSync(recursive: true);
      _pdfFile.clear();

      for (var entity in entities) {
        if (entity is File && entity.path.endsWith(".pdf")) {
          _pdfFile.add(entity.path);
        }
      }

      setState(() {
        _filteredFile = List.from(_pdfFile);
        _isLoading = false;
      });
    } catch (e) {
      print("Error reading files: $e");
    }
  }

  Future<void> addToRecent(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentList = prefs.getStringList("recent_pdfs") ?? [];
    recentList.remove(filePath);
    recentList.insert(0, filePath);
    if (recentList.length > 10) {
      recentList = recentList.sublist(0, 10);
    }
    await prefs.setStringList("recent_pdfs", recentList);
  }

  void _filterFiles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFile = _pdfFile;
      } else {
        _filteredFile = _pdfFile
            .where((file) =>
            path.basename(file).toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: !_isSearching
            ? const Text(
          "Pdf Reader",
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        )
            : TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search PDF...",
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
          ),
          onChanged: _filterFiles,
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.cancel : Icons.search, color: Colors.white, size: 40),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _filteredFile = _pdfFile;
              });
            },
          ),
        ],
      ),



      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredFile.isEmpty
          ? const Center(
          child: Text("No PDF files found",
              style: TextStyle(color: Colors.white)))
          : ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredFile.length,
        itemBuilder: (context, index) {
          final filePath = _filteredFile[index];
          final fileName = path.basename(filePath);
          final isFav = _favoriteFiles.contains(filePath);
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onLongPress: () => showOptions(filePath),
              title: Text(
                fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.picture_as_pdf,
                  color: Colors.redAccent, size: 30),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isFav
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                      isFav ? Colors.red : Colors.grey,
                    ),
                    onPressed: () {
                      toggleFavorite(filePath);
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'rename') {
                        TextEditingController controller =
                        TextEditingController();
                        controller.text =
                            path.basenameWithoutExtension(filePath);
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Rename PDF"),
                            content: TextField(
                                controller: controller),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  final newPath = path.join(
                                      path.dirname(filePath),
                                      "${controller.text}.pdf");
                                  await File(filePath)
                                      .rename(newPath);
                                  await getFiles(
                                      path.dirname(filePath));
                                  Navigator.pop(context);
                                },
                                child: const Text("Rename"),
                              )
                            ],
                          ),
                        );
                      } else if (value == 'share') {
                        Share.shareXFiles(
                          [XFile(filePath)],
                          text: 'Check out this PDF!',
                        );
                      }
                        // Add share logic here (optional)
                       else if (value == 'delete') {
                        File(filePath).deleteSync();
                        await getFiles(path.dirname(filePath));
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename')),
                      const PopupMenuItem(
                          value: 'share',
                          child: Text('Share')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete')),
                    ],
                  )
                ],
              ),
              onTap: () async {
                await addToRecent(filePath);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
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

  void showOptions(String filePath) {
    showModalBottomSheet(
        context: context,
        builder: (_) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              children: [
                ListTile(
                    leading:
                    const Icon(Icons.drive_file_rename_outline),
                    title: const Text("Rename"),
                    onTap: () async {
                      Navigator.pop(context);
                      TextEditingController controller =
                      TextEditingController();
                      controller.text =
                          path.basenameWithoutExtension(filePath);
                      showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: const Text("Rename PDF"),
                              content: TextField(controller: controller),
                              actions: [
                                TextButton(
                                    onPressed: () async {
                                      final newPath = path.join(
                                          path.dirname(filePath),
                                          "${controller.text}.pdf");
                                      File(filePath).renameSync(newPath);
                                      await getFiles(path.dirname(filePath));
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Rename"))
                              ],
                            );
                          });
                    }),
                ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text("Share"),
                    onTap: () {
                      Navigator.pop(context);
                      // Add share logic here if needed
                    }),
                ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text("Delete"),
                    onTap: () async {
                      File(filePath).deleteSync();
                      await getFiles(path.dirname(filePath));
                      Navigator.pop(context);
                    }),
              ],
            ),
          );
        });
  }
}
