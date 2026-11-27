import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProToolsScreen extends StatefulWidget {
  final List<dynamic> allQs;
  final String activeBranch;
  final Map<String, Map<String, List<String>>> curriculum;

  const ProToolsScreen({
    super.key,
    required this.allQs,
    required this.activeBranch,
    required this.curriculum,
  });

  @override
  State<ProToolsScreen> createState() => _ProToolsScreenState();
}

class _ProToolsScreenState extends State<ProToolsScreen> {
  // 1. العداد التنازلي للامتحان
  DateTime _examDate = DateTime(2026, 6, 1, 8, 0);
  Timer? _timer;
  Duration _remaining = Duration.zero;

  // 2. البحث الفوري
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];

  // 3. حاسبة المعدل السوري (2400)
  final Map<String, TextEditingController> _gradeCtrls = {
    'الرياضيات (600)': TextEditingController(),
    'الفيزياء (400)': TextEditingController(),
    'الكيمياء (200)': TextEditingController(),
    'العلوم / الأحياء (300)': TextEditingController(),
    'اللغة العربية (400)': TextEditingController(),
    'اللغة الإنكليزية (300)': TextEditingController(),
    'التربية الوطنية / الدينية (200)': TextEditingController(),
  };
  double _totalScore = 0;
  double _percentage = 0;

  @override
  void initState() {
    super.initState();
    _loadExamDate();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  Future<void> _loadExamDate() async {
    final p = await SharedPreferences.getInstance();
    final savedMillis = p.getInt('custom_exam_date');
    if (savedMillis != null) {
      setState(() {
        _examDate = DateTime.fromMillisecondsSinceEpoch(savedMillis);
      });
    }
    _updateTimer();
  }

  void _updateTimer() {
    final now = DateTime.now();
    setState(() {
      _remaining = _examDate.isAfter(now) ? _examDate.difference(now) : Duration.zero;
    });
  }

  Future<void> _pickExamDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate.isAfter(DateTime.now()) ? _examDate : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final newDate = DateTime(picked.year, picked.month, picked.day, 8, 0);
      final p = await SharedPreferences.getInstance();
      await p.setInt('custom_exam_date', newDate.millisecondsSinceEpoch);
      setState(() {
        _examDate = newDate;
      });
      _updateTimer();
    }
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _searchResults = widget.allQs.where((item) {
        final questionText = (item['question'] ?? '').toString().toLowerCase();
        final subjectText = (item['subject'] ?? '').toString().toLowerCase();
        return questionText.contains(q) || subjectText.contains(q);
      }).toList();
    });
  }

  void _calculateAverage() {
    double sum = 0;
    for (final ctrl in _gradeCtrls.values) {
      sum += double.tryParse(ctrl.text.trim()) ?? 0;
    }
    setState(() {
      _totalScore = sum;
      _percentage = (sum / 2400.0) * 100;
    });
  }

  void _startMixedExam() {
    if (widget.allQs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أسئلة محمّلة حالياً! اضغط تحديث الأسئلة أولاً.')),
      );
      return;
    }
    final shuffled = List<dynamic>.from(widget.allQs)..shuffle(Random());
    final examQs = shuffled.take(min(20, shuffled.length)).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QuickMixedExamScreen(questions: examQs),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchCtrl.dispose();
    for (final c in _gradeCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('أدوات Alpha Super الذكية'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.timer), text: 'العداد التنازلي'),
              Tab(icon: Icon(Icons.quiz), text: 'اختبار شامل'),
              Tab(icon: Icon(Icons.search), text: 'البحث الفوري'),
              Tab(icon: Icon(Icons.calculate), text: 'حاسبة المعدل'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // التبويب 1: العداد التنازلي
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_bottom, size: 64, color: Colors.indigo),
                  const SizedBox(height: 16),
                  const Text(
                    'الوقت المتبقي للامتحان النهائي',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _timeBox('$days', 'يوم'),
                      _timeBox('$hours', 'ساعة'),
                      _timeBox('$minutes', 'دقيقة'),
                      _timeBox('$seconds', 'ثانية'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _pickExamDate,
                    icon: const Icon(Icons.edit_calendar),
                    label: Text(
                      'تعديل تاريخ الامتحان (${_examDate.year}/${_examDate.month}/${_examDate.day})',
                    ),
                  ),
                ],
              ),
            ),

            // التبويب 2: الاختبار الشامل المختلط
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology, size: 70, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  const Text(
                    'الاختبار الشامل المختلط',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'يختار لك التطبيق 20 سؤالاً عشوائياً من جميع المواد المتاحة (${widget.allQs.length} سؤال) لاختبار جاهزيتك الفورية.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _startMixedExam,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('ابدأ الاختبار الشامل الآن'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),

            // التبويب 3: البحث الفوري بكل الأسئلة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن أي سؤال أو مادة...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              _searchCtrl.text.isEmpty
                                  ? 'اكتب كلمة للبحث في ${widget.allQs.length} سؤال'
                                  : 'لا توجد نتائج مطابقة',
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (_, i) {
                              final q = _searchResults[i];
                              final opts = (q['options'] as List?) ?? [];
                              final cIdx = q['correctIndex'] ?? 0;
                              final ans = (cIdx >= 0 && cIdx < opts.length) ? opts[cIdx] : '';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(q['question'] ?? ''),
                                  subtitle: Text(
                                    'المادة: ${q['subject'] ?? ''} | الجواب الصحيح: $ans',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // التبويب 4: حاسبة المعدل السوري (2400)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'المجموع: ${_totalScore.toStringAsFixed(1)} / 2400',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'النسبة المئوية: ${_percentage.toStringAsFixed(2)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._gradeCtrls.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: entry.value,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _calculateAverage(),
                      decoration: InputDecoration(
                        labelText: entry.key,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _timeBox(String val, String label) {
  return Container(
    width: 72,
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.indigo,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    ),
  );
}
}

class _QuickMixedExamScreen extends StatefulWidget {
final List<dynamic> questions;
const _QuickMixedExamScreen({required this.questions});

@override
State<_QuickMixedExamScreen> createState() => _QuickMixedExamScreenState();
}

class _QuickMixedExamScreenState extends State<_QuickMixedExamScreen> {
final Map<int, int> _selected = {};
bool _submitted = false;

@override
Widget build(BuildContext context) {
  int score = 0;
  if (_submitted) {
    for (int i = 0; i < widget.questions.length; i++) {
      if (_selected[i] == widget.questions[i]['correctIndex']) score++;
    }
  }

  return Scaffold(
    appBar: AppBar(title: const Text('الاختبار الشامل السريع')),
    body: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.questions.length + 1,
      itemBuilder: (_, i) {
        if (i == widget.questions.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _submitted
                ? Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'نتيجتك: $score من ${widget.questions.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => setState(() => _submitted = true),
                    child: const Text('إنهاء وعرض النتيجة'),
                  ),
          );
        }

        final q = widget.questions[i];
        final opts = (q['options'] as List?) ?? [];
        final correctIdx = q['correctIndex'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. ${q['question'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(opts.length, (optIdx) {
                  Color? tileColor;
                  if (_submitted) {
                    if (optIdx == correctIdx) tileColor = Colors.green.shade100;
                    else if (_selected[i] == optIdx) tileColor = Colors.red.shade100;
                  }
                  return Container(
                    color: tileColor,
                    child: RadioListTile<int>(
                      value: optIdx,
                      groupValue: _selected[i],
                      title: Text(opts[optIdx].toString()),
                      onChanged: _submitted ? null : (val) => setState(() => _selected[i] = val!),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    ),
  );
}
}
