import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class CodeGeneratorScreen extends StatefulWidget {
  const CodeGeneratorScreen({super.key});

  @override
  State<CodeGeneratorScreen> createState() => _CodeGeneratorScreenState();
}

class _CodeGeneratorScreenState extends State<CodeGeneratorScreen> {
  final String owner = 'alphasuper6-dev';
  final String repo = 'alpha_super';
  final String filePath = 'codes.json';
  final String githubToken = 'YOUR_GITHUB_READ_WRITE_TOKEN';

  final TextEditingController countController = TextEditingController(text: '10');
  List<String> newlyGeneratedCodes = [];
  bool isGenerating = false;

  String _createRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    String part1 = List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    String part2 = List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    return 'ALPHA-$part1-$part2';
  }

  Future<void> generateAndUploadCodes() async {
    int count = int.tryParse(countController.text.trim()) ?? 1;
    if (count <= 0 || count > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عدداً بين 1 و 2000 كود')),
      );
      return;
    }

    setState(() {
      isGenerating = true;
      newlyGeneratedCodes.clear();
    });

    final String apiUrl = 'https://github.com';

    try {
      // 1. جلب ملف codes.json الحالي من GitHub
      final getResponse = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (getResponse.statusCode != 200) {
        throw Exception('فشل الاتصال بملف الأكواد: ${getResponse.statusCode}');
      }

      final fileData = jsonDecode(getResponse.body);
      final String sha = fileData['sha'];
      final String contentStr = utf8.decode(
        base64Decode(fileData['content'].toString().replaceAll('\n', '')),
      );

      Map<String, dynamic> codesMap = {};
      if (contentStr.trim().isNotEmpty) {
        final decoded = jsonDecode(contentStr);
        if (decoded is Map<String, dynamic>) {
          codesMap = decoded;
        } else if (decoded is List) {
          for (var c in decoded) {
            codesMap[c.toString()] = {"status": "unused", "device_id": ""};
          }
        }
      }

      // 2. توليد الأكواد الجديدة بدون تكرار
      int added = 0;
      while (added < count) {
        String code = _createRandomCode();
        if (!codesMap.containsKey(code)) {
          codesMap[code] = {
            "status": "unused",
            "device_id": "", // سيُملأ برقم هاتف الطالب عند أول تفعيل
          };
          newlyGeneratedCodes.add(code);
          added++;
        }
      }

      // 3. رفع القائمة المحدثة إلى GitHub
      String updatedJson = const JsonEncoder.withIndent('  ').convert(codesMap);
      String updatedBase64 = base64Encode(utf8.encode(updatedJson));

      final putResponse = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'توليد $count كود تفعيل من التطبيق',
          'content': updatedBase64,
          'sha': sha,
        }),
      );

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم توليد وحفظ $count كود على السحابة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('فشل الحفظ: ${putResponse.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  void copyAllCodes() {
    if (newlyGeneratedCodes.isEmpty) return;
    Clipboard.setData(ClipboardData(text: newlyGeneratedCodes.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ جميع الأكواد الجديدة للحافظة!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مولّد أكواد التفعيل'),
        actions: [
          if (newlyGeneratedCodes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_all),
              tooltip: 'نسخ الكل',
              onPressed: copyAllCodes,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الأكواد المطلوب توليدها (مثلاً: 1 أو 50 أو 500)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            isGenerating
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: generateAndUploadCodes,
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('توليد ورفع للسحابة فوراً'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
            const SizedBox(height: 16),
            if (newlyGeneratedCodes.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الأكواد المولّدة (${newlyGeneratedCodes.length}):',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: copyAllCodes,
                    icon: const Icon(Icons.copy),
                    label: const Text('نسخ القائمة كاملة'),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: newlyGeneratedCodes.length,
                  itemBuilder: (context, index) {
                    final code = newlyGeneratedCodes[index];
                    return Card(
                      child: ListTile(
                        title: SelectableText(
                          code,
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم نسخ الكود: $code')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
