import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:get/get.dart';

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
      body: SizedBox.expand(
        child: Stack(
          children: [
            SizedBox.expand(
              child: Image.asset(
                'assets/img/canvas.png',
                fit: BoxFit.cover,
              ),
            ),
            SmartRefresher(
              controller: _refreshController,
              enablePullDown: true,
              enablePullUp: false,
              onLoading: onLoading,
              onRefresh: onResresh,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 150,
                    ),
                    Text(
                      "Text Recognizer",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[400],
                      ),
                    ),
                    Text(
                      "with Machine Learning",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.deepPurple[400],
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    if (textScanning) const CircularProgressIndicator(),
                    if (!textScanning && imageFile == null)
                      InkWell(
                        onTap: () {
                          Get.defaultDialog(
                            title: "Select Image",
                            content: Column(
                              children: [
                                ListTile(
                                  onTap: () {
                                    getImage(ImageSource.camera);
                                    Get.back();
                                  },
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text("Camera"),
                                ),
                                ListTile(
                                  onTap: () {
                                    getImage(ImageSource.gallery);
                                    Get.back();
                                  },
                                  leading: const Icon(Icons.image),
                                  title: const Text("Gallery"),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(250),
                            border: Border.all(
                              color: Colors.deepPurple[200]!,
                              width: 10,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 210,
                              height: 210,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(210),
                                color: Colors.deepPurple[200],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image_rounded,
                                  size: 130,
                                  weight: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (imageFile != null) Image.file(File(imageFile!.path)),
                    const SizedBox(
                      height: 16,
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
                                    (value) => ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text("Copied to clipboard"),
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.copy,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
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
          ],
        ),
      ),
    );
  }
}
