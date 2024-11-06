import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

class TabSoundScreen extends StatefulWidget {
  const TabSoundScreen({super.key});

  @override
  _TabSoundScreenState createState() => _TabSoundScreenState();
}

class _TabSoundScreenState extends State<TabSoundScreen> {
  final TextEditingController textController = TextEditingController();
  final TextEditingController speakerController = TextEditingController();
  final TextEditingController volumeController = TextEditingController();
  final TextEditingController speedController = TextEditingController();
  final TextEditingController typeMediaController = TextEditingController();
  final TextEditingController saveFileController = TextEditingController();
  final TextEditingController languageController = TextEditingController();

  final Dio _dio = Dio();

  List<String> generatedList = [];

  String? latestAudioUrl;
  List<Map<String, String>> audioItems = [];

  // String convertNumberToThaiWord(int number) {
  //   const thaiNumbers = [
  //     'ศูนย์',
  //     'หนึ่ง',
  //     'สอง',
  //     'สาม',
  //     'สี่',
  //     'ห้า',
  //     'หก',
  //     'เจ็ด',
  //     'แปด',
  //     'เก้า',
  //     'สิบ',
  //     'สิบเอ็ด',
  //     'สิบสอง',
  //     'สิบสาม',
  //     'สิบสี่',
  //     'สิบห้า',
  //     'สิบหก',
  //     'สิบเจ็ด',
  //     'สิบแปด',
  //     'สิบเก้า',
  //     'ยี่สิบ',
  //     'สามสิบ',
  //     'สี่สิบ',
  //     'ห้าสิบ',
  //     'หกสิบ',
  //     'เจ็ดสิบ',
  //     'แปดสิบ',
  //     'เก้าสิบ'
  //   ];

  //   if (number == 0) return thaiNumbers[0];
  //   if (number < 10) return thaiNumbers[number];

  //   if (number < 20) {
  //     if (number == 11) return 'สิบเอ็ด'; // ใช้ "เอ็ด" สำหรับ 11
  //     return thaiNumbers[10] +
  //         (number == 12 ? 'สอง' : thaiNumbers[number % 10]);
  //   }

  //   if (number < 100) {
  //     String tens =
  //         thaiNumbers[number ~/ 10 + 18]; // ใช้ค่าที่ถูกต้องสำหรับ 10-90
  //     if (number % 10 == 0) return tens; // ไม่มีตัวเลขท้าย
  //     if (number % 10 == 1) return tens + 'เอ็ด'; // 1 ใช้ "เอ็ด"
  //     return tens + thaiNumbers[number % 10]; // ตัวเลขอื่นๆ
  //   }

  //   if (number < 1000) {
  //     int hundreds = number ~/ 100;
  //     int remainder = number % 100;

  //     String hundredPart = hundreds > 1
  //         ? thaiNumbers[hundreds] + 'ร้อย'
  //         : 'หนึ่งร้อย'; // สำหรับกรณี 100 เป็น "หนึ่งร้อย"

  //     // แสดงผลเศษ
  //     if (remainder == 0) return hundredPart; // ถ้ามีแค่ร้อย
  //     if (remainder == 1) return hundredPart + 'เอ็ด'; // 101
  //     if (remainder < 10)
  //       return hundredPart + thaiNumbers[remainder]; // 102 ถึง 109
  //     return hundredPart +
  //         convertNumberToThaiWord(remainder); // สำหรับเลขที่เหลือ
  //   }

  //   return number.toString(); // สำหรับเลขที่มากกว่า 999
  // }

  void _generateListThai() async {
    String inputText = textController.text;

    // Regular expression to match the pattern "เชิญหมายเลข 0, 1, 2, ... ค่ะ"
    RegExp regExp = RegExp(r"(.*?)(\d+)(?:,\s*\.\.\.\s*)(.*)");
    Match? match = regExp.firstMatch(inputText);

    if (match != null) {
      String baseText = match.group(1)!.trim(); // "เชิญหมายเลข"
      int start = int.parse(match.group(2)!); // 0
      String endText = match.group(3)!.trim(); // "ค่ะ"

      // สร้างลิสต์เพื่อเก็บหมายเลขที่ต้องการแปลง
      List<String> tempList = [];

      // สร้างหมายเลขตั้งแต่ start จนถึง 9
      for (int number = start; number <= 9; number++) {
        String thaiNumber = convertNumberToThaiWord(number);
        tempList.add("$baseText $thaiNumber $endText");
      }

      // บันทึกข้อมูลแต่ละรายการ
      for (String item in tempList) {
        await _saveSettings(item); // ใช้ await เพื่อรอแต่ละคำขอ
      }

      setState(() {
        generatedList = tempList; // อัพเดต generatedList
      });
    } else {
      setState(() {
        generatedList = [inputText]; // แสดงข้อความเดิมถ้าไม่ตรงกับรูปแบบ
      });
    }
  }

