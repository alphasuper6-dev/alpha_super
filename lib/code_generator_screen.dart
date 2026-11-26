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
  final String githubToken = 'ghp_vHJTKbSBC85KS8C3G7+9CKJRkXkwj0o4BYjpt' ;

  String selectedBranch = 'T9';
  final TextEditingController countController = TextEditingController(text: '10');
  bool isLoading = false;
  List<String> generatedCodes = [];

  String _randomCode(String prefix) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    String part1 = List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    String part2 = List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    return '$prefix-$part1-$part2';
  }

  Future<void> _generateAndUpload() async {
    int count = int.tryParse(countController.text.trim()) ?? 0;
    if (count <= 0 || count > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عدداً صحيحاً بين 1 و 500'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      isLoading = true;
      generatedCodes.clear();
    });

    try {
      final url = Uri.parse('https://api.github.com/repos/alphasuper6-dev/alpha_super/contents/codes.json');
      
      
      final headers = {
        'Authorization': 'Bearer $githubToken',
                'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        
        'X-GitHub-Api-Version': '2022-11-28',
      };

      final getRes = await http.get(url, headers: headers);
      Map<String, dynamic> existingCodes = {};
      String? sha;

      if (getRes.statusCode == 200) {
        final data = jsonDecode(getRes.body);
        sha = data['sha'];
        String rawBase64 = (data['content'] as String).replaceAll('\n', '').replaceAll('\r', '').trim();
        if (rawBase64.isNotEmpty) {
          String decodedStr = utf8.decode(base64Decode(rawBase64)).trim();
          if (decodedStr.startsWith('{')) {
            existingCodes = jsonDecode(decodedStr);
          }
        }
      } else if (getRes.statusCode != 404) {
        throw Exception('GitHub Error (${getRes.statusCode}): ${getRes.body}');
      }

      List<String> newBatch = [];
      for (int i = 0; i < count; i++) {
        String code;
        do {
          code = _randomCode(selectedBranch);
        } while (existingCodes.containsKey(code));

        existingCodes[code] = {
          'deviceId': '',
          'status': 'unused',
          'branch': selectedBranch,
        };
        newBatch.add(code);
      }

      String updatedJson = const JsonEncoder.withIndent('  ').convert(existingCodes);
      String encodedContent = base64Encode(utf8.encode(updatedJson));

      final putBody = <String, dynamic>{
        'message': 'Generate $count codes for $selectedBranch',
        'content': encodedContent,
      };
      if (sha != null) {
        putBody['sha'] = sha;
      }

      final putRes = await http.put(url, headers: headers, body: jsonEncode(putBody));

      if (putRes.statusCode == 200 || putRes.statusCode == 201) {
        setState(() => generatedCodes = newBatch);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم توليد ورفع $count كود بنجاح!'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('فشل الرفع (${putRes.statusCode}): ${putRes.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 6)),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مولّد الأكواد حسب الفرع')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: selectedBranch,
              decoration: const InputDecoration(labelText: 'اختر الفرع المطلوب للكود', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'T9', child: Text('التاسع الأساسي فقط (T9)')),
                DropdownMenuItem(value: 'SCI', child: Text('البكالوريا العلمي فقط (SCI)')),
                DropdownMenuItem(value: 'LIT', child: Text('البكالوريا الأدبي فقط (LIT)')),
                DropdownMenuItem(value: 'ALL', child: Text('شامل لجميع الفروع (ALL)')),
              ],
              onChanged: (val) => setState(() => selectedBranch = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد الأكواد', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _generateAndUpload,
              icon: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.vpn_key),
              label: Text(isLoading ? 'جاري التوليد والرفع...' : 'توليد ورفع للسحابة'),
            ),
            const SizedBox(height: 16),
            if (generatedCodes.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الأكواد الجاهزة (${generatedCodes.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: generatedCodes.join('\n')));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ جميع الأكواد!')));
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('نسخ الكل'),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: generatedCodes.length,
                  itemBuilder: (_, i) => Card(
                    child: ListTile(
                      title: SelectableText(generatedCodes[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: generatedCodes[i]));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الكود')));
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
