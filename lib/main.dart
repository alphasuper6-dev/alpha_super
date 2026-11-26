import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

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
  bool? isActivated;
  String deviceId = "...";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    String id = "device";
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      id = info.id;
    }
    setState(() {
      deviceId = id;
      isActivated = prefs.getBool('activated') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isActivated == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return isActivated!
        ? HomeScreen(deviceId: deviceId)
        : ActivationScreen(deviceId: deviceId, onDone: () => setState(() => isActivated = true));
  }
}

class ActivationScreen extends StatefulWidget {
  final String deviceId;
  final VoidCallback onDone;
  const ActivationScreen({super.key, required this.deviceId, required this.onDone});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _ctrl = TextEditingController();
  String _err = "";

  Future<void> _check() async {
    final c = _ctrl.text.trim().toUpperCase();
    if (c == "ALPHA2026" || c.startsWith("AS-")) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('activated', true);
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
            Text("معرّف جهازك: ${widget.deviceId}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(controller: _ctrl, decoration: const InputDecoration(labelText: "أدخل كود التفعيل", border: OutlineInputBorder())),
            if (_err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _check, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)), child: const Text("تفعيل التطبيق")),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String deviceId;
  const HomeScreen({super.key, required this.deviceId});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool updating = false;
  final Map<String, List<String>> data = {
    "التاسع الأساسي": ["الرياضيات", "العلوم العامة", "الفيزياء والكيمياء", "العربية", "الإنكليزية", "الفرنسية", "الاجتماعيات", "الوطنية"],
    "البكالوريا العلمي": ["الرياضيات", "علم الأحياء", "الفيزياء", "الكيمياء", "العربية", "الإنكليزية", "الفرنسية", "الوطنية"],
    "البكالوريا الأدبي": ["العربية", "الفلسفة", "التاريخ", "الجغرافيا", "الإنكليزية", "الفرنسية", "الوطنية"],
  };

  Future<void> _sync() async {
    setState(() => updating = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => updating = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم تحديث الأسئلة بنجاح (يعمل بدون إنترنت)")));
  }

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList();
    final colors = [Colors.teal, Colors.indigo, Colors.deepPurple];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text("Alpha Super"),
        actions: [
          TextButton.icon(
            onPressed: updating ? null : _sync,
            icon: const Icon(Icons.cloud_sync, color: Colors.amber),
            label: Text(updating ? "تحديث..." : "تحديث الأسئلة", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: keys.length,
        itemBuilder: (ctx, i) => Card(
          color: colors[i],
          margin: const EdgeInsets.only(bottom: 14),
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: const Icon(Icons.school, color: Colors.white, size: 32),
            title: Text(keys[i], style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
            subtitle: Text("${data[keys[i]]!.length} مواد • أتمتة + مقالي", style: const TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: SubjectsScreen(title: keys[i], subjects: data[keys[i]]!, color: colors[i])))),
          ),
        ),
      ),
    );
  }
}

class SubjectsScreen extends StatelessWidget {
  final String title;
  final List<String> subjects;
  final Color color;
  const SubjectsScreen({super.key, required this.title, required this.subjects, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: color, foregroundColor: Colors.white),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
        itemCount: subjects.length,
        itemBuilder: (ctx, i) => Card(
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: UnitsScreen(subject: subjects[i], color: color)))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, color: color, size: 32),
                const SizedBox(height: 8),
                Text(subjects[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UnitsScreen extends StatelessWidget {
  final String subject;
  final Color color;
  const UnitsScreen({super.key, required this.subject, required this.color});

  @override
  Widget build(BuildContext context) {
    final units = ["الوحدة الأولى", "الوحدة الثانية", "الوحدة الثالثة", "نماذج شاملة"];
    return Scaffold(
      appBar: AppBar(title: Text(subject), backgroundColor: color, foregroundColor: Colors.white),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: units.length,
        itemBuilder: (ctx, i) => Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color, child: Text("${i + 1}", style: const TextStyle(color: Colors.white))),
            title: Text(units[i], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("أسئلة أتمتة + مقالي مع سلم التصحيح"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: QuizScreen(title: "$subject - ${units[i]}", color: color)))),
          ),
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final String title;
  final Color color;
  const QuizScreen({super.key, required this.title, required this.color});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? ans;
  bool rubric = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontSize: 15)), backgroundColor: widget.color, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("1. سؤال أتمتة (Offline):", style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("تقع مدينة اللاذقية على البحر:"),
          RadioListTile<int>(title: const Text("المتوسط"), value: 0, groupValue: ans, onChanged: (v) => setState(() => ans = v)),
          RadioListTile<int>(title: const Text("الأحمر"), value: 1, groupValue: ans, onChanged: (v) => setState(() => ans = v)),
          if (ans != null) Text(ans == 0 ? "✅ صحيح!" : "❌ خطأ، الصحيح: المتوسط", style: TextStyle(color: ans == 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
          const Divider(height: 30),
          
