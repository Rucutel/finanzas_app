import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore/firestore_helper.dart';
import '../models/expense.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalIngresos = 0;
  double totalGastosPendientes = 0;
  double sobrante = 0;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final allIncomes = await FirestoreHelper.getIncomesByMonthYear(selectedMonth, selectedYear);
      final allExpenses = await FirestoreHelper.getExpensesByMonthYear(selectedMonth, selectedYear);

      setState(() {
        expenses = allExpenses;

        final totalIngresosCalc = allIncomes.fold(0.0, (s, i) => s + i.amount);
        final totalGastosPendientesCalc = expenses.where((e) => e.status == 'Falta pagar').fold(0.0, (s, e) => s + e.amount);
        final totalGastosCalc = expenses.fold(0.0, (s, e) => s + e.amount);

        totalIngresos = totalIngresosCalc;
        totalGastosPendientes = totalGastosPendientesCalc;
        sobrante = totalIngresosCalc - totalGastosCalc;
      });
    } catch (e) {
      print('Error cargando datos Dashboard: $e');
    }
  }

  String _format(double v) => NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ').format(v);

  @override
  Widget build(BuildContext context) {
    final Map<String, double> gastosPendientesPorCategoria = {};
    for (var e in expenses.where((e) => e.status == 'Falta pagar')) {
      gastosPendientesPorCategoria[e.category] = (gastosPendientesPorCategoria[e.category] ?? 0) + e.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => Navigator.pushNamed(context, '/excel'),
            tooltip: 'Exportar Excel',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/historial'),
            tooltip: 'Historial',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedMonth,
                    isExpanded: true,
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(DateFormat.MMMM('es_PE').format(DateTime(0, month))),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedMonth = val);
                        _loadSummary();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedYear,
                    isExpanded: true,
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedYear = val);
                        _loadSummary();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(child: ListTile(title: const Text('Total Ingresos'), trailing: Text(_format(totalIngresos)))),
            Card(child: ListTile(title: const Text('Gastos Pendientes'), trailing: Text(_format(totalGastosPendientes)))),
            Card(
              color: sobrante >= 0 ? Colors.green[50] : Colors.red[50],
              child: ListTile(title: const Text('Sobrante / Deuda'), trailing: Text(_format(sobrante))),
            ),
            const SizedBox(height: 20),
            if (gastosPendientesPorCategoria.isNotEmpty) ...[
              const Text('Resumen de gastos pendientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...gastosPendientesPorCategoria.entries.map((e) => Card(
                    color: Colors.orange[50],
                    child: ListTile(title: Text(e.key), trailing: Text(_format(e.value))),
                  )),
              const SizedBox(height: 20),
            ],
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Registrar Ingreso'),
              onPressed: () => Navigator.pushNamed(context, '/ingresos').then((_) => _loadSummary()),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Registrar Gasto'),
              onPressed: () => Navigator.pushNamed(context, '/register-expense').then((_) => _loadSummary()),
            ),
          ],
        ),
      ),
    );
  }
}
