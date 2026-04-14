import 'package:flutter/material.dart';
import 'package:help_me_app/config/router.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Help Me App',
      routerConfig: router,
    );
  }
}
