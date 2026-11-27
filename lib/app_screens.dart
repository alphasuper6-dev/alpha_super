import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'curriculum.dart';
import 'admin_screen.dart';
import 'code_generator_screen.dart';
import 'study_views.dart';
import 'main.dart';
import 'pro_tools.dart';

const String kOwner = 'alphasuper6-dev';
const String kRepo = 'alpha_super';

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
  bool unbinding = false;

  @override
  void initState() {
    super.initState();
    _loadOffline();
    _syncCloud();
  }

  Future<void> _loadOffline() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('offline_questions');
    if (s != null && s.isNotEmpty) {
      setState(() => allQs = jsonDecode(s));
    }
  }

  Future<void> _syncCloud() async {
    setState(() => syncing = true);
    try {
      final p = await SharedPreferences.getInstance();
      final host = ['api', 'github', 'com'].join('.');
      final file = ['questions', 'json'].join('.');
      final ts = DateTime.now().millisecondsSinceEpoch;
      final url = Uri.parse(
        'https://$host/repos/$kOwner/$kRepo/contents/$file?t=$ts',
      );
      final res = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'AlphaSuperApp',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cleanBase64 = data['content'].toString().replaceAll('\n', '');
        final raw = utf8.decode(base64Decode(cleanBase64));
        await p.setString('offline_questions', raw);
        setState(() => allQs = jsonDecode(raw));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الأسئلة من السحابة بنجاح ✅')),
          );
        }
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر التحديث: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  Future<void> _confirmUnbindDevice() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فك ربط الجهاز / نقل الحساب'),
        content: const Text('هل تريد فك ربط هذا الجهاز لنقل حسابك لجهاز آخر؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، فك الربط'),
          ),
        ],
      ),
    );
    if (ok == true) await _unbindDevice();
  }

  Future<void> _unbindDevice() async {
    setState(() => unbinding = true);
    try {
      final p = await SharedPreferences.getInstance();
      final activeCode = p.getString('active_code') ?? '';
      final token = p.getString('gh_token') ?? '';
      if (activeCode.isNotEmpty && token.isNotEmpty) {
        final headers = {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'AlphaSuperApp',
          'Authorization': 'Bearer $token',
        };
        final getUri = kCodesUri.replace(queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'});
        final res = await http.get(getUri, headers: headers);
        if (res.statusCode == 200) {
          final bodyJson = jsonDecode(res.body);
          final sha = bodyJson['sha'];
          final cleanB64 = bodyJson['content'].toString().replaceAll('\n', '');
          final Map<String, dynamic> codesMap = jsonDecode(utf8.decode(base64Decode(cleanB64)));
          if (codesMap.containsKey(activeCode)) {
            final entry = Map<String, dynamic>.from(codesMap[activeCode]);
            entry['deviceId'] = '';
            entry['status'] = 'unused';
            codesMap[activeCode] = entry;
            await http.put(
              kCodesUri,
              headers: {...headers, 'Content-Type': 'application/json'},
              body: jsonEncode({
                'message': 'Unbind code $activeCode',
                'content': base64Encode(utf8.encode(const JsonEncoder.withIndent('  ').convert(codesMap))),
                'sha': sha,
              }),
            );
          }
        }
      }
      await p.remove('active_code');
      await p.remove('active_branch');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
                MaterialPageRoute(builder: (_) => const SplashGate()),
        
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => unbinding = false);
    }
  }
   bool _isStageUnlocked(String stageName) {
    final b = widget.activeBranch.toUpperCase();
    if (b == 'ALL') return true;
    if (b == 'T9' && stageName.contains('التاسع')) return true;
    if ((b == 'SCI' || b == 'SC') && stageName.contains('العلمي')) return true;
    if ((b == 'LIT' || b == 'LT') && stageName.contains('الأدبي')) return true;
    return false;
  }

  void _adminLogin() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('دخول الإدارة'),
        content: TextField(controller: c, obscureText: true, decoration: const InputDecoration(hintText: 'رمز الإدارة')),
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
    );
  }

  void _adminMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('إضافة أسئلة جديدة للسحابة'),
              onTap: () {
                Navigator.pop(ctx);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
                
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('مولّد الأكواد السحابي'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CodeGeneratorScreen()));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alpha Super 2026'),
        actions: [
          IconButton(
            tooltip: 'أدوات Alpha Super الذكية',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProToolsScreen(
                  allQs: allQs,
                  activeBranch: widget.activeBranch,
                  curriculum: syrianCurriculum2026,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'فك ربط الجهاز / نقل الحساب',
            icon: unbinding
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.phonelink_erase),
            onPressed: unbinding ? null : _confirmUnbindDevice,
          ),
          IconButton(
            tooltip: 'تحديث الأسئلة',
            icon: syncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_download),
            onPressed: syncing ? null : _syncCloud,
          ),
          IconButton(
            tooltip: 'الإدارة',
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
              title: Text(stage, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(unlocked ? 'مفعّل بالكامل' : 'مقفل - يتطلب كود هذا الفرع'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                if (!unlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('هذا القسم غير مفعّل لكودك الحالي!')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubjectsScreen(
                      stageName: stage,
                      subjectsMap: syrianCurriculum2026[stage]!,
                      allQs: allQs,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
