import 'package:flutter/material.dart';
import 'main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ important
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainPage(),
    );
  }
}
