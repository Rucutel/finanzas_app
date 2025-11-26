import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:finanzas_app/screens/dashboard_screen.dart';
import 'package:finanzas_app/screens/income_screen.dart';
import 'package:finanzas_app/screens/register_expense_screen.dart';
import 'package:finanzas_app/screens/export_screen.dart';
import 'package:finanzas_app/screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('es_PE', null); // Fechas en español
  runApp(const FinanzasApp());
}

class FinanzasApp extends StatelessWidget {
  const FinanzasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanzas App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/ingresos': (context) => const IncomeScreen(),
        '/register-expense': (context) => const RegisterExpenseScreen(),
        '/excel': (context) => const ExportScreen(),
        '/historial': (context) => const HistoryScreen(),
      },
    );
  }
}
