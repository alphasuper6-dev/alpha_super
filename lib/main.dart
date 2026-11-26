import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  // إعدادات مستودعك (ضع التوكن الخاص بك هنا بصلاحية قراءة وكتابة Contents: Read & Write)
  final String owner = 'alphasuper6-dev';
  final String repo = 'alpha_super';
  final String filePath = 'questions.json'; // تأكد أنه يطابق مكان الملف في مستودعك
  final String githubToken = 'YOUR_GITHUB_READ_WRITE_TOKEN';

  String selectedStage = 'تاسع';
  String selectedType = 'mcq';
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController questionController = TextEditingController();
  final TextEditingController opt1Controller = TextEditingController();
  final TextEditingController opt2Controller = TextEditingController();
  final TextEditingController opt3Controller = TextEditingController();
  final TextEditingController opt4Controller = TextEditingController();
  final TextEditingController answerController = TextEditingController();

  bool isLoading = false;

  Future<void> publishQuestionToGitHub() async {
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

    final String apiUrl =
        'https://github.com';

    try {
      // 1. جلب الملف الحالي من GitHub للحصول على المحتوى القديم ورمز التحديث (sha)
      final getResponse = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (getResponse.statusCode != 200) {
        throw Exception('فشل الاتصال بالمستودع: ${getResponse.statusCode}');
      }

      final fileData = jsonDecode(getResponse.body);
      final String sha = fileData['sha'];
      final String contentBase64 =
          fileData['content'].toString().replaceAll('\n', '');
      final String currentJsonString =
          utf8.decode(base64Decode(contentBase64));

      // 2. تحويل النص إلى قائمة وإضافة السؤال الجديد
      List<dynamic> questionsList = jsonDecode(currentJsonString);

      Map<String, dynamic> newQuestion = {
        "stage": selectedStage,
        "subject": subjectController.text.trim(),
        "unit": unitController.text.trim(),
        "type": selectedType,
        "question": questionController.text.trim(),
        "options": selectedType == 'mcq'
            ? [
                opt1Controller.text.trim(),
                opt2Controller.text.trim(),
                opt3Controller.text.trim(),
                opt4Controller.text.trim(),
              ]
            : [],
        "answer": answerController.text.trim(),
      };

      questionsList.add(newQuestion);

      // 3. تشفير القائمة المحدثة وإرسالها إلى GitHub
      String updatedJsonString =
          const JsonEncoder.withIndent('  ').convert(questionsList);
      String updatedBase64 = base64Encode(utf8.encode(updatedJsonString));

      final putResponse = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'إضافة سؤال جديد من التطبيق (${subjectController.text})',
          'content': updatedBase64,
          'sha': sha,
        }),
      );

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نشر السؤال على السحابة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        questionController.clear();
        opt1Controller.clear();
        opt2Controller.clear();
        opt3Controller.clear();
        opt4Controller.clear();
        answerController.clear();
      } else {
        throw Exception('فشل الرفع: ${putResponse.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الإدارة - إضافة سؤال')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedStage,
              decoration: const InputDecoration(labelText: 'المرحلة الدراسية'),
              items: ['تاسع', 'بكالوريا علمي', 'بكالوريا أدبي']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => selectedStage = val!),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: 'اسم المادة (مثلاً: الفيزياء)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'اسم الوحدة'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: 'نوع السؤال'),
              items: const [
                DropdownMenuItem(value: 'mcq', child: Text('أتمتة (اختيار من متعدد)')),
                DropdownMenuItem(value: 'essay', child: Text('مقالي (مع سلم تصحيح)')),
              ],
              onChanged: (val) => setState(() => selectedType = val!),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: questionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'نص السؤال'),
            ),
            if (selectedType == 'mcq') ...[
              const SizedBox(height: 10),
              TextField(controller: opt1Controller, decoration: const InputDecoration(labelText: 'الخيار الأول')),
              TextField(controller: opt2Controller, decoration: const InputDecoration(labelText: 'الخيار الثاني')),
              TextField(controller: opt3Controller, decoration: const InputDecoration(labelText: 'الخيار الثالث')),
              TextField(controller: opt4Controller, decoration: const InputDecoration(labelText: 'الخيار الرابع')),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: answerController,
              maxLines: selectedType == 'essay' ? 4 : 1,
              decoration: InputDecoration(
                labelText: selectedType == 'mcq'
                    ? 'الإجابة الصحيحة (اكتبها مطابقة لأحد الخيارات)'
                    : 'الحل وسلّم التصحيح',
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: publishQuestionToGitHub,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('نشر السؤال للسحابة فوراً'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
