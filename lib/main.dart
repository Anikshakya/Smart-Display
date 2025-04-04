import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_display/widgets/custom_webview.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent> {
        LogicalKeySet(LogicalKeyboardKey.select) : const ActivateIntent(),
      },
      child:  MaterialApp(
        title: 'Codent Smart',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const WebView(
          title: "",
          websiteLink: "https://smart.codentinfo.com/",
        )
      )
    );
  }
}
