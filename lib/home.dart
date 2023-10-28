import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool textScanning = false;

  XFile? imageFile;

  String scannedText = "";

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        textScanning = true;
        imageFile = pickedImage;
        setState(() {});
        getRecognisedText(pickedImage);
      }
    } catch (e) {
      textScanning = false;
      imageFile = null;
      scannedText = "Error occured while scanning";
      setState(() {});
    }
  }

  void getRecognisedText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    RecognizedText recognisedText = await textDetector.processImage(inputImage);
    await textDetector.close();
    scannedText = "";
    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        scannedText = scannedText + line.text + "\n";
      }
    }
    textScanning = false;
    setState(() {});
  }

  void onResresh() {
    // monitor network fetch
    setState(() {
      textScanning = false;
      imageFile = null;
      scannedText = "";
    });
    _refreshController.refreshCompleted();
  }

  void onLoading() {
    // monitor network fetch
    setState(() {
      textScanning = false;
      imageFile = null;
      scannedText = "";
    });
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ML Text Recognize'), centerTitle: true),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: false,
        onLoading: onLoading,
        onRefresh: onResresh,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              if (textScanning) const CircularProgressIndicator(),
              if (!textScanning && imageFile == null)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                  ),
                ),
              if (imageFile != null) Image.file(File(imageFile!.path)),
              const SizedBox(
                height: 16,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          getImage(ImageSource.camera);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt),
                            SizedBox(width: 8),
                            Text('Camera'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          getImage(ImageSource.gallery);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.image),
                            SizedBox(width: 8),
                            Text('Gallery'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              if (scannedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: Stack(
                    children: [
                      Text(
                        scannedText,
                        style: TextStyle(fontSize: 18),
                      ),
                      Positioned(
                        right: 1,
                        top: 1,
                        child: IconButton(
                            onPressed: () {
                              FlutterClipboard.copy(scannedText).then(
                                (value) =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Copied to clipboard"),
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary,),),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
