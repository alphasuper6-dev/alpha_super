import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'curriculum.dart';
import 'admin_screen.dart';
import 'code_generator_screen.dart';
import 'lesson_study_screen.dart';

// إعدادات مستودعك السحابي (ضع التوكن الخاص بك هنا لقفل الأكواد والتحديث)
const String kGithubOwner = 'alphasuper6-dev';
const String kGithubRepo = 'alpha_super';
const String kGithubToken = 'YOUR_GITHUB_READ_WRITE_TOKEN';

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
    if (Platform.isAndroid) {
      id = (await DeviceInfoPlugin().androidInfo).id;
    }
    setState(() {
      devId = id;
      ok = p.getBool('activated') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ok == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ok!
        ? HomeScreen(devId: devId)
        : ActivationScreen(
            devId: devId,
            onDone: () => setState(() => ok = true),
          );
  }
}

// 1. شاشة التفعيل مع قفل الكود بجهاز واحد (Device ID Lock)
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
  bool _loading = false;

  Future<void> _verify() async {
    final code = _c.text.trim().toUpperCase();
    if (code.isEmpty) return;

    // كود المدير التجريبي
    if (code == "ALPHA2026") {
      final p = await SharedPreferences.getInstance();
      await p.setBool('activated', true);
      widget.onDone();
      return;
    }

    setState(() {
      _loading = true;
      _err = "";
    });

    final String apiUrl =
        'https://github.com';

    try {
      final getRes = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $kGithubToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (getRes.statusCode != 200) {
        throw Exception("تعذر الاتصال بالسيرفر، تأكد من الإنترنت");
      }

      final fileData = jsonDecode(getRes.body);
      final String sha = fileData['sha'];
      final String contentStr = utf8.decode(
        base64Decode(fileData['content'].toString().replaceAll('\n', '')),
      );

      Map<String, dynamic> codesMap = jsonDecode(contentStr);

      if (!codesMap.containsKey(code)) {
        setState(() => _err = "كود غير صحيح! احصل على كودك من @AlphaSuperSy_bot");
        return;
      }

      final codeInfo = codesMap[code];
      String savedDevice = "";
      if (codeInfo is Map) {
        savedDevice = codeInfo['device_id']?.toString() ?? "";
      }

      // التحقق من قفل الجهاز الواحد
      if (savedDevice.isNotEmpty && savedDevice != widget.devId) {
        setState(() => _err = "عذراً! هذا الكود مستخدم ومقفل على جهاز آخر.");
        return;
      }

      // ربط الكود بهذا الجهاز حصراً ورفعه للسحابة
      codesMap[code] = {
        "status": "used",
        "device_id": widget.devId,
      };

      String updatedBase64 =
          base64Encode(utf8.encode(const JsonEncoder.withIndent('  ').convert(codesMap)));

      await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $kGithubToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'تفعيل كود على جهاز ${widget.devId}',
          'content': updatedBase64,
          'sha': sha,
        }),
      );

      final p = await SharedPreferences.getInstance();
      await p.setBool('activated', true);
      widget.onDone();
    } catch (e) {
      setState(() => _err = "حدث خطأ: تأكد من اتصالك بالإنترنت وحاول مجدداً");
    } finally {
      if (mounted) setState(() => _loading = false);
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
            const Text(
              "الباقة الشاملة: تاسع + بكالوريا علمي وأدبي",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "معرّف جهازك: ${widget.devId}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _c,
              decoration: const InputDecoration(
                labelText: "أدخل كود التفعيل (مثال: ALPHA-XXXX-XXXX)",
                border: OutlineInputBorder(),
              ),
            ),
            if (_err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _err,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verify,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("تفعيل التطبيق"),
                  ),
          ],
        ),
      ),
    );
  }
}

// 2. الشاشة الرئيسية للمراحل + التحديث السحابي + الأسئلة المحفوظة + لوحة الإدارة
class HomeScreen extends StatefulWidget {
  final String devId;
  const HomeScreen({super.key, required this.devId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> allCloudQuestions = [];
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineQuestions();
  }

  Future<void> _loadOfflineQuestions() async {
    final p = await SharedPreferences.getInstance();
    final savedJson = p.getString('offline_questions');
    if (savedJson != null && savedJson.isNotEmpty) {
      setState(() {
        allCloudQuestions = jsonDecode(savedJson);
      });
    }
  }

  Future<void> _syncQuestionsFromCloud() async {
    setState(() => syncing = true);
    final String apiUrl =
        'https://github.com';

    try {
      final res = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $kGithubToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (res.statusCode == 200) {
        final fileData = jsonDecode(res.body);
        final String decodedJson = utf8.decode(
          base64Decode(fileData['content'].toString().replaceAll('\n', '')),
        );
        final List<dynamic> parsed = jsonDecode(decodedJson);

        final p = await SharedPreferences.getInstance();
        await p.setString('offline_questions', decodedJson);

        setState(() => allCloudQuestions = parsed);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم تحديث الأسئلة بنجاح! (${parsed.length} سؤال جاهز بدون إنترنت)"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("فشل التحديث");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تعذر التحديث السحابي، تأكد من الاتصال بالإنترنت"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  void _openAdminAuth() {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("لوحة الإدارة السرية"),
          content: TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "كلمة سر المدير"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("إلغاء"),
            ),
            
