import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../firestore/firestore_helper.dart';
import '../models/expense.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Totales y filtros
  double totalIngresos = 0;
  double totalGastosPendientes = 0;
  double totalGastos = 0;
  double sobrante = 0;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // Datos
  List<Expense> expensesForFilter = []; // gastos que responden al filtro month/year
  List<double> gastosPorMes = List.filled(12, 0); // gráfico (año actual)

  bool mostrarPendientes = false;

  // Para controlar toque en barra y evitar spamear SnackBars
  int? _lastTouchedBarIndex;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  /// Carga datos necesarios:
  /// - gastosPorMes: siempre para el AÑO ACTUAL (no depende de los filtros)
  /// - totals & expensesForFilter: dependen de selectedMonth & selectedYear
  Future<void> _loadAll() async {
    await Future.wait([
      _loadGastosPorMesAnioActual(),
      _loadSummaryForFilter(),
    ]);
  }

  Future<void> _loadGastosPorMesAnioActual() async {
    try {
      final int anioActual = DateTime.now().year;
      final List<double> tmp = List.filled(12, 0);
      for (int m = 1; m <= 12; m++) {
        final gastosMes = await FirestoreHelper.getExpensesByMonthYear(m, anioActual);
        tmp[m - 1] = gastosMes.fold(0.0, (s, e) => s + e.amount);
      }
      setState(() {
        gastosPorMes = tmp;
      });
    } catch (e) {
      print('Error cargando gastos por mes (año actual): $e');
    }
  }

  Future<void> _loadSummaryForFilter() async {
    try {
      final incomes = await FirestoreHelper.getIncomesByMonthYear(selectedMonth, selectedYear);
      final expenses = await FirestoreHelper.getExpensesByMonthYear(selectedMonth, selectedYear);

      final totIngresos = incomes.fold(0.0, (s, i) => s + i.amount);
      final totGastos = expenses.fold(0.0, (s, e) => s + e.amount);
      final totPendientes = expenses.where((e) => e.status == 'Falta pagar').fold(0.0, (s, e) => s + e.amount);

      setState(() {
        totalIngresos = totIngresos;
        totalGastos = totGastos;
        totalGastosPendientes = totPendientes;
        sobrante = totIngresos - totGastos;
        expensesForFilter = expenses;
      });
    } catch (e) {
      print('Error cargando resumen para filtro: $e');
    }
  }

  String _format(double v) =>
    NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ', decimalDigits: 2).format(v);

  // --------------------------
  //  GRÁFICO PEQUEÑO 12 MESES
  // --------------------------
  Widget _buildGastosPorMesChart() {
    const meses = ["Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic"];

    return SizedBox(
      height: 160, // más pequeño, comparativo
      child: BarChart(
        BarChartData(
          maxY: (gastosPorMes.reduce((a,b) => a>b?a:b)) * 1.15, // un poco de margen; si todos 0, queda 0
          barGroups: List.generate(12, (i) {
            final value = gastosPorMes[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: const Color(0xFFEF5350), // rojo suave
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // sin montos laterales
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx > 11) return const SizedBox.shrink();
                  return Text(meses[idx], style: const TextStyle(fontSize: 11));
                },
                reservedSize: 28,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'S/ ${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            touchCallback: (event, response) {
              if (response == null || response.spot == null) return;

              final idx = response.spot!.touchedBarGroupIndex;
              final amount = gastosPorMes[idx];

              if (_lastTouchedBarIndex != idx) {
                _lastTouchedBarIndex = idx;

                if (amount > 0) {
                  final snack = SnackBar(
                    content: Text('${_monthNameShort(idx)} — S/ ${amount.toStringAsFixed(2)}'),
                    duration: const Duration(seconds: 2),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snack);
                } else {
                  const snack = SnackBar(
                    content: Text('No hubo gastos en ese mes'),
                    duration: Duration(seconds: 1),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snack);
                }

                Future.delayed(const Duration(milliseconds: 500), () {
                  _lastTouchedBarIndex = null;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  String _monthNameShort(int index) {
    const meses = ["Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic"];
    if (index < 0 || index >= 12) return '';
    return meses[index];
  }

  // --------------------------
  //  INTERFAZ
  // --------------------------
  @override
  Widget build(BuildContext context) {
    final gastosPendientesLista = expensesForFilter.where((e) => e.status == 'Falta pagar').toList();

    return Scaffold(
      appBar: AppBar(
      title: const Text('Dashboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.file_download),
          tooltip: 'Exportar Excel',
          onPressed: () => Navigator.pushNamed(context, '/excel'),
        ),
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Historial',
          onPressed: () => Navigator.pushNamed(context, '/historial'),
        ),
      ],
    ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---------- filtros (AFECTAN cajas y lista) ----------
            Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedMonth,
                    isExpanded: true,
                    items: List.generate(12, (i) {
                      final month = i + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(DateFormat.MMMM('es_PE').format(DateTime(0, month))),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedMonth = val);
                        _loadSummaryForSelected();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedYear,
                    isExpanded: true,
                    items: List.generate(5, (i) {
                      final year = DateTime.now().year - i;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedYear = val);
                        _loadSummaryForSelected();
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------- CARDS (orden requerido) ----------
            // 👉 Total ingresos 
            Card(
              color: Colors.lightBlue[50], // celeste pastel
              child: ListTile(
                title: const Text('Total Ingresos'),
                trailing: Text(_format(totalIngresos)),
              ),
            ),

            // 👉 Total gastos
            Card(
              child: ListTile(
                title: const Text('Total Gastos'),
                trailing: Text(_format(totalGastos)),
              ),
            ),

            // 👉 GASTOS PENDIENTES (cajón igual a los otros, sin negrita, sin flecha)
            GestureDetector(
              onTap: () {
                setState(() => mostrarPendientes = !mostrarPendientes);
              },
              child: Card(
                color: Colors.yellow[100], // pastel, como pediste
                child: ListTile(
                  title: const Text('Gastos Pendientes'),
                  
                  // monto a la derecha, igual que los otros cards
                  trailing: Text(
                    _format(totalGastosPendientes),
                  ),
                ),
              ),
            ),

            // 👉 sobrante / deuda
            Card(
              color: sobrante >= 0 ? Colors.green[50] : Colors.red[50],
              child: ListTile(
                title: const Text('Sobrante / Deuda'),
                trailing: Text(_format(sobrante)),
              ),
            ),

            const SizedBox(height: 16),

            // ---------- gráfico pequeño (NO afectado por filtros) ----------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Gastos por Mes', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    _buildGastosPorMesChart(),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ---------- BOTONES (mantengo su posición) ----------
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Registrar Ingreso'),
                    onPressed: () => Navigator.pushNamed(context, '/ingresos').then((_) => _loadSummaryForSelected()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Registrar Gasto'),
                    onPressed: () => Navigator.pushNamed(context, '/register-expense').then((_) => _loadSummaryForSelected()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (mostrarPendientes)
              ...gastosPendientesLista.map((e) => Card(
                    child: ListTile(
                      title: Text('${e.subcategory} - S/ ${e.amount.toStringAsFixed(2)}'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(e.date)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              backgroundColor: e.status == 'Falta pagar' ? Colors.red : Colors.grey[300],
                              foregroundColor: Colors.white,
                              minimumSize: const Size(40, 35),
                            ),
                            onPressed: () async {
                              if (e.id != null) {
                                await FirestoreHelper.updateExpenseStatus(e.id!, 'Falta pagar');
                                _loadSummaryForSelected();
                              }
                            },
                            child: const Text('FP'),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              backgroundColor: e.status == 'Pagado' ? Colors.green : Colors.grey[300],
                              foregroundColor: Colors.white,
                              minimumSize: const Size(40, 35),
                            ),
                            onPressed: () async {
                              if (e.id != null) {
                                await FirestoreHelper.updateExpenseStatus(e.id!, 'Pagado');
                                _loadSummaryForSelected();
                              }
                            },
                            child: const Text('P'),
                          ),
                        ],
                      ),
                    ),
                  )),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Llamada para recargar cuando cambian filtros (month/year)
  Future<void> _loadSummaryForSelected() async {
    try {
      final incomes = await FirestoreHelper.getIncomesByMonthYear(selectedMonth, selectedYear);
      final expenses = await FirestoreHelper.getExpensesByMonthYear(selectedMonth, selectedYear);

      setState(() {
        totalIngresos = incomes.fold(0.0, (s, i) => s + i.amount);
        totalGastos = expenses.fold(0.0, (s, e) => s + e.amount);
        totalGastosPendientes = expenses.where((e) => e.status == 'Falta pagar').fold(0.0, (s, e) => s + e.amount);
        sobrante = totalIngresos - totalGastos;
        expensesForFilter = expenses;
      });
    } catch (e) {
      print('Error recargando resumen: $e');
    }
  }
}