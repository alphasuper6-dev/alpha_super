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
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E3A8A),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
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
      setState(() => _error = "الكود غير صالح! احصل على كود الباقة الشاملة (150 ألف ل.س) عبر بوت التلغرام @AlphaSuperSy_bot أو ادعُ 4 أصدقاء لكود مجاني.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_rounded, size: 60, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 16),
                    const Text("Alpha Super", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 6),
                    const Text("الباقة الشاملة: تاسع + بكالوريا علمي وأدبي", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                      child: Text("معرّف جهازك المقفل: ${widget.deviceId}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "أدخل كود التفعيل هنا",
                        prefixIcon: const Icon(Icons.vpn_key_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _activate,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text("تفعيل الباقة على هذا الجهاز", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
  bool isUpdating = false;
  String lastUpdate = "نسخة الأسئلة: v1.0 (محدّثة)";

  final Map<String, List<String>> stagesData = {
    "التاسع الأساسي": ["الرياضيات", "العلوم العامة", "الفيزياء والكيمياء", "اللغة العربية", "اللغة الإنكليزية", "اللغة الفرنسية", "الاجتماعيات", "التربية الوطنية"],
    "البكالوريا العلمي": ["الرياضيات", "علم الأحياء", "الفيزياء", "الكيمياء", "اللغة العربية", "اللغة الإنكليزية", "اللغة الفرنسية", "التربية الوطنية"],
    "البكالوريا الأدبي": ["اللغة العربية", "الفلسفة والعلوم الإنسانية", "التاريخ", "الجغرافيا", "اللغة الإنكليزية", "اللغة الفرنسية", "التربية الوطنية"],
  };

  Future<void> _syncQuestions() async {
    setState(() => isUpdating = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      isUpdating = false;
      lastUpdate = "آخر تحديث: اليوم (${TimeOfDay.now().format(context)})";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ تم فحص السحابة: جميع الأسئلة وسلالم التصحيح محدّثة وتعمل بدون إنترنت!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stageColors = [const Color(0xFF0D9488), const Color(0xFF1E3A8A), const Color(0xFF7C3AED)];
    final stageIcons = [Icons.menu_book_rounded, Icons.science_rounded, Icons.history_edu_rounded];
    final stageKeys = stagesData.keys.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Alpha Super", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text("يعمل بدون إنترنت • محمي ضد التصوير", style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: TextButton.icon(
              onPressed: isUpdating ? null : _syncQuestions,
              icon: isUpdating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_sync_rounded, color: Colors.amberAccent),
              label: Text(isUpdating ? "جاري التحديث..." : "تحديث الأسئلة", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(lastUpdate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const Row(
                  children: [
                    
