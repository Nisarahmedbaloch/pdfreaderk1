import 'package:flutter/material.dart';
import 'package:pdfreaderk/pages/pdf_viewer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:path/path.dart' as path;

class RecentPdfScreen extends StatefulWidget {
  const RecentPdfScreen({super.key});

  @override
  State<RecentPdfScreen> createState() => _RecentPdfScreenState();
}

class _RecentPdfScreenState extends State<RecentPdfScreen> {
  List<String> recentPdfs = [];

  @override
  void initState() {
    super.initState();
    loadRecentPdfs();
  }

  Future<void> loadRecentPdfs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("recent_pdfs") ?? [];
    setState(() {
      recentPdfs = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: recentPdfs.isEmpty
          ? const Center(
        child: Text(
          "No recent PDFs",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      )
          : ListView.builder(
        itemCount: recentPdfs.length,
        itemBuilder: (context, index) {
          String filePath = recentPdfs[index];
          String fileName = path.basename(filePath);
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                fileName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              leading: const Icon(
                Icons.picture_as_pdf,
                color: Colors.redAccent,
                size: 30,
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
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
}
