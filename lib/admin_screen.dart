import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'code_generator_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});
  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = List.generate(4, (_) => TextEditingController());
  final TextEditingController explanationController = TextEditingController();

  String selectedBranch = 'T9';
  String selectedSubject = 'الرياضيات';
  String selectedUnit = 'الوحدة الأولى';
  int correctIndex = 0;
  bool isLoading = false;

  final Map<String, List<String>> branchSubjects = {
    'T9': ['الرياضيات', 'الفيزياء والكيمياء', 'علم الأحياء', 'اللغة العربية', 'اللغة الإنكليزية', 'اللغة الفرنسية', 'الاجتماعيات', 'التربية الدينية'],
    'SCI': ['الرياضيات', 'الفيزياء', 'الكيمياء', 'علم الأحياء', 'اللغة العربية', 'اللغة الإنكليزية', 'اللغة الفرنسية', 'التربية الوطنية', 'التربية الدينية'],
    'LIT': ['اللغة العربية', 'التاريخ', 'الجغرافيا', 'الفلسفة', 'اللغة الإنكليزية', 'اللغة الفرنسية', 'التربية الوطنية', 'التربية الدينية'],
  };

  Future<void> _uploadQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    final githubToken = (prefs.getString('gh_admin_token') ?? '').trim();

    if (githubToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('افتح مولّد الأكواد أولاً واحفظ مفتاح GitHub Token هناك'), backgroundColor: Colors.red),
      );
      return;
    }

    if (questionController.text.trim().isEmpty || optionControllers.any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة نص السؤال والخيارات الأربعة كاملة'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('https://api.github.com/repos/' + 'alphasuper6-dev/alpha_super/contents/questions.json');
      final headers = {
        'Authorization': 'token $githubToken',
        'User-Agent': 'AlphaSuperApp',
      };

      final getRes = await http.get(url, headers: headers);
      List<dynamic> questionsList = [];
      String? sha;

      if (getRes.statusCode == 200) {
        final data = jsonDecode(getRes.body);
        sha = data['sha'];
        String rawBase64 = (data['content'] as String).replaceAll('\n', '').replaceAll('\r', '').trim();
        if (rawBase64.isNotEmpty) {
          String decodedStr = utf8.decode(base64Decode(rawBase64)).trim();
          if (decodedStr.startsWith('[')) {
            questionsList = jsonDecode(decodedStr);
          }
        }
      } else if (getRes.statusCode != 404) {
        throw Exception('GitHub Error (${getRes.statusCode}): ${getRes.body}');
      }

      questionsList.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'branch': selectedBranch,
        'subject': selectedSubject,
        'unit': selectedUnit,
        'question': questionController.text.trim(),
        'options': optionControllers.map((c) => c.text.trim()).toList(),
        'correctIndex': correctIndex,
        'explanation': explanationController.text.trim(),
      });

      String updatedJson = const JsonEncoder.withIndent('  ').convert(questionsList);
      String encodedContent = base64Encode(utf8.encode(updatedJson));

      final putBody = <String, dynamic>{
        'message': 'Add question to $selectedSubject - $selectedUnit',
        'content': encodedContent,
      };
      if (sha != null) {
        putBody['sha'] = sha;
      }

      final putRes = await http.put(url, headers: headers, body: jsonEncode(putBody));

      if (putRes.statusCode == 200 || putRes.statusCode == 201) {
        questionController.clear();
        for (var c in optionControllers) {
          c.clear();
        }
        explanationController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفع السؤال للسحابة بنجاح!'), backgroundColor: Colors.green),
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
    final subjects = branchSubjects[selectedBranch] ?? ['الرياضيات'];
    if (!subjects.contains(selectedSubject)) {
      selectedSubject = subjects.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة - إضافة الأسئلة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            tooltip: 'مولّد الأكواد',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CodeGeneratorScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CodeGeneratorScreen())),
              icon: const Icon(Icons.vpn_key),
              label: const Text('فتح مولّد الأكواد السحابي'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedBranch,
              decoration: const InputDecoration(labelText: 'الفرع الدراسي', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'T9', child: Text('التاسع الأساسي (T9)')),
                DropdownMenuItem(value: 'SCI', child: Text('البكالوريا العلمي (SCI)')),
                DropdownMenuItem(value: 'LIT', child: Text('البكالوريا الأدبي (LIT)')),
              ],
              onChanged: (val) => setState(() {
                selectedBranch = val!;
                selectedSubject = branchSubjects[selectedBranch]!.first;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedSubject,
              decoration: const InputDecoration(labelText: 'المادة', border: OutlineInputBorder()),
              items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => selectedSubject = val!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedUnit,
              decoration: const InputDecoration(labelText: 'الوحدة / القسم', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'الوحدة الأولى', child: Text('الوحدة الأولى')),
                DropdownMenuItem(value: 'الوحدة الثانية', child: Text('الوحدة الثانية')),
                DropdownMenuItem(value: 'الوحدة الثالثة', child: Text('الوحدة الثالثة')),
                DropdownMenuItem(value: 'الوحدة الرابعة', child: Text('الوحدة الرابعة')),
                DropdownMenuItem(value: 'الوحدة الخامسة', child: Text('الوحدة الخامسة')),
                DropdownMenuItem(value: 'الوحدة السادسة', child: Text('الوحدة السادسة')),
                DropdownMenuItem(value: 'نماذج امتحانية شاملة', child: Text('نماذج امتحانية شاملة')),
              ],
              onChanged: (val) => setState(() => selectedUnit = val!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: questionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'نص السؤال', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ...List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: correctIndex,
                    onChanged: (val) => setState(() => correctIndex = val!),
                  ),
                  Expanded(
                    child: TextField(
                      controller: optionControllers[i],
                      decoration: InputDecoration(labelText: 'الخيار ${i + 1}', border: const OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            TextField(
              controller: explanationController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'شرح الإجابة الصحيحة (اختياري)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _uploadQuestion,
              icon: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: Text(isLoading ? 'جاري الرفع للسحابة...' : 'رفع السؤال للسحابة'),
            ),
          ],
        ),
      ),
    );
  }
}
