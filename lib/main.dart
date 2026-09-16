import 'package:flutter/material.dart';

import 'roost_app.dart';
import 'settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  runApp(const RoostApp());
}
