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
    final mcqList = widget.allQuestions.where((q) => (q['section'] ?? 'أتمتة') == 'أتمتة').toList();
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
  bool revealAnswer = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.questionData;
    final List<dynamic> options = q['options'] ?? [];
    final String shape = (q['shape'] ?? '').toString().trim().toLowerCase();
    final String imageUrl = (q['image'] ?? '').toString().trim();
    final String correctAnswer = (q['answer'] ?? '').toString();
    final String explanation = (q['explanation'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (q['year'] != null && q['year'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(label: Text('دورة ${q['year']}'), backgroundColor: Colors.amber.shade100),
              ),

            if (shape.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(180, 140),
                    painter: GeometryShapePainter(shape),
                  ),
                ),
              ),

            if (imageUrl.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            Text(q['question'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (options.isNotEmpty)
              ...options.map((opt) {
                final optText = opt.toString();
                Color? tileColor;
                if (revealAnswer) {
                  if (optText == correctAnswer) {
                    tileColor = Colors.green.shade100;
                  } else if (optText == selectedOption) {
                    tileColor = Colors.red.shade100;
                  }
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RadioListTile<String>(
                    title: Text(optText),
                    value: optText,
                    groupValue: selectedOption,
                    onChanged: (val) => setState(() => selectedOption = val),
                  ),
                );
              }),

            if (revealAnswer) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإجابة الصحيحة / الحل النموذجي:\n$correctAnswer',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    if (explanation.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('الشرح: $explanation'),
                    ],
                  ],
                ),
              ),
            ],

            const Divider(),
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
          ],
        ),
      ),
    );
  }
}

class GeometryShapePainter extends CustomPainter {
  final String shape;
  GeometryShapePainter(this.shape);

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.indigo.shade800
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final dashedPaint = Paint()
      ..color = Colors.indigo.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    if (shape == 'triangle' || shape == 'مثلث') {
      final path = Path()
        ..moveTo(w * 0.5, h * 0.1)
        ..lineTo(w * 0.15, h * 0.88)
        ..lineTo(w * 0.85, h * 0.88)
        ..close();
      canvas.drawPath(path, paint);
      _drawLabel(canvas, 'A', Offset(w * 0.48, h * 0.0));
      _drawLabel(canvas, 'B', Offset(w * 0.06, h * 0.85));
      _drawLabel(canvas, 'C', Offset(w * 0.88, h * 0.85));
    } else if (shape == 'circle' || shape == 'دائرة') {
      final center = Offset(w * 0.5, h * 0.5);
      final r = h * 0.42;
      canvas.drawCircle(center, r, paint);
      canvas.drawLine(center, Offset(center.dx + r, center.dy), dashedPaint);
      canvas.drawCircle(center, 3, Paint()..color = Colors.red);
      _drawLabel(canvas, 'O', Offset(center.dx - 12, center.dy - 14));
      _drawLabel(canvas, 'R', Offset(center.dx + r * 0.45, center.dy - 18));
    } else if (shape == 'cone' || shape == 'مخروط') {
      final top = Offset(w * 0.5, h * 0.1);
      final left = Offset(w * 0.2, h * 0.8);
      final right = Offset(w * 0.8, h * 0.8);
      canvas.drawLine(top, left, paint);
      
