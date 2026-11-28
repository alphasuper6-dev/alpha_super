import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonStudyScreen extends StatefulWidget {
  final String subjectName, lessonName;
  final List<dynamic> allQuestions;
  const LessonStudyScreen({super.key, required this.subjectName, required this.lessonName, required this.allQuestions});
  @override
  State<LessonStudyScreen> createState() => _LessonStudyScreenState();
}

class _LessonStudyScreenState extends State<LessonStudyScreen> {
  Future<void> saveQuestionLocally(Map<String, dynamic> q) async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList('saved_questions') ?? [];
    final enc = jsonEncode(q);
    if (!saved.contains(enc)) {
      saved.add(enc);
      await p.setStringList('saved_questions', saved);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ السؤال في حقيبة المراجعة')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا السؤال محفوظ مسبقاً')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mcq = widget.allQuestions.where((q) => (q['section'] ?? 'أتمتة') == 'أتمتة').toList();
    final essay = widget.allQuestions.where((q) => q['section'] == 'تحريري').toList();
    final past = widget.allQuestions.where((q) => q['section'] == 'دورات').toList();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.lessonName),
          bottom: const TabBar(tabs: [Tab(text: 'أتمتة'), Tab(text: 'تحريري'), Tab(text: 'دورات 18-26')]),
        ),
        body: TabBarView(children: [
          ExamTabView(questions: mcq, onSave: saveQuestionLocally, enableExam: true),
          ExamTabView(questions: essay, onSave: saveQuestionLocally, enableExam: false),
          ExamTabView(questions: past, onSave: saveQuestionLocally, enableExam: true),
        ]),
      ),
    );
  }
}

class ExamTabView extends StatefulWidget {
  final List<dynamic> questions;
  final Function(Map<String, dynamic>) onSave;
  final bool enableExam;
  const ExamTabView({super.key, required this.questions, required this.onSave, required this.enableExam});
  @override
  State<ExamTabView> createState() => _ExamTabViewState();
}

class _ExamTabViewState extends State<ExamTabView> {
  bool isExam = false, submitted = false;
  int secLeft = 0;
  Timer? _timer;
  final Map<int, String> answers = {};

  String _getCorrect(Map<String, dynamic> q) {
    final opts = q['options'] ?? [];
    final idx = (q['correctIndex'] is int) ? q['correctIndex'] : -1;
    return (q['answer'] ?? (idx >= 0 && idx < opts.length ? opts[idx] : '')).toString();
  }

  void _start() {
    setState(() {
      isExam = true;
      submitted = false;
      answers.clear();
      secLeft = widget.questions.length * 90;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secLeft <= 1) {
        t.cancel();
        _submit();
      } else {
        setState(() => secLeft--);
      }
    });
  }

  void _submit() {
    _timer?.cancel();
    int ok = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (answers[i] != null && answers[i] == _getCorrect(widget.questions[i])) ok++;
    }
    setState(() => submitted = true);
    final total = widget.questions.length;
    final score = total > 0 ? ((ok / total) * 100).round() : 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نتيجة الاختبار الامتحاني'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(score >= 60 ? Icons.emoji_events : Icons.school, size: 52, color: score >= 60 ? Colors.amber : Colors.indigo),
          const SizedBox(height: 10),
          Text('علامتك: $score / 100', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('الصحيحة: $ok من أصل $total | الخاطئة: ${total - ok}'),
        ]),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('مراجعة الحلول'))],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) return const Center(child: Text('لا توجد أسئلة مضافة في هذا القسم بعد'));
    final timeStr = '${(secLeft ~/ 60).toString().padLeft(2, '0')}:${(secLeft % 60).toString().padLeft(2, '0')}';
    return Column(children: [
      if (widget.enableExam)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.indigo.shade50,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if (!isExam)
              ElevatedButton.icon(onPressed: _start, icon: const Icon(Icons.timer), label: const Text('وضع الامتحان المؤقت'))
            else ...[
              Row(children: [const Icon(Icons.timer, color: Colors.red), const SizedBox(width: 6), Text(timeStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red))]),
              if (!submitted)
                ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('إنهاء وحساب النتيجة'))
              else
                OutlinedButton(onPressed: () => setState(() { isExam = false; submitted = false; answers.clear(); }), child: const Text('خروج من الاختبار')),
            ],
          ]),
        ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: widget.questions.length,
          itemBuilder: (ctx, i) {
            final q = widget.questions[i];
            return QuestionCardWidget(
              questionData: q,
              correctAnswer: _getCorrect(q),
              onSave: () => widget.onSave(q),
              isExam: isExam,
              submitted: submitted,
              selected: answers[i],
              onSelect: (v) => setState(() => answers[i] = v),
            );
          },
        ),
      ),
    ]);
  }
}

