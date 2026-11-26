import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'app_screens.dart';

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
  bool _loading = false;

  Future<void> _verify() async {
    final code = _c.text.trim().toUpperCase();
    if (code.isEmpty) return;
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
    const url = 'https://github.com';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $kToken', 'Accept': 'application/vnd.github.v3+json'},
      );
      final data = jsonDecode(res.body);
      final sha = data['sha'];
      Map<String, dynamic> codes = jsonDecode(
        utf8.decode(base64Decode(data['content'].toString().replaceAll('\n', ''))),
      );
      if (!codes.containsKey(code)) {
        setState(() => _err = "كود غير صحيح! احصل على كودك من @AlphaSuperSy_bot");
        return;
      }
      final info = codes[code];
      final savedDev = (info is Map) ? (info['device_id']?.toString() ?? "") : "";
      if (savedDev.isNotEmpty && savedDev != widget.devId) {
        setState(() => _err = "هذا الكود مستخدم ومقفل على جهاز آخر!");
        return;
      }
      codes[code] = {"status": "used", "device_id": widget.devId};
      await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $kToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'تفعيل كود',
          'content': base64Encode(utf8.encode(jsonEncode(codes))),
          'sha': sha,
        }),
      );
      final p = await SharedPreferences.getInstance();
      await p.setBool('activated', true);
      widget.onDone();
    } catch (_) {
      setState(() => _err = "تأكد من الاتصال بالإنترنت وحاول مجدداً");
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
            const Text("الباقة الشاملة: تاسع + بكالوريا علمي وأدبي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("معرّف جهازك: ${widget.devId}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(controller: _c, decoration: const InputDecoration(labelText: "أدخل كود التفعيل", border: OutlineInputBorder())),
            if (_err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verify,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    child: const Text("تفعيل التطبيق"),
                  ),
          ],
        ),
      ),
    );
  }
}
