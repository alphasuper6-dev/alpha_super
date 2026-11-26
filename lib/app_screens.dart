import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'curriculum.dart';
import 'admin_screen.dart';
import 'code_generator_screen.dart';
import 'lesson_study_screen.dart';

const String kOwner = 'alphasuper6-dev';
const String kRepo = 'alpha_super';
const String kToken = 'YOUR_GITHUB_READ_WRITE_TOKEN';

class HomeScreen extends StatefulWidget {
  final String devId;
  final String activeBranch;
  const HomeScreen({super.key, required this.devId, required this.activeBranch});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

  
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> allQs = [];
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    _loadOffline();
  }

  Future<void> _loadOffline() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('offline_questions');
    if (s != null && s.isNotEmpty) setState(() => allQs = jsonDecode(s));
  }

  Future<void> _syncCloud() async {
    setState(() => syncing = true);
    try {
      final res = await http.get(
        Uri.parse('https://github.com'),
        headers: {'Authorization': 'Bearer $kToken', 'Accept': 'application/vnd.github.v3+json'},
      );
      if (res.statusCode == 200) {
        final raw = utf8.decode(base64Decode(jsonDecode(res.body)['content'].toString().replaceAll('\n', '')));
        final p = await SharedPreferences.getInstance();
        await p.setString('offline_questions', raw);
        setState(() => allQs = jsonDecode(raw));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث الأسئلة بنجاح!"), backgroundColor: Colors.green));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تعذر التحديث السحابي"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  bool _isStageUnlocked(String stageName) {
    if (widget.activeBranch == 'ALL') return true;
    if (widget.activeBranch == 'T9' && stageName.contains('التاسع')) return true;
    if (widget.activeBranch == 'SC' && stageName.contains('العلمي')) return true;
    if (widget.activeBranch == 'LT' && stageName.contains('الأدبي')) return true;
    return false;
  }

  void _adminLogin() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("دخول الإدارة"),
          content: TextField(controller: c, obscureText: true, decoration: const InputDecoration(labelText: "كلمة السر")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () {
                if (c.text.trim() == "KHDR2026") {
                  Navigator.pop(ctx);
                  _adminMenu();
                }
              },
              child: const Text("دخول"),
            ),
          ],
        ),
      ),
    );
  }

  void _adminMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.quiz, color: Colors.indigo),
              title: const Text("أداة إضافة الأسئلة"),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: AdminPanelScreen())));
              },
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key, color: Colors.teal),
              title: const Text("مولّد الأكواد حسب الفرع"),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: CodeGeneratorScreen())));
              },
            ),
          ],
        ),
      ),
    );
  }
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
  @override
  Widget build(BuildContext context) {
    final stages = syrianCurriculum2026.keys.toList();
    final colors = [Colors.teal, Colors.indigo, Colors.deepPurple];
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(onLongPress: _adminLogin, child: const Text("Alpha Super 2026")),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: SavedQuestionsScreen()))),
          ),
          syncing
              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(icon: const Icon(Icons.cloud_download), onPressed: _syncCloud),
          IconButton(icon: const Icon(Icons.admin_panel_settings), onPressed: _adminLogin),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stages.length,
        itemBuilder: (context, i) {
          final st = stages[i];
          final col = colors[i % colors.length];
          final unlocked = _isStageUnlocked(st);
          return Card(
            color: unlocked ? col.shade50 : Colors.grey.shade200,
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: CircleAvatar(
                backgroundColor: unlocked ? col : Colors.grey,
                child: Icon(unlocked ? Icons.school : Icons.lock, color: Colors.white),
              ),
              title: Text(st, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: unlocked ? col.shade900 : Colors.grey.shade700)),
              subtitle: Text(unlocked ? "مفعّل - اضغط لعرض المواد" : "مقفل - يتطلب كود هذا الفرع"),
              trailing: Icon(unlocked ? Icons.arrow_forward_ios : Icons.lock_outline),
              onTap: () {
                if (!unlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("كودك الحالي لا يشمل هذا الفرع!")));
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: SubjectsScreen(stageName: st, subjectsMap: syrianCurriculum2026[st]!, allQs: allQs))));
              },
            ),
          );
        },
      ),
    );
  }
}

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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2),
        itemCount: subs.length,
        itemBuilder: (context, i) {
          final sub = subs[i];
          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: UnitsScreen(subjectName: sub, units: subjectsMap[sub]!, allQs: allQs)))),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subjectName)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: units.length,
        itemBuilder: (context, i) {
          final u = units[i];
          final uQs = allQs.where((q) => q['subject'] == subjectName && q['unit'] == u).toList();
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text("${i + 1}")),
              title: Text(u, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("الأسئلة: ${uQs.length}"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: LessonStudyScreen(subjectName: subjectName, lessonName: u, allQuestions: uQs)))),
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

