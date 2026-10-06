import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_transfer_app/app/app.dart';
import 'package:file_transfer_app/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await di.init();

  runApp(const App());
}