  String convertNumberToThaiWord(int number) {
    // สร้างลิสต์ของคำในภาษาไทยสำหรับหมายเลข 0 ถึง 9
    const List<String> thaiNumbers = [
      'ศูนย์', // 0
      'หนึ่ง', // 1
      'สอง', // 2
      'สาม', // 3
      'สี่', // 4
      'ห้า', // 5
      'หก', // 6
      'เจ็ด', // 7
      'แปด', // 8
      'เก้า' // 9
    ];

    // ตรวจสอบว่า number อยู่ในช่วงที่สามารถแปลงได้
    if (number < 0 || number > 9) {
      throw Exception("Number must be between 0 and 9");
    }

    // คืนค่าคำที่แปลงจากลิสต์
    return thaiNumbers[number];
  }

  // String convertNumberToThaiWord1(int number) {
  //   const thaiNumbers = [
  //     'ศูนย์',
  //     'หนึ่ง',
  //     'สอง',
  //     'สาม',
  //     'สี่',
  //     'ห้า',
  //     'หก',
  //     'เจ็ด',
  //     'แปด',
  //     'เก้า',
  //     'สิบ',
  //   ];

  //   if (number == 0) return thaiNumbers[0];

  //   if (number < 10) return thaiNumbers[number];

  //   if (number < 20) {
  //     if (number == 11) return 'สิบเอ็ด'; // ใช้ "เอ็ด" สำหรับ 11
  //     return thaiNumbers[10] +
  //         (number == 12 ? 'สอง' : thaiNumbers[number % 10]);
  //   }

  //   if (number < 100) {
  //     if (number == 21) return 'ยี่สิบเอ็ด'; // ใช้ "เอ็ด" สำหรับ 21
  //     String tens = thaiNumbers[number ~/ 10];
  //     if (number % 10 == 0) return tens + 'สิบ'; // สำหรับเลขที่ไม่มีตัวเลขท้าย
  //     if (number % 10 == 1) return tens + 'สิบเอ็ด'; // สำหรับเลขที่ลงท้ายด้วย 1
  //     return tens + 'สิบ' + thaiNumbers[number % 10]; // ตัวเลขอื่นๆ
  //   }

  //   if (number < 1000) {
  //     int hundreds = number ~/ 100;
  //     int remainder = number % 100;

  //     String hundredPart = hundreds > 1
  //         ? thaiNumbers[hundreds] + 'ร้อย'
  //         : 'ร้อย'; // สำหรับกรณี 100 เป็น "ร้อย"
  //     String remainderPart =
  //         remainder > 0 ? convertNumberToThaiWord(remainder) : '';

  //     return hundredPart + remainderPart;
  //   }

  //   return number.toString(); // สำหรับเลขที่มากกว่า 999
  // }

  // void _generateListThai1() async {
  //   String inputText = textController.text;

  //   // Regular expression to match both single number and number ranges
  //   RegExp regExp = RegExp(r"(.*?)(\d+)(?:-(\d+))?(.*)");
  //   Match? match = regExp.firstMatch(inputText);

  //   if (match != null) {
  //     String baseText = match.group(1)!.trim(); // "เชิญหมายเลข"
  //     int start = int.parse(match.group(2)!); // 572
  //     String endText = match.group(4)!.trim(); // "ค่ะ"

  //     // Check if it's a range or a single number
  //     int end = match.group(3) != null ? int.parse(match.group(3)!) : start;

  //     // Generate the list based on the range or single number
  //     List<String> tempList = List.generate(
  //       end - start + 1,
  //       (index) {
  //         String thaiNumber = convertNumberToThaiWord(start + index);
  //         return "$baseText $thaiNumber $endText";
  //       },
  //     );

  //     // for (String item in tempList) {
  //     //   await _saveSettings(item); // Use await to wait for each request
  //     // }

  //     setState(() {
  //       generatedList = tempList;
  //     });
  //   } else {
  //     setState(() {
  //       generatedList = [inputText];
  //     });
  //   }
  // }

