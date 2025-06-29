import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String pdfName;

  const PdfViewerScreen({
    super.key,
    required this.pdfName,
    required this.pdfPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  int _pageNumber = 1;
  int _totalPages = 0;

  @override
  void initState() {
    _pdfViewerController = PdfViewerController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('${widget.pdfName} ($_pageNumber / $_totalPages)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: () => _pdfViewerController.previousPage(),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward),
            onPressed: () => _pdfViewerController.nextPage(),
          ),
        ],
      ),
      body: SfPdfViewer.file(
        File(widget.pdfPath),
        controller: _pdfViewerController,
        enableTextSelection: true,
        onPageChanged: (details) {
          setState(() {
            _pageNumber = details.newPageNumber;
          });
        },
        onDocumentLoaded: (details) {
          setState(() {
            _totalPages = details.document.pages.count;
          });
        },
      ),
    );
  }
}
