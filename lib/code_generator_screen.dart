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
  final String githubToken = 'ghp_XmrIVpgB39JUfxJDf+Cwr0N17DAmPb01YS14V' ;
  
  
  String selectedBranch = 'T9';
  final TextEditingController countController = TextEditingController(text: '10');
  List<String> generated = [];
  bool isGenerating = false;

  String _makeCode(String prefix) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    String p1 = List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    String p2 = List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    return '$prefix-$p1-$p2';
  }

  Future<void> generateCodes() async {
    int count = int.tryParse(countController.text.trim()) ?? 1;
    if (count <= 0 || count > 2000) return;

    setState(() {
      isGenerating = true;
      generated.clear();
    });
    final url = 'https://github.com';

    try {
      final getRes = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $githubToken', 'Accept': 'application/vnd.github.v3+json'},
      );
      final fileData = jsonDecode(getRes.body);
      final sha = fileData['sha'];
      final raw = utf8.decode(base64Decode(fileData['content'].toString().replaceAll('\n', '')));
      Map<String, dynamic> codesMap = raw.trim().isNotEmpty ? jsonDecode(raw) : {};

      int added = 0;
      while (added < count) {
        String code = _makeCode(selectedBranch);
        if (!codesMap.containsKey(code)) {
          codesMap[code] = {"status": "unused", "device_id": "", "branch": selectedBranch};
          generated.add(code);
          added++;
        }
      }

      await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'توليد $count كود ($selectedBranch)',
          'content': base64Encode(utf8.encode(const JsonEncoder.withIndent('  ').convert(codesMap))),
          'sha': sha,
        }),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم توليد $count كود بنجاح!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مولّد الأكواد حسب الفرع'),
        actions: [
          if (generated.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_all),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: generated.join('\n')));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ جميع الأكواد!')),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedBranch,
              decoration: const InputDecoration(labelText: 'اختر الفرع المطلوب للكود', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'T9', child: Text('التاسع الأساسي فقط (T9)')),
                DropdownMenuItem(value: 'SC', child: Text('البكالوريا العلمي فقط (SC)')),
                DropdownMenuItem(value: 'LT', child: Text('البكالوريا الأدبي فقط (LT)')),
                DropdownMenuItem(value: 'ALL', child: Text('الباقة الشاملة للكل (ALL)')),
              ],
              onChanged: (v) => setState(() => selectedBranch = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد الأكواد', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            isGenerating
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: generateCodes,
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('توليد ورفع للسحابة'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                  ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: generated.length,
                itemBuilder: (_, i) => Card(
                  child: ListTile(
                    title: SelectableText(generated[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => Clipboard.setData(ClipboardData(text: generated[i])),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