  void _generateListEnglish() async {
    String inputText = textController.text;

    // Regular expression to match both single number and number ranges
    RegExp regExp = RegExp(r"(.*?)(\d+)(?:-(\d+))?(.*)");
    Match? match = regExp.firstMatch(inputText);

    if (match != null) {
      String baseText = match.group(1)!.trim(); // "PleaseNumber"
      int start = int.parse(match.group(2)!); // Start number (e.g. 0)

      // Check if it's a range or a single number
      int end = match.group(3) != null ? int.parse(match.group(3)!) : start;

      // Generate the list based on the range or single number
      List<String> tempList = List.generate(
        end - start + 1,
        (index) {
          String numberText = convertNumberToWord(start + index);
          return "$baseText $numberText"; // Combine base text and number text
        },
      );

      // Update the UI with the generated list
      setState(() {
        generatedList = tempList;
      });

      // Save each item asynchronously
      for (String item in tempList) {
        await _saveSettings(item); // Use await to wait for each request
      }
    } else {
      // If no match, return the input text as-is
      setState(() {
        generatedList = [inputText];
      });
    }
  }

  String convertNumberToWord(int number) {
    if (number < 0 || number > 999) {
      return number.toString(); // Return as is if outside range
    }

    // Define the words for the numbers
    List<String> units = [
      'zero',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine'
    ];

    // Process each digit separately
    String numberStr = number.toString(); // Convert number to string
    String words = '';

    for (int i = 0; i < numberStr.length; i++) {
      int digit = int.parse(numberStr[i]); // Get each digit as an integer
      words +=
          (i > 0 ? ' ' : '') + units[digit]; // Append the corresponding word
    }

    return words.trim(); // Remove any leading/trailing spaces
  }

  Future<void> _saveSettings(String singleText) async {
    String apiUrl = 'https://api-voice.botnoi.ai/openapi/v1/generate_audio';
    String token = 'SWNMcmZwMXhic1phYzdGV2RVZ0IydmRxT1dDMzU2MTg5NA==';

    var body = jsonEncode({
      'text': singleText, // ส่งข้อความทีละรายการ
      'speaker': speakerController.text,
      'volume': double.tryParse(volumeController.text) ?? 1.0,
      'speed': double.tryParse(speedController.text) ?? 1.0,
      'type_media': typeMediaController.text,
      'save_file': saveFileController.text.toLowerCase() == 'true',
      'language': languageController.text
    });

    // Make the POST request
    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Botnoi-Token': token,
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      String audioUrl = responseData['audio_url'];

      setState(() {
        audioItems.add({'text': singleText, 'url': audioUrl});
      });
    } else {
      print('Error: ${response.statusCode}, Response: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // ใช้ SingleChildScrollView เพื่อให้เลื่อนขึ้นลงได้
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: textController,
                    decoration: InputDecoration(labelText: 'Text'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: speakerController,
                    decoration: InputDecoration(labelText: 'Speaker'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Second row: Volume, Speed, and Type Media
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: volumeController,
                    decoration: InputDecoration(labelText: 'Volume'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: speedController,
                    decoration: InputDecoration(labelText: 'Speed'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: typeMediaController,
                    decoration: InputDecoration(labelText: 'Type Media'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: saveFileController,
                    decoration:
                        InputDecoration(labelText: 'Save File (true/false)'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: languageController,
                    decoration: InputDecoration(labelText: 'Language'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Save button
            Center(
              child: ElevatedButton(
                onPressed: _generateListThai,
                // onPressed: _generateListEnglish,
                child: const Text('Save Settings (บันทึกการตั้งค่าหน้านี้)'),
              ),
            ),
            const SizedBox(height: 24),
            // Button to download all audio files
            if (audioItems.isNotEmpty)
              Center(
                child: ElevatedButton(
                  onPressed: _downloadAll,
                  child: const Text('ดาวน์โหลดเสียงทั้งหมด'),
                ),
              ),
            const SizedBox(height: 24),
            // Expanded list of audio items
            ListView.builder(
              shrinkWrap:
                  true, // ใช้ shrinkWrap เพื่อให้ ListView สามารถปรับขนาดได้ตามเนื้อหา
              physics:
                  NeverScrollableScrollPhysics(), // ปิดการเลื่อนของ ListView
              itemCount: audioItems.length,
              itemBuilder: (context, index) {
                final item = audioItems[index];
                return ListTile(
                  title: Text(item['text']!),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      if (await canLaunch(item['url']!)) {
                        await launch(item['url']!);
                      } else {
                        print('Could not launch ${item['url']}');
                      }
                    },
                    child: const Text('ดาวน์โหลด'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAll() async {
    for (var item in audioItems) {
      final url = item['url']!;
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        print('Could not launch $url');
      }
    }
  }
}
