import 'package:flutter/material.dart';
import 'package:flutter_application_4/View/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgendaApp());
}

class AgendaApp extends StatelessWidget {
  const AgendaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Agenda de Contatos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const HomePage(),
      );
}
