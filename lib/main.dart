import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'curriculum.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlphaSuperApp());
}

class AlphaSuperApp extends StatelessWidget {
  const AlphaSuperApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alpha Super',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const Directionality(textDirection: TextDirection.rtl, child: SplashOrHome()),
    );
  }
}

class SplashOrHome extends StatefulWidget {
  const SplashOrHome({super.key});
  @override
  State<SplashOrHome> createState() => _SplashOrHomeState();
}

class _SplashOrHomeState extends State<SplashOrHome> {
  bool? ok;
  String devId = "...";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    String id = "device";
    if (Platform.isAndroid) id = (await DeviceInfoPlugin().androidInfo).id;
    setState(() {
      devId = id;
      ok = p.getBool('activated') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ok == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return ok! ? HomeScreen(devId: devId) : ActivationScreen(devId: devId, onDone: () => setState(() => ok = true));
  }
}

class ActivationScreen extends StatefulWidget {
  final String devId;
  final VoidCallback onDone;
  const ActivationScreen({super.key, required this.devId, required this.onDone});
  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _c = TextEditingController();
  String _err = "";

  Future<void> _verify() async {
    final code = _c.text.trim().toUpperCase();
    if (code == "ALPHA2026" || code.startsWith("AS-")) {
      final p = await SharedPreferences.getInstance();
      await p.setBool('activated', true);
      widget.onDone();
    } else {
      setState(() => _err = "كود غير صالح! احصل على كودك من @AlphaSuperSy_bot");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تفعيل Alpha Super")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 64, color: Colors.indigo),
            const SizedBox(height: 12),
            const Text("الباقة الشاملة: تاسع + بكالوريا علمي وأدبي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("معرّف جهازك: ${widget.devId}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(controller: _c, decoration: const InputDecoration(labelText: "أدخل كود التفعيل", border: OutlineInputBorder())),
            if (_err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _verify, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)), child: const Text("تفعيل التطبيق")),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String devId;
  const HomeScreen({super.key, required this.devId});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _openAdminAuth() {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("لوحة الإدارة السرية"),
          content: TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "كلمة سر المدير (KHDR2026)")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () {
                if (passCtrl.text.trim() == "KHDR2026") {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: AdminGeneratorScreen())));
                }
              },
              child: const Text("دخول"),
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
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text("Alpha Super 2026"),
        actions: [
          IconButton(icon: const Icon(Icons.admin_panel_settings, color: Colors.amber), tooltip: "إدارة الأسئلة", onPressed: _openAdminAuth),
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم تحديث بنك الأسئلة بنجاح (Offline)"))),
            icon: const Icon(Icons.cloud_sync, color: Colors.white),
            label: const Text("تحديث", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stages.length,
        itemBuilder: (ctx, i) {
          final st = stages[i];
          final subs = syrianCurriculum2026[st]!;
          return Card(
            color: colors[i],
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(Icons.school, color: Colors.white, size: 32),
              title: Text(st, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
              subtitle: Text("${subs.length} مواد • منهاج 2026 المعتمد", style: const TextStyle(color: Colors.white70)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: SubjectsScreen(stage: st, subjects: subs, color: colors[i])))),
            ),
          );
        },
      ),
    );
  }
}

class SubjectsScreen extends StatelessWidget {
  final String stage;
  final Map<String, List<String>> subjects;
  final Color color;
  const SubjectsScreen({super.key, required this.stage, required this.subjects, required this.color});

  @override
  Widget build(BuildContext context) {
    final subNames = subjects.keys.toList();
    return Scaffold(
      appBar: AppBar(title: Text(stage), backgroundColor: color, foregroundColor: Colors.white),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
        itemCount: subNames.length,
        itemBuilder: (ctx, i) => Card(
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: UnitsScreen(stage: stage, subject: subNames[i], units: subjects[subNames[i]]!, color: color)))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, color: color, size: 32),
                const SizedBox(height: 8),
                Text(subNames[i], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("${subjects[subNames[i]]!.length} وحدات", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UnitsScreen extends StatelessWidget {
  final String stage, subject;
  final List<String> units;
  final Color color;
  const UnitsScreen({super.key, required this.stage, required this.subject, required this.units, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subject), backgroundColor: color, foregroundColor: Colors.white),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: units.length,
        itemBuilder: (ctx, i) => Card(
          child: ListTile(
            title: Text(units[i], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("أتمتة + مقالي مع سلم التصحيح"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: QuizScreen(unitKey: "$stage|$subject|${units[i]}", title: units[i], color: color)))),
          ),
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final String unitKey, title;
  final Color color;
  const QuizScreen({super.key, required this.unitKey, required this.title, required this.color});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> customQs = [];
  Map<int, int> selected = {};
  Map<int, bool> showRubric = {};

  @override
  void initState() {
    super.initState();
    _loadQs();
  }

  Future<void> _loadQs() async {
    final p = await SharedPreferences.getInstance();
    
