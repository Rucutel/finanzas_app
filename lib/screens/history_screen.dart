import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../firestore/firestore_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<Income> incomes = [];
  List<Expense> expenses = [];

  Set<String> selectedIncomeIds = {};
  Set<String> selectedExpenseIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final allIncomes = await FirestoreHelper.getIncomesByMonthYear(selectedMonth, selectedYear);
    final allExpenses = await FirestoreHelper.getExpensesByMonthYear(selectedMonth, selectedYear);

    setState(() {
      incomes = allIncomes;
      expenses = allExpenses;

      selectedIncomeIds.clear();
      selectedExpenseIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    for (var id in selectedIncomeIds) {
      await FirestoreHelper.deleteIncome(id);
    }
    for (var id in selectedExpenseIds) {
      await FirestoreHelper.deleteExpense(id);
    }
    _loadData();
  }

  Future<void> _changeExpenseStatus(String id, String newStatus) async {
    await FirestoreHelper.updateExpenseStatus(id, newStatus);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd', 'es_PE');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: selectedIncomeIds.isEmpty && selectedExpenseIds.isEmpty
                ? null
                : _deleteSelected,
            tooltip: 'Eliminar seleccionados',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Filtros Mes y Año
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
                      _loadData();
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
                      _loadData();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ingresos
          const Text('Ingresos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...incomes.map((i) => CheckboxListTile(
                value: selectedIncomeIds.contains(i.id),
                title: Text('S/ ${i.amount.toStringAsFixed(2)} - ${i.description}'),
                subtitle: Text(df.format(i.date)),
                onChanged: (val) {
                  setState(() {
                    if (val == true && i.id != null) selectedIncomeIds.add(i.id!);
                    else if (i.id != null) selectedIncomeIds.remove(i.id!);
                  });
                },
              )),
          const SizedBox(height: 12),
          // Gastos
          const Text('Gastos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...expenses.map((e) => ListTile(
                title: Text('${e.category} / ${e.subcategory} - S/ ${e.amount.toStringAsFixed(2)}'),
                subtitle: Row(
                  children: [
                    DropdownButton<String>(
                      value: e.status,
                      items: const [
                        DropdownMenuItem(value: 'Falta pagar', child: Text('Falta pagar')),
                        DropdownMenuItem(value: 'Pagado', child: Text('Pagado')),
                      ],
                      onChanged: (val) {
                        if (val != null && e.id != null) _changeExpenseStatus(e.id!, val);
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(df.format(e.date)),
                  ],
                ),
                trailing: Checkbox(
                  value: selectedExpenseIds.contains(e.id),
                  onChanged: (val) {
                    setState(() {
                      if (val == true && e.id != null) selectedExpenseIds.add(e.id!);
                      else if (e.id != null) selectedExpenseIds.remove(e.id!);
                    });
                  },
                ),
              )),
        ],
      ),
    );
  }
}
