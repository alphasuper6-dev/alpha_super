import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'app_screens.dart';

final Uri kCodesUri = Uri.https(
  'api.' + 'github.com',
  '/repos/alphasuper6-dev/alpha_super/contents/codes.json',
);

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
        child: SplashGate(),
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<String> _getDeviceId() async {
    final p = await SharedPreferences.getInstance();
    String? savedId = p.getString('saved_device_id');
    if (savedId != null && savedId.isNotEmpty) return savedId;

    final info = DeviceInfoPlugin();
    String id = 'DEV-${DateTime.now().millisecondsSinceEpoch}';
    try {
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        id = android.id;
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        id = ios.identifierForVendor ?? id;
      }
    } catch (_) {}
    await p.setString('saved_device_id', id);
    return id;
  }

  Future<void> _checkSession() async {
    final p = await SharedPreferences.getInstance();
    final devId = await _getDeviceId();
    final savedBranch = p.getString('active_branch');
    final savedCode = p.getString('active_code');

    if (!mounted) return;
    if (savedBranch != null && savedBranch.isNotEmpty && savedCode != null && savedCode.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: HomeScreen(devId: devId, activeBranch: savedBranch),
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: ActivationScreen(devId: devId),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class ActivationScreen extends StatefulWidget {
  final String devId;
  const ActivationScreen({super.key, required this.devId});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  Future<String?> _getStoredToken(SharedPreferences p) async {
    return p.getString('gh_token') ??
        p.getString('github_token') ??
        p.getString('token');
  }

  Future<void> _activate() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _loading = true);
    try {
      final p = await SharedPreferences.getInstance();
      final token = await _getStoredToken(p);

      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'AlphaSuperApp',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final getUri = kCodesUri.replace(queryParameters: {
        'ref': 'main',
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final res = await http.get(getUri, headers: headers);
      if (res.statusCode != 200) {
        throw Exception('فشل الاتصال بالسحابة (${res.statusCode})');
      }

      final bodyJson = jsonDecode(res.body);
      final sha = bodyJson['sha'];
      final cleanB64 = bodyJson['content'].toString().replaceAll(RegExp(r'\s+'), '');
      final Map<String, dynamic> codesMap = jsonDecode(utf8.decode(base64Decode(cleanB64)));

      if (!codesMap.containsKey(code)) {
        throw Exception('كود التفعيل غير صحيح!');
      }

      final entry = Map<String, dynamic>.from(codesMap[code]);
      final boundDevice = (entry['deviceId'] ?? '').toString();
      final branch = (entry['branch'] ?? 'ALL').toString();

      if (boundDevice.isNotEmpty && boundDevice != widget.devId) {
        throw Exception('هذا الكود مرتبط بجهاز آخر! يجب فك ربطه من الجهاز القديم أولاً.');
      }

      if (boundDevice.isEmpty && token != null && token.isNotEmpty) {
        entry['deviceId'] = widget.devId;
        entry['status'] = 'used';
        codesMap[code] = entry;

        final updatedContent = base64Encode(utf8.encode(const JsonEncoder.withIndent('  ').convert(codesMap)));
        final putRes = await http.put(
          kCodesUri,
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': 'Bind code $code',
            'content': updatedContent,
            'sha': sha,
          }),
        );
        if (putRes.statusCode != 200 && putRes.statusCode != 201) {
          throw Exception('تعذر ربط الجهاز بالسحابة (${putRes.statusCode})');
        }
      }

      await p.setString('active_code', code);
      await p.setString('active_branch', branch);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: HomeScreen(devId: widget.devId, activeBranch: branch),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفعيل تطبيق Alpha Super')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 72, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text(
              'أدخل كود التفعيل الخاص بك',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('معرّف جهازك: ${widget.devId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: _codeCtrl,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'مثال: SCI-XXXX-XXXX',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _activate,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('تفعيل الدخول', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
