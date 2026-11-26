import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'curriculum.dart';
import 'admin_screen.dart';
import 'code_generator_screen.dart';
import 'study_views.dart';

const String kOwner = 'alphasuper6-dev';
const String kRepo = 'alpha_super';
const String kToken = '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';

class HomeScreen extends StatefulWidget {
  final String devId;
  final String activeBranch;
  const HomeScreen({super.key, required this.devId, required this.activeBranch});
  @override
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
              leading: CircleAvatar(backgroundColor: unlocked ? col : Colors.grey, child: Icon(unlocked ? Icons.school : Icons.lock, color: Colors.white)),
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
