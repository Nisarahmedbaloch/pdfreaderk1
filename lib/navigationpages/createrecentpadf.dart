import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path; // Add this import at the top
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart'; // Add this for opening the PDF

class CreatePdfScreen extends StatefulWidget {
  const CreatePdfScreen({super.key});

  @override
  State<CreatePdfScreen> createState() => _CreatePdfScreenState();
}

class _CreatePdfScreenState extends State<CreatePdfScreen> {
  final List<File> _images = [];
  final picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    PermissionStatus status;

    // Handle permissions based on source and Android version
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        _showPermissionDeniedSnackBar("Camera permission is required.");
        return;
      }
    } else if (source == ImageSource.gallery) {
      if (Platform.isAndroid) {
        // For Android 13 (API 33) and above, use READ_MEDIA_IMAGES
        if (Theme.of(context).platform == TargetPlatform.android &&
            (await Permission.photos.request()).isGranted || // For Android 13+
            (await Permission.storage.request()).isGranted) { // For Android 12-
          status = PermissionStatus.granted;
        } else {
          status = await Permission.photos.request();
        }
      } else {
        // For iOS, simply request photos permission
        status = await Permission.photos.request();
      }

      if (status != PermissionStatus.granted) {
        _showPermissionDeniedSnackBar("Gallery permission is required.");
        return;
      }
    }

    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    }
  }

  void _showPermissionDeniedSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: "Settings",
            onPressed: () => openAppSettings(), // Opens app settings for manual permission grant
          ),
        ),
      );
    }
  }

  Future<void> _createPdf() async {
    if (_images.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select images to create a PDF.")),
        );
      }
      return;
    }

    final pdf = pw.Document();

    for (var img in _images) {
      final image = pw.MemoryImage(img.readAsBytesSync());
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Center(child: pw.Image(image)),
        ),
      );
    }

    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter PDF Name"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "e.g., MyDocument"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _savePdf(pdf, nameController.text.trim());
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePdf(pw.Document pdf, String fileName) async {
    if (fileName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF name cannot be empty.")),
        );
      }
      return;
    }

    try {
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        // For Android, use the public Downloads folder
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // For iOS, use the app's documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final filePath = path.join(downloadsDir!.path, '$fileName.pdf');
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF saved: $filePath"),
            action: SnackBarAction(
              label: "Open",
              onPressed: () async {
                await OpenFilex.open(filePath);
              },
            ),
          ),
        );
        setState(() => _images.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving PDF: $e")),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showImagePickerOptions(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Add Images for PDF", style: TextStyle(fontSize: 20)),
            ),
            if (_images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Image.file(
                      _images[index],
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            if (_images.isNotEmpty)
              ElevatedButton(
                onPressed: _createPdf,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Generate PDF", style: TextStyle(fontSize: 20)),
              ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text("Take Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Pick From Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}