import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonStudyScreen extends StatefulWidget {
  final String subjectName;
  final String lessonName;
  final List<dynamic> allQuestions;

  const LessonStudyScreen({
    super.key,
    required this.subjectName,
    required this.lessonName,
    required this.allQuestions,
  });

  @override
  State<LessonStudyScreen> createState() => _LessonStudyScreenState();
}

class _LessonStudyScreenState extends State<LessonStudyScreen> {
  // حفظ السؤال في المفضلة داخل التطبيق
  Future<void> saveQuestionLocally(Map<String, dynamic> question) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('saved_questions') ?? [];
    String encoded = jsonEncode(question);
    if (!saved.contains(encoded)) {
      saved.add(encoded);
      await prefs.setStringList('saved_questions', saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ السؤال في قائمة المراجعة!'), backgroundColor: Colors.green),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا السؤال محفوظ مسبقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mcqList = widget.allQuestions.where((q) => q['section'] == 'أتمتة').toList();
    final essayList = widget.allQuestions.where((q) => q['section'] == 'تحريري').toList();
    final pastExamsList = widget.allQuestions.where((q) => q['section'] == 'دورات').toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.lessonName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'أتمتة'),
              Tab(text: 'تحريري'),
              Tab(text: 'دورات 18-26'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildQuestionList(mcqList),
            _buildQuestionList(essayList),
            _buildQuestionList(pastExamsList),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionList(List<dynamic> questions) {
    if (questions.isEmpty) {
      return const Center(child: Text('لا توجد أسئلة مضافة في هذا القسم بعد'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        return QuestionCardWidget(
          questionData: questions[index],
          onSave: () => saveQuestionLocally(questions[index]),
        );
      },
    );
  }
}

class QuestionCardWidget extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final VoidCallback onSave;

  const QuestionCardWidget({super.key, required this.questionData, required this.onSave});

  @override
  State<QuestionCardWidget> createState() => _QuestionCardWidgetState();
}

class _QuestionCardWidgetState extends State<QuestionCardWidget> {
  String? selectedOption;
  bool revealAnswer = false; // لا يظهر الجواب إلا عند الضغط على الزر

  @override
  Widget build(BuildContext context) {
    final q = widget.questionData;
    final List<dynamic> options = q['options'] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (q['year'] != null && q['year'].toString().isNotEmpty)
              Chip(label: Text('دورة ${q['year']}'), backgroundColor: Colors.amber.shade100),
            Text(q['question'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // عرض الخيارات الأربعة للأتمتة بدون كشف الحل فوراً
            if (options.isNotEmpty)
              ...options.map((opt) {
                return RadioListTile<String>(
                  title: Text(opt.toString()),
                  value: opt.toString(),
                  groupValue: selectedOption,
                  onChanged: (val) => setState(() => selectedOption = val),
                );
              }),
            const Divider(),
            // أزرار كشف الإجابة وحفظ السؤال في الأسفل
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => revealAnswer = !revealAnswer),
                  icon: Icon(revealAnswer ? Icons.visibility_off : Icons.visibility),
                  label: Text(revealAnswer ? 'إخفاء الإجابة' : 'كشف الإجابة'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onSave,
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text('حفظ السؤال'),
                ),
              ],
            ),
            // صندوق الإجابة والشرح (يظهر فقط بعد الضغط على كشف الإجابة)
            if (revealAnswer) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الإجابة الصحيحة: ${q['answer']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    if (q['explanation'] != null && q['explanation'].toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('الشرح: ${q['explanation']}'),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
