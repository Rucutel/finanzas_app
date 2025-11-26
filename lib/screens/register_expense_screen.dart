import 'package:flutter/material.dart';
import '../firestore/firestore_helper.dart';
import '../models/expense.dart';

class RegisterExpenseScreen extends StatefulWidget {
  const RegisterExpenseScreen({super.key});

  @override
  State<RegisterExpenseScreen> createState() => _RegisterExpenseScreenState();
}

class _RegisterExpenseScreenState extends State<RegisterExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedSubcategory;
  final List<String> _categories = ['Servicios', 'Compras', 'Transporte', 'Otros'];
  final Map<String, List<String>> _subcategories = {
    'Servicios': ['Agua', 'Luz', 'Internet', 'Otros'],
    'Compras': ['Supermercado', 'Ropa', 'Otros'],
    'Transporte': ['Taxi', 'Bus', 'Otros'],
    'Otros': ['Otros'],
  };

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final expense = Expense(
      category: _selectedCategory!,
      subcategory: _selectedSubcategory!,
      amount: double.parse(_amountCtrl.text),
      status: 'Falta pagar',
      date: DateTime.now(),
      note: _noteCtrl.text,
    );

    try {
      await FirestoreHelper.addExpense(expense);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gasto registrado')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Gasto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto'),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingrese monto' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                    _selectedSubcategory = null;
                  });
                },
                validator: (v) => (v == null) ? 'Seleccione categoría' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedCategory != null)
                DropdownButtonFormField<String>(
                  value: _selectedSubcategory,
                  decoration: const InputDecoration(labelText: 'Subcategoría'),
                  items: _subcategories[_selectedCategory]!.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedSubcategory = val),
                  validator: (v) => (v == null) ? 'Seleccione subcategoría' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}