class QuestionCardWidget extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final String correctAnswer;
  final VoidCallback onSave;
  final bool isExam, submitted;
  final String? selected;
  final Function(String)? onSelect;
  const QuestionCardWidget({super.key, required this.questionData, required this.correctAnswer, required this.onSave, this.isExam = false, this.submitted = false, this.selected, this.onSelect});
  @override
  State<QuestionCardWidget> createState() => _QuestionCardWidgetState();
}

class _QuestionCardWidgetState extends State<QuestionCardWidget> {
  String? localSel;
  bool localReveal = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.questionData;
    final opts = q['options'] ?? [];
    final shape = (q['shape'] ?? '').toString().trim().toLowerCase();
           final rawImg = (q['image'] ?? '').toString().trim();
        final img = rawImg.isEmpty ? '' : Uri.encodeFull(rawImg.startsWith('http') ? rawImg : ('https://' + 'cdn.jsdelivr.net/gh/alphasuper6-dev/alpha_super@main/image/' + rawImg));
    
    
    final exp = (q['explanation'] ?? '').toString();
    final activeSel = widget.isExam ? widget.selected : localSel;
    final showSol = widget.isExam ? widget.submitted : localReveal;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (q['year'] != null && q['year'].toString().isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Chip(label: Text('دورة ${q['year']}'))),
          if (shape.isNotEmpty) Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)), child: Center(child: CustomPaint(size: const Size(180, 140), painter: GeometryShapePainter(shape)))),
          if (img.isNotEmpty) Container(margin: const EdgeInsets.only(bottom: 10), child: Image.network(img, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          Text(q['question'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...opts.map<Widget>((o) {
            final t = o.toString();
            Color? col;
            if (showSol) {
              if (t == widget.correctAnswer) col = Colors.green.shade100;
              else if (t == activeSel) col = Colors.red.shade100;
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(8)),
              child: RadioListTile<String>(
                title: Text(t),
                value: t,
                groupValue: activeSel,
                onChanged: (widget.isExam && widget.submitted) ? null : (v) {
                  if (v == null) return;
                  widget.isExam ? widget.onSelect?.call(v) : setState(() => localSel = v);
                },
              ),
            );
          }),
          if (showSol)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الإجابة الصحيحة: ${widget.correctAnswer}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                if (exp.isNotEmpty) Text('الشرح: $exp'),
                              ]),
            ),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if (!widget.isExam) ElevatedButton.icon(onPressed: () => setState(() => localReveal = !localReveal), icon: Icon(localReveal ? Icons.visibility_off : Icons.visibility), label: Text(localReveal ? 'إخفاء الحل' : 'إظهار الحل')),
            OutlinedButton.icon(onPressed: widget.onSave, icon: const Icon(Icons.bookmark_add), label: const Text('حفظ السؤال')),
          ]),
        ]),
      ),
    );
  }
}

class GeometryShapePainter extends CustomPainter {
  final String shape;
  GeometryShapePainter(this.shape);
  void _lbl(Canvas c, String t, Offset o) => (TextPainter(text: TextSpan(text: t, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout()).paint(c, o);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Colors.indigo.shade800..strokeWidth = 2.2..style = PaintingStyle.stroke;
    final w = s.width, h = s.height;
    if (shape == 'triangle' || shape == 'مثلث') {
      c.drawPath(Path()..moveTo(w * 0.5, h * 0.1)..lineTo(w * 0.15, h * 0.88)..lineTo(w * 0.85, h * 0.88)..close(), p);
      _lbl(c, 'A', Offset(w * 0.48, h * 0.01)); _lbl(c, 'B', Offset(w * 0.08, h * 0.85)); _lbl(c, 'C', Offset(w * 0.87, h * 0.85));
    } else if (shape == 'circle' || shape == 'دائرة') {
      final ctr = Offset(w * 0.5, h * 0.5);
      c.drawCircle(ctr, h * 0.42, p); c.drawLine(ctr, Offset(ctr.dx + h * 0.42, ctr.dy), p);
      _lbl(c, 'O', Offset(ctr.dx - 12, ctr.dy - 14)); _lbl(c, 'R', Offset(ctr.dx + h * 0.2, ctr.dy - 18));
    } else if (shape == 'cone' || shape == 'مخروط') {
      final top = Offset(w * 0.5, h * 0.1);
      c.drawLine(top, Offset(w * 0.2, h * 0.8), p); c.drawLine(top, Offset(w * 0.8, h * 0.8), p);
      c.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.8), width: w * 0.6, height: h * 0.18), p);
      c.drawLine(top, Offset(w * 0.5, h * 0.8), p);
      _lbl(c, 'S', Offset(w * 0.48, h * 0.01)); _lbl(c, 'O', Offset(w * 0.44, h * 0.78)); _lbl(c, 'h', Offset(w * 0.52, h * 0.45));
    }
  }
  @override
  bool shouldRepaint(covariant GeometryShapePainter old) => old.shape != shape;
}
