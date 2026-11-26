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
const String kToken = '';

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
    _syncCloud();
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
        Uri.parse('https://raw.githubusercontent.com/' + 'alphasuper6-dev/alpha_super/main/questions.json'),
      );
      if (res.statusCode == 200) {
        final raw = utf8.decode(res.bodyBytes);
        final p = await SharedPreferences.getInstance();
        await p.setString('offline_questions', raw);
        setState(() => allQs = jsonDecode(raw));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الأسئلة بنجاح!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر التحديث السحابي'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  bool _isStageUnlocked(String stageName) {
    if (widget.activeBranch == 'ALL') return true;
    if (widget.activeBranch == 'T9' && stageName.contains('التاسع')) return true;
    if ((widget.activeBranch == 'SC' || widget.activeBranch == 'SCI') && stageName.contains('العلمي')) return true;
    if ((widget.activeBranch == 'LT' || widget.activeBranch == 'LIT') && stageName.contains('الأدبي')) return true;
    return false;
  }

  void _adminLogin() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('دخول الإدارة'),
          content: TextField(controller: c, obscureText: true, decoration: const InputDecoration(hintText: 'كلمة المرور')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (c.text.trim() == 'KHDR2026') {
                  Navigator.pop(ctx);
                  _adminMenu();
                }
              },
              child: const Text('دخول'),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.indigo),
                title: const Text('إضافة أسئلة جديدة للسحابة'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.vpn_key, color: Colors.green),
                title: const Text('مولّد الأكواد السحابي'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CodeGeneratorScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stages = kCurriculum.keys.toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alpha Super 2026'),
          actions: [
            IconButton(
              icon: syncing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_download),
              onPressed: syncing ? null : _syncCloud,
            ),
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: _adminLogin,
            ),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stages.length,
          itemBuilder: (_, i) {
            final stage = stages[i];
            final unlocked = _isStageUnlocked(stage);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(unlocked ? Icons.lock_open : Icons.lock, color: unlocked ? Colors.green : Colors.grey),
                title: Text(stage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(unlocked ? 'مفعّل بالكامل' : 'مقفل (يتطلب كود هذا الفرع)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  if (!unlocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('هذا الفرع غير مشمول في كود التفعيل الخاص بك'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectsScreen(stageName: stage, subjects: kCurriculum[stage]!, allQs: allQs),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
