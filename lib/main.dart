import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'app_screens.dart';

final Uri kCodesUri = Uri.https('api.' + 'github.com', '/repos/alphasuper6-dev/alpha_super/contents/codes.json');

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
  String? activeBranch;
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
      activeBranch = p.getString('active_branch') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    if (activeBranch == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return activeBranch!.isNotEmpty
        ? HomeScreen(devId: devId, activeBranch: activeBranch!)
        : ActivationScreen(devId: devId, onDone: (branch) => setState(() => activeBranch = branch));
  }
}

class ActivationScreen extends StatefulWidget {
  final String devId;
  final Function(String) onDone;
  const ActivationScreen({super.key, required this.devId, required this.onDone});
  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _c = TextEditingController();
  String _err = "";
  String _msg = "";
  bool _loading = false;

  Future<void> _verify() async {
    final code = _c.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (code == "ALPHA2026") {
      final p = await SharedPreferences.getInstance();
      await p.setString('active_branch', 'ALL');
      widget.onDone('ALL');
      return;
    }

    setState(() {
      _loading = true;
      _err = "";
      _msg = "";
    });

    try {
      final res = await http.get(
        kCodesUri,
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

      String branch = "ALL";
      if (code.startsWith("T9-")) branch = "T9";
      else if (code.startsWith("SC-")) branch = "SC";
      else if (code.startsWith("LT-")) branch = "LT";

      codes[code] = {"status": "used", "device_id": widget.devId, "branch": branch};
      await http.put(
        kCodesUri,
        headers: {
          'Authorization': 'Bearer $kToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'تفعيل كود $branch',
          'content': base64Encode(utf8.encode(jsonEncode(codes))),
          'sha': sha,
        }),
      );

      final p = await SharedPreferences.getInstance();
      await p.setString('active_branch', branch);
      await p.setString('active_code', code);
      widget.onDone(branch);
    } catch (_) {
      setState(() => _err = "تأكد من الاتصال بالإنترنت وحاول مجدداً");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unbindCode() async {
    final code = _c.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _err = "أدخل الكود الأساسي أولاً لفك ربطه ونقله");
      return;
    }

    setState(() {
      _loading = true;
      _err = "";
      _msg = "";
    });

    try {
      final res = await http.get(
        kCodesUri,
        headers: {'Authorization': 'Bearer $kToken', 'Accept': 'application/vnd.github.v3+json'},
      );
      final data = jsonDecode(res.body);
      final sha = data['sha'];
      Map<String, dynamic> codes = jsonDecode(
        utf8.decode(base64Decode(data['content'].toString().replaceAll('\n', ''))),
      );

      if (!codes.containsKey(code)) {
        setState(() => _err = "الكود غير موجود!");
        return;
      }

      final info = codes[code];
      final savedDev = (info is Map) ? (info['device_id']?.toString() ?? "") : "";

      if (savedDev.isEmpty) {
        setState(() => _err = "هذا الكود غير مربوط بأي جهاز أصلاً!");
        return;
      }

      if (savedDev != widget.devId) {
        setState(() => _err = "لا يمكن فك الربط إلا من الجهاز الأساسي المفعل عليه الكود!");
        return;
      }

      String branch = (info is Map && info['branch'] != null) ? info['branch'] : "ALL";
      codes[code] = {"status": "unused", "device_id": "", "branch": branch};

      await http.put(
        kCodesUri,
        headers: {
          'Authorization': 'Bearer $kToken',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'فك ربط كود $code للنقل',
          'content': base64Encode(utf8.encode(jsonEncode(codes))),
          'sha': sha,
        }),
      );

      final p = await SharedPreferences.getInstance();
      await p.remove('active_branch');
      await p.remove('active_code');

      setState(() {
        _msg = "تم فك ربط الكود عن هذا الجهاز بنجاح! يمكنك الآن تفعيله على جهازك الجديد.";
      });
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
            const Text("منصة Alpha Super التعليمية - سوريا", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text("معرّف جهازك: ${widget.devId}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(
              controller: _c,
              decoration: const InputDecoration(
                labelText: "أدخل كود التفعيل (T9 / SC / LT)",
                border: OutlineInputBorder(),
              ),
            ),
            if (_err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_err, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            if (_msg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_msg, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _verify,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                        child: const Text("تفعيل التطبيق"),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _unbindCode,
                        icon: const Icon(Icons.phonelink_erase, color: Colors.orange),
                        label: const Text("فك ربط الكود (لنقل الحساب لجهاز جديد)"),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
