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

  Future<void> _saveSettings() async {
    String apiUrl = 'https://api-voice.botnoi.ai/openapi/v1/generate_audio';
    String token = 'SWNMcmZwMXhic1phYzdGV2RVZ0IydmRxT1dDMzU2MTg5NA==';

    var body = jsonEncode({
      'text': textController.text,
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
        audioItems.add({'text': textController.text, 'url': audioUrl});
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
                onPressed: _saveSettings,
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
