import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'lesson_study_screen.dart';

class SubjectsScreen extends StatelessWidget {
  final String stageName;
  final Map<String, List<String>> subjectsMap;
  final List<dynamic> allQs;
  const SubjectsScreen({super.key, required this.stageName, required this.subjectsMap, required this.allQs});

  @override
  Widget build(BuildContext context) {
    final subs = subjectsMap.keys.toList();
    return Scaffold(
      appBar: AppBar(title: Text(stageName)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: subs.length,
        itemBuilder: (context, i) {
          final sub = subs[i];
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: UnitsScreen(
                    subjectName: sub,
                    units: subjectsMap[sub]!,
                    allQs: allQs,
                  ),
                ),
              ),
            ),
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, size: 38, color: Colors.indigo),
                  const SizedBox(height: 8),
                  Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class UnitsScreen extends StatelessWidget {
  final String subjectName;
  final List<String> units;
  final List<dynamic> allQs;
  const UnitsScreen({super.key, required this.subjectName, required this.units, required this.allQs});

  String _norm(String text) {
    return text
        .trim()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('الاولي', '1')
        .replaceAll('الأولي', '1')
        .replaceAll('الأولى', '1')
        .replaceAll('الثانيه', '2')
        .replaceAll('الثانية', '2')
        .replaceAll('الثالثه', '3')
        .replaceAll('الثالثة', '3')
        .replaceAll('الرابعه', '4')
        .replaceAll('الرابعة', '4')
        .replaceAll('الخامسه', '5')
        .replaceAll('الخامسة', '5')
        .replaceAll('السادسه', '6')
        .replaceAll('السادسة', '6')
        .replaceAll('السابعه', '7')
        .replaceAll('السابعة', '7')
        .replaceAll('الثامنه', '8')
        .replaceAll('الثامنة', '8')
        .replaceAll('التاسعه', '9')
        .replaceAll('التاسعة', '9')
        .replaceAll('العاشره', '10')
        .replaceAll('العاشرة', '10')
        .replaceAll('الحاديه عشره', '11')
        .replaceAll('الثانيه عشره', '12')
        .replaceAll('الثالثه عشره', '13');
  }

  @override
  Widget build(BuildContext context) {
    final targetSub = _norm(subjectName);
    return Scaffold(
      appBar: AppBar(title: Text(subjectName)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: units.length,
        itemBuilder: (context, i) {
          final u = units[i];
          final targetUnit = _norm(u);
          final uQs = allQs.where((q) {
            final qSub = _norm((q['subject'] ?? '').toString());
            final qUnit = _norm((q['unit'] ?? '').toString());
            final subMatch = qSub == targetSub || qSub.contains(targetSub) || targetSub.contains(qSub);
            final unitMatch = qUnit.isEmpty ||
                qUnit == targetUnit ||
                targetUnit.contains(qUnit) ||
                qUnit.contains(targetUnit);
            return subMatch && unitMatch;
          }).toList();

          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text("${i + 1}")),
              title: Text(u, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("الأسئلة: ${uQs.length}"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: LessonStudyScreen(
                      subjectName: subjectName,
                      lessonName: u,
                      allQuestions: uQs,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SavedQuestionsScreen extends StatefulWidget {
  const SavedQuestionsScreen({super.key});
  @override
  State<SavedQuestionsScreen> createState() => _SavedQuestionsScreenState();
}

class _SavedQuestionsScreenState extends State<SavedQuestionsScreen> {
  List<Map<String, dynamic>> list = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('saved_questions') ?? [];
    setState(() => list = raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الأسئلة المحفوظة")),
      body: list.isEmpty
          ? const Center(child: Text("لا توجد أسئلة محفوظة"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final q = list[i];
                return Card(
                  child: ListTile(
                    title: Text(q['question'] ?? ''),
                    subtitle: Text("الحل: ${q['answer']}\n${q['explanation'] ?? ''}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final p = await SharedPreferences.getInstance();
                        final raw = p.getStringList('saved_questions') ?? [];
                        raw.removeAt(i);
                        await p.setStringList('saved_questions', raw);
                        _load();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
