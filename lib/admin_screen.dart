import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final String owner = 'alphasuper6-dev';
  final String repo = 'alpha_super';
  final String filePath = 'questions.json';
  final String githubToken = 'YOUR_GITHUB_READ_WRITE_TOKEN';

  String selectedStage = 'تاسع';
  String selectedSection = 'أتمتة'; // أتمتة | تحريري | دورات
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController examYearController = TextEditingController(); // لأسئلة الدورات 2018-2026
  final TextEditingController questionController = TextEditingController();
  final TextEditingController opt1Controller = TextEditingController();
  final TextEditingController opt2Controller = TextEditingController();
  final TextEditingController opt3Controller = TextEditingController();
  final TextEditingController opt4Controller = TextEditingController();
  final TextEditingController answerController = TextEditingController();
  final TextEditingController explanationController = TextEditingController(); // شرح السؤال

  bool isLoading = false;

  Future<void> publishQuestion() async {
    if (subjectController.text.isEmpty ||
        unitController.text.isEmpty ||
        questionController.text.isEmpty ||
        answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول المطلوبة')),
      );
      return;
    }

    setState(() => isLoading = true);
    final String apiUrl = 'https://github.com';

    try {
      final getResponse = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      final fileData = jsonDecode(getResponse.body);
      final String sha = fileData['sha'];
      final String currentJson = utf8.decode(base64Decode(fileData['content'].toString().replaceAll('\n', '')));
      List<dynamic> questionsList = jsonDecode(currentJson);

      questionsList.add({
        "stage": selectedStage,
        "subject": subjectController.text.trim(),
        "unit": unitController.text.trim(),
        "section": selectedSection, // أتمتة / تحريري / دورات
        "year": selectedSection == 'دورات' ? examYearController.text.trim() : "",
        "question": questionController.text.trim(),
        "options": selectedSection == 'أتمتة'
            ? [
                opt1Controller.text.trim(),
                opt2Controller.text.trim(),
                opt3Controller.text.trim(),
                opt4Controller.text.trim(),
              ]
            : [],
        "answer": answerController.text.trim(),
        "explanation": explanationController.text.trim(),
      });

      String updatedBase64 = base64Encode(utf8.encode(const JsonEncoder.withIndent('  ').convert(questionsList)));

      final putResponse = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'إضافة سؤال جديد (${subjectController.text})',
          'content': updatedBase64,
          'sha': sha,
        }),
      );

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر السؤال بنجاح!'), backgroundColor: Colors.green),
        );
        questionController.clear();
        opt1Controller.clear();
        opt2Controller.clear();
        opt3Controller.clear();
        opt4Controller.clear();
        answerController.clear();
        explanationController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أداة توليد الأسئلة (للإدارة)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedStage,
              decoration: const InputDecoration(labelText: 'المرحلة'),
              items: ['تاسع', 'بكالوريا علمي', 'بكالوريا أدبي']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => selectedStage = val!),
            ),
            TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'المادة (مثلاً: العلوم، الرياضيات)')),
            TextField(controller: unitController, decoration: const InputDecoration(labelText: 'الدرس / الوحدة')),
            DropdownButtonFormField<String>(
              value: selectedSection,
              decoration: const InputDecoration(labelText: 'تبويب الدرس (وجه الصفحة)'),
              items: ['أتمتة', 'تحريري', 'دورات']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => selectedSection = val!),
            ),
            if (selectedSection == 'دورات')
              TextField(controller: examYearController, decoration: const InputDecoration(labelText: 'سنة الدورة (من 2018 إلى 2026)')),
            TextField(controller: questionController, maxLines: 3, decoration: const InputDecoration(labelText: 'نص السؤال')),
            if (selectedSection == 'أتمتة') ...[
              TextField(controller: opt1Controller, decoration: const InputDecoration(labelText: 'الخيار 1')),
              TextField(controller: opt2Controller, decoration: const InputDecoration(labelText: 'الخيار 2')),
              TextField(controller: opt3Controller, decoration: const InputDecoration(labelText: 'الخيار 3')),
              TextField(controller: opt4Controller, decoration: const InputDecoration(labelText: 'الخيار 4')),
            ],
            TextField(controller: answerController, maxLines: 2, decoration: const InputDecoration(labelText: 'الإجابة الصحيحة / سلم التصحيح')),
            TextField(controller: explanationController, maxLines: 3, decoration: const InputDecoration(labelText: 'شرح السؤال (يظهر عند كشف الإجابة)')),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: publishQuestion,
                    icon: const Icon(Icons.send),
                    label: const Text('نشر السؤال للسحابة'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  ),
          ],
        ),
      ),
    );
  }
}
