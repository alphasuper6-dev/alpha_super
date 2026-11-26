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
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Arial',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: SplashOrHome(),
      ),
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
  String deviceId = "جاري التحقق...";

  @override
  void initState() {
    super.initState();
    _checkActivation();
  }

  Future<void> _checkActivation() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceInfo = DeviceInfoPlugin();
    String id = "unknown";
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      id = androidInfo.id;
    }
    setState(() {
      deviceId = id;
      isActivated = prefs.getBool('activated') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isActivated == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return isActivated!
        ? HomeScreen(deviceId: deviceId)
        : ActivationScreen(
            deviceId: deviceId,
            onActivated: () => setState(() => isActivated = true),
          );
  }
}

class ActivationScreen extends StatefulWidget {
  final String deviceId;
  final VoidCallback onActivated;
  const ActivationScreen({super.key, required this.deviceId, required this.onActivated});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _codeController = TextEditingController();
  String _error = "";

  Future<void> _activate() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code == "ALPHA2026" || code.startsWith("AS-")) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('activated', true);
      await prefs.setString('bound_device', widget.deviceId);
      widget.onActivated();
    } else {
      setState(() => _error = "الكود غير صالح! تواصل مع بوت التلغرام للحصول على كود الباقة الشاملة (150 ألف) أو ادعُ 4 أصدقاء لكود مجاني.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تفعيل تطبيق Alpha Super")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 70, color: Colors.indigo),
            const SizedBox(height: 15),
            const Text("الباقة الشاملة (تاسع + بكالوريا علمي وأدبي)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("معرّف جهازك المقفل: ${widget.deviceId}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "أدخل كود التفعيل هنا",
                border: OutlineInputBorder(),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _activate,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("تفعيل الباقة على هذا الجهاز فقط", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String deviceId;
  const HomeScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final sections = ["التاسع الأساسي", "البكالوريا العلمي", "البكالوريا الأدبي"];
    return Scaffold(
      appBar: AppBar(title: const Text("Alpha Super - بدون إنترنت")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.school, color: Colors.indigo),
              title: Text(sections[index], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("أسئلة أتمتة + مقالي مع سلالم التصحيح الوزارية"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: QuestionSampleScreen(sectionTitle: sections[index]),
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

class QuestionSampleScreen extends StatefulWidget {
  final String sectionTitle;
  const QuestionSampleScreen({super.key, required this.sectionTitle});

  @override
  State<QuestionSampleScreen> createState() => _QuestionSampleScreenState();
}

class _QuestionSampleScreenState extends State<QuestionSampleScreen> {
  int? selectedOption;
  bool showRubric = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sectionTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("1. نموذج سؤال أتمتة (يعمل Offline):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text("تقع مدينة طرطوس على الساحل الشرقي للبحر:"),
            RadioListTile<int>(
              title: const Text("المتوسط"),
              value: 0,
              groupValue: selectedOption,
              onChanged: (v) => setState(() => selectedOption = v),
            ),
            RadioListTile<int>(
              title: const Text("الأحمر"),
              value: 1,
              groupValue: selectedOption,
              onChanged: (v) => setState(() => selectedOption = v),
            ),
            if (selectedOption != null)
              Text(
                selectedOption == 0 ? "✅ إجابة صحيحة!" : "❌ إجابة خاطئة، الصحيح: المتوسط",
                style: TextStyle(color: selectedOption == 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
              ),
            const Divider(height: 32),
            const Text("2. نموذج سؤال مقالي مع سلم التصحيح:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text("علّل: أهمية تنظيم الوقت لطلاب الشهادات؟"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => setState(() => showRubric = !showRubric),
              child: Text(showRubric ? "إخفاء سلم التصحيح" : "إظهار سلم التصحيح الوزاري"),
            ),
            if (showRubric)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                color: Colors.amber.shade50,
                child: const Text("سلم التصحيح (10 درجات):\n• استثمار الساعات الذهنية الصباحية (5 درجات).\n• مراجعة جميع الوحدات قبل الامتحان دون توتر (5 درجات)."),
              ),
          ],
        ),
      ),
    );
  }
}
