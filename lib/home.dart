import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'setting-main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  FocusNode focusNode = FocusNode();
  final TextEditingController controller = TextEditingController();
  String? errorLoading;
  String displayNumber = '0000';
  Timer? _timer;
  Color _textColor = const Color.fromARGB(255, 242, 255, 0);
  Color selectedTextColor = const Color.fromARGB(255, 228, 151, 35);

  bool isPlaying = false;
  bool isFieldEnabled = true;

  List<File> filteredLogoList = [];
  List<File> logoList = [];

  late Box box;
  late Box boxmode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
    _requestExternalStoragePermission();
    _openBox();
  }

  Future<void> _openBox() async {
    await Hive.initFlutter();
    box = await Hive.openBox('settingsBox');
    boxmode = await Hive.openBox('ModeSounds');
    await loadSettings();
    box.listenable().addListener(() {
      loadSettings();
    });
    boxmode.listenable().addListener(() {
      loadSettings();
    });
    setState(() {});
  }

  Future<void> loadSettings() async {
    final usb = box.get('usbPath', defaultValue: '').toString();
    var boxmode = await Hive.openBox('ModeSounds');
    var mode = boxmode.values.first;
    setState(() {
      filteredLogoList =
          logoList.where((file) => file.path.endsWith("${mode}.png")).toList();
    });
    await loadLogoFromUSB();
  }

  Future<void> _requestExternalStoragePermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
    } else {
      setState(() {
        errorLoading = 'Permission denied for storage';
      });
    }
  }

  void _handleSubmitted(String value) async {
    if (isPlaying) {
      return;
    }
    value = value.replaceAll('-', '');
    setState(() {
      isFieldEnabled = false;
    });
    if (value == '*') {
      _handleMultiply();
    } else if (value == '/1234/') {
      controller.clear();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingMainScreen()),
      );
      _handleInvalidCharacter();
    } else if (value.contains == '/') {
      _handleMultiply();
    } else if (RegExp(r'^\d+$').hasMatch(value)) {
      if (value.length > 4) {
        value = value.substring(0, 4);
      }
      _handleNumericValue(value);
    } else if (value.startsWith("1") ||
        value.startsWith("2") ||
        value.startsWith("3") ||
        value.startsWith("4") ||
        value.startsWith("6") ||
        value.startsWith("5")) {
      int indexOfPlus = value.indexOf("+");
      if (indexOfPlus == -1) {
        _handleInvalidCharacter();
        setState(() {
          isFieldEnabled = true;
        });
      } else if (indexOfPlus > 0 && indexOfPlus == value.length - 1) {
        _handleInvalidCharacter();
      } else if (indexOfPlus > 1) {
        value = value[0] + value.substring(indexOfPlus);
        _handleNumericValue(value.toString());
      } else {
        _handleNumericValue(value.toString());
      }
    } else if (RegExp(r'[^\d+.*/]').hasMatch(value)) {
      _handleInvalidCharacter();
      setState(() {
        isFieldEnabled = true;
      });
    } else {
      _handleInvalidCharacter();
    }
  }

  void _handleMultiply() {
    setState(() {
      displayNumber = '0000';
      isFieldEnabled = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isFieldEnabled) {
        focusNode.requestFocus();
        controller.clear();
      }
    });
  }

  void _handleNumericValue(String value) async {
    if (RegExp(r'^\d+$').hasMatch(value)) {
      value = '1+$value';
    }
    await playSound(value);
  }

  Future<void> _addToHive(String mode) async {
    await boxmode.put('mode', mode);
    setState(() {});
  }

  Future<void> playSound(String value) async {
    try {
      final usb = box.get('usbPath', defaultValue: '').toString();
      var beforePlus = '';
      var afterPlus = '';

      final trimmedString = value.toString();
      final parts = trimmedString.split("+");

      if (parts.length == 2) {
        beforePlus = parts[0];
        afterPlus = parts[1].toString();
        if (afterPlus.length > 4) {
          afterPlus = afterPlus.substring(0, 4);
        }
      } else {
        print("Invalid format, '+' not found or extra characters");
      }

      setState(() {
        displayNumber = afterPlus;
      });

      await _addToHive(beforePlus);

      Directory? externalDir = await getExternalStorageDirectory();
      String usbPath = p.join(usb, 'sounds');
      Directory usbDir = Directory(usbPath);

      if (await usbDir.exists()) {
        Future<void> playAudioFile(String path) async {
          try {
            if (await File(path).exists()) {
              await audioPlayer.play(DeviceFileSource(path));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Audio file not found: $path'),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error playing audio file: $e'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }

        Future<void> playNumberSound(String number) async {
          for (int i = 0; i < number.length; i++) {
            await playAudioFile(p.join(usbPath, 'TH-NEW', '${number[i]}.mp3'));
            await audioPlayer.onPlayerStateChanged.firstWhere(
              (state) => state == PlayerState.completed,
            );
          }
        }

        if (beforePlus == '1') {
          filteredLogoList =
              logoList.where((file) => file.path.endsWith("1.png")).toList();
          runZoned(() async {
            await playAudioFile(p.join(usbPath, 'TITTLE', 'order.mp3'));
            // await audioPlayer.play(AssetSource('title/order.mp3'));
            await audioPlayer.onPlayerStateChanged.firstWhere(
              (state) => state == PlayerState.completed,
            );
            await playNumberSound(afterPlus);
          }, zoneSpecification: ZoneSpecification());
        } else if (beforePlus == '4') {
          // grab
          filteredLogoList =
              logoList.where((file) => file.path.endsWith("4.png")).toList();
          runZoned(() async {
            await playAudioFile(p.join(usbPath, 'TITTLE', 'grab.mp3'));
            // await audioPlayer.play(AssetSource('title/grab.mp3'));
            await audioPlayer.onPlayerStateChanged.firstWhere(
              (state) => state == PlayerState.completed,
            );
            await playNumberSound(afterPlus);
          }, zoneSpecification: ZoneSpecification());
        } else if (beforePlus == '3') {
          // line man
          filteredLogoList =
              logoList.where((file) => file.path.endsWith("3.png")).toList();
          runZoned(() async {
            await playAudioFile(p.join(usbPath, 'TITTLE', 'line.mp3'));
            // await audioPlayer.play(AssetSource('title/line.mp3'));
            await audioPlayer.onPlayerStateChanged.firstWhere(
              (state) => state == PlayerState.completed,
            );
            await playNumberSound(afterPlus);
          }, zoneSpecification: ZoneSpecification());
        } else if (beforePlus == '5') {
          // shopee
          filteredLogoList =
              logoList.where((file) => file.path.endsWith("5.png")).toList();
          runZoned(() async {
            await playAudioFile(p.join(usbPath, 'TITTLE', 'shop.mp3'));
            // await audioPlayer.play(AssetSource('title/shop.mp3'));
            await audioPlayer.onPlayerStateChanged.firstWhere(
              (state) => state == PlayerState.completed,
            );
            await playNumberSound(afterPlus);
          }, zoneSpecification: ZoneSpecification());
        } else if (beforePlus == '2') {
          // food
          filteredLogoList =
              logoList.where((file) => file.path.endsWith("2.png")).toList();
          runZoned(() async {
            await playAudioFile(p.join(usbPath, 'TITTLE', 'food.mp3'));
            // await audioPlayer.play(AssetSource('title/food.mp3'));
            await audioPlayer.onPlayerStateChanged.firstWhere(
              (state) => state == PlayerState.completed,
            );
            await playNumberSound(afterPlus);
          }, zoneSpecification: ZoneSpecification());
        } else if (beforePlus == '6') {
          // robin
          filteredLogoList =
              logoList.where((file) => file.path.endsWith("6.png")).toList();
          runZoned(() async {
            await playAudioFile(p.join(usbPath, 'TITTLE', 'robin.mp3'));
            // await audioPlayer.play(AssetSource('title/food.mp3'));
            await audioPlayer.onPlayerStateChanged.firstWhere(
              (state) => state == PlayerState.completed,
            );
            await playNumberSound(afterPlus);
          }, zoneSpecification: ZoneSpecification());
        } else {
          filteredLogoList =
              logoList.where((file) => file.path.endsWith("1.png")).toList();
          runZoned(() async {
            await playAudioFile(p.join(usbPath, 'TITTLE', 'order.mp3'));
            // await audioPlayer.play(AssetSource('title/order.mp3'));
            await audioPlayer.onPlayerStateChanged.firstWhere(
              (state) => state == PlayerState.completed,
            );
            await playNumberSound(afterPlus);
          }, zoneSpecification: ZoneSpecification());
        }

        setState(() {
          isFieldEnabled = true;
          controller.clear();
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('USB directory does not exist: $usbPath'),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          isFieldEnabled = true;
          controller.clear();
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });
      }
      _timer?.cancel();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {
        isFieldEnabled = true;
        controller.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
    }
  }

  Future<void> playNumberSound1(String number) async {
    for (int i = 0; i < number.length; i++) {
      await audioPlayer.play(AssetSource('th/${number[i]}.mp3'));
      await audioPlayer.onPlayerStateChanged.firstWhere(
        (state) => state == PlayerState.completed,
      );
    }
  }

  void startBlinking() {
    final color1 = box.get('color1', defaultValue: '');
    final color2 = box.get('color2', defaultValue: '');

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _textColor = _textColor == color1 ? color2 : color1;
      });
    });

    Timer(const Duration(seconds: 3), () {
      _timer?.cancel();
      setState(() {
        _textColor = color1;
      });
    });
  }

  void checkvalue(String value) async {
    if (isPlaying) {
      return;
    }
    if (value == '.') {
      setState(() {
        isFieldEnabled = false;
      });
      if (displayNumber == '0000' ||
          displayNumber == '000' ||
          displayNumber == '00' ||
          displayNumber == '0') {
        await Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {
            isFieldEnabled = true;
            controller.clear();
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            focusNode.requestFocus();
          });
        });
      } else {
        var boxmode = await Hive.openBox('ModeSounds');
        var mode = boxmode.values.first;
        int currentValue = int.tryParse(displayNumber) ?? 0;
        currentValue = (currentValue) % 10000;
        displayNumber = "$mode+${currentValue.toString()}";
        await playSound(displayNumber);
      }
    } else if (value == '+') {
      if (isPlaying) {
        return;
      }
      setState(() {
        isFieldEnabled = false;
      });
      handlePlus(value);
    }
  }

  void handlePlus(String value) async {
    var boxmode = await Hive.openBox('ModeSounds');
    var mode = boxmode.values.first;
    int currentValue = int.tryParse(displayNumber) ?? 0;
    currentValue = (currentValue + 1) % 10000;
    displayNumber = "$mode+${currentValue.toString()}";
    await playSound(displayNumber);
  }

  void _handleInvalidCharacter() {
    setState(() {
      isFieldEnabled = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isFieldEnabled) {
        focusNode.requestFocus();
        controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // คำนวณขนาดฟอนต์ตามขนาดหน้าจอ
    final double orderNumberFontSize =
        screenSize.height * 0.07; // เปลี่ยนเป็นค่าที่ต้องการ
    final double displayNumberFontSize =
        screenSize.height * 0.58; // เปลี่ยนเป็นค่าที่ต้องการ

    return GestureDetector(
      onTap: () {
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 15),
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredLogoList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Image.file(
                            filteredLogoList[index],
                            fit: BoxFit.fill,
                            alignment: Alignment.center,
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Stack(
                      alignment: Alignment.center, // จัดให้อยู่ตรงกลางตามแนวนอน
                      children: [
                        Align(
                          alignment: Alignment.topLeft, // ชิดด้านบนและซ้าย
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: screenSize.height *
                                  0.1, // ปรับระยะห่างจากด้านบนตามขนาดจอ
                              left: screenSize.width *
                                  0.05, // เพิ่มระยะห่างจากซ้ายเล็กน้อยตามขนาดจอ
                            ),
                            child: Text(
                              "Order Number",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: orderNumberFontSize,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment
                              .bottomCenter, // จัดให้อยู่ด้านล่างของ Stack
                          child: Text(
                            displayNumber,
                            style: TextStyle(
                              color: selectedTextColor,
                              fontSize: displayNumberFontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DIGITAL',
                              letterSpacing: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: controller,
                  onSubmitted: _handleSubmitted,
                  onChanged: (value) {
                    checkvalue(value);
                  },
                  keyboardType: TextInputType.text,
                  focusNode: focusNode,
                  maxLines: 1,
                  enabled: isFieldEnabled,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: "Enter Order Number",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadLogoFromUSB() async {
    final usb = box.get('usbPath', defaultValue: '').toString();

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await _requestExternalStoragePermission();
    }

    Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir == null) {
      throw 'External storage directory not found';
    }

    // USB directory path
    String usbPath = p.join(usb, 'logo');
    // String usbPath = '$usb/logo';
    Directory usbDir = Directory(usbPath);

    if (!usbDir.existsSync()) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          const duration = Duration(seconds: 2);
          Timer(duration, () {
            Navigator.of(context).pop();
          });
          return AlertDialog(
            title: Text(
              'USB directory does not exist: $usbPath',
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          );
        },
      );
      throw 'USB directory does not exist';
    }

    // Load files from USB directory
    List<FileSystemEntity> files = usbDir.listSync();
    if (files.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          const duration = Duration(seconds: 2);
          Timer(duration, () {
            Navigator.of(context).pop();
          });
          return const AlertDialog(
            title: Text(
              'No files found in USB directory',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          );
        },
      );
      throw 'No files found in USB directory';
    }

    List<File> logoFiles = files.whereType<File>().toList();
    if (logoFiles.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          const duration = Duration(seconds: 2);
          Timer(duration, () {
            Navigator.of(context).pop();
          });
          return const AlertDialog(
            title: Text(
              'No image files found in USB directory',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          );
        },
      );
      throw 'No image files found in USB directory';
    }

    setState(() {
      logoList = logoFiles;
    });
  }
}
