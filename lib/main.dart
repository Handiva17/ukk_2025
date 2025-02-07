import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://xcjjeyyivwuphgwbogsq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjampleXlpdnd1cGhnd2JvZ3NxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg3MTQxMDMsImV4cCI6MjA1NDI5MDEwM30.bzBuUkZ6OASDvdD955_WrQqEamGCytoVkGm9kIcGI9E',
  );
  runApp(MyApp());
}
        
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Kasir Handiva';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: LoginScreen(),
      ),
    );
  }
}
