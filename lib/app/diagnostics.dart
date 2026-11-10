import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../core/logger.dart';
import 'theme.dart' show webFontFamily;

/// Must match IdleOrbitApplication.CRASH_FILE on Android.
const _nativeCrashFile = 'last_native_crash.txt';

/// Returns (and deletes) the report of a JVM crash from the previous launch.
Future<String?> takeNativeCrashReport() async {
  if (kIsWeb || !Platform.isAndroid) return null;
  try {
    final dir = await getApplicationSupportDirectory();
    final f = File('${dir.path}/$_nativeCrashFile');
    if (!await f.exists()) return null;
    final text = await f.readAsString();
    await f.delete();
    return text;
  } catch (e, st) {
    log.error('Reading crash report failed', e, st);
    return null;
  }
}

String deviceSummary() {
  if (kIsWeb) return 'web';
  return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
}

/// Shown instead of the game when startup fails or hangs, so the player
/// (and we) can see what went wrong instead of an endless splash screen.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.report});
  final String report;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          fontFamily: kIsWeb ? webFontFamily : null),
      home: Scaffold(
        backgroundColor: const Color(0xFF070E22),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('起動中にエラーが発生しました',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('お手数ですが、下の「エラー内容をコピー」を押して開発者に送ってください。'),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black26,
                  child: SingleChildScrollView(
                    child: SelectableText(report,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) => FilledButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('エラー内容をコピー'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: report));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('コピーしました')));
                    }
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Dialog for a crash report from the previous launch.
Future<void> showCrashReportDialog(BuildContext context, String report) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('前回、アプリが異常終了しました'),
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: SingleChildScrollView(
          child: SelectableText(report,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: report));
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('コピーして閉じる'),
        ),
      ],
    ),
  );
}

/// Crash report from the previous launch, shown once by the home screen.
String? pendingCrashReport;
