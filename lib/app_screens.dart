  Future<void> _confirmUnbindDevice() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فك ربط الجهاز / نقل الحساب'),
        content: const Text('هل أنت متأكد من فك ارتباط هذا الجهاز لنقل حسابك لجهاز آخر؟'),
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
      final token = p.getString('gh_token') ?? p.getString('github_token') ?? p.getString('token') ?? '';
      if (activeCode.isNotEmpty && token.isNotEmpty) {
        final headers = {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'AlphaSuperApp',
          'Authorization': 'Bearer $token',
        };
        final getUri = kCodesUri.replace(queryParameters: {'ref': 'main', 't': '${DateTime.now().millisecondsSinceEpoch}'});
        final res = await http.get(getUri, headers: headers);
        if (res.statusCode == 200) {
          final bodyJson = jsonDecode(res.body);
          final sha = bodyJson['sha'];
          final cleanB64 = bodyJson['content'].toString().replaceAll(RegExp(r'\s+'), '');
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
        MaterialPageRoute(builder: (_) => Directionality(textDirection: TextDirection.rtl, child: ActivationScreen(devId: widget.devId))),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
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
              leading: const Icon(Icons.add_circle, color: Colors.indigo),
              title: const Text('إضافة أسئلة جديدة للسحابة'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key, color: Colors.green),
              title: const Text('مولّد الأكواد السحابي'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => CodeGeneratorScreen()));
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
            tooltip: 'فك ربط الجهاز / نقل الحساب',
            icon: unbinding
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.phonelink_erase, color: Colors.redAccent),
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
              subtitle: Text(unlocked ? 'مفعّل بالكامل' : 'مقفل (يتطلب كود هذا الفرع)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                if (!unlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا القسم مقفل حسب كود التفعيل الخاص بك')));
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
