import 'package:flutter/material.dart';
import '../firestore/firestore_helper.dart';
import '../models/income.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();

  String? _selectedPerson;
  String? _selectedCategory;

  final Map<String, List<String>> _categories = {
    'Alexa': ['Sueldo', 'CTS', 'AFP', 'Gratificación', 'Liquidación', 'Delivery', 'Encontrado', 'Otros'],
    'Rubén': ['Sueldo', 'CTS', 'AFP', 'Gratificación', 'Liquidación', 'Delivery', 'Encontrado', 'Otros'],
    'Otros': ['Otros'],
  };

  @override
  void dispose() {
    _amountCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String description = _selectedCategory!;
    if (_selectedCategory == 'Otros') description = _otherCtrl.text;

    final income = Income(
      amount: double.parse(_amountCtrl.text),
      description: description,
      date: DateTime.now(),
    );

    try {
      await FirestoreHelper.addIncome(income);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingreso registrado')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Ingreso')),
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
                value: _selectedPerson,
                decoration: const InputDecoration(labelText: 'Persona'),
                items: ['Alexa', 'Rubén', 'Otros'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPerson = val;
                    _selectedCategory = null;
                  });
                },
                validator: (v) => (v == null) ? 'Seleccione una persona' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedPerson != null)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categories[_selectedPerson]!.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  validator: (v) => (v == null) ? 'Seleccione una categoría' : null,
                ),
              const SizedBox(height: 16),
              if (_selectedCategory == 'Otros')
                TextFormField(
                  controller: _otherCtrl,
                  decoration: const InputDecoration(labelText: 'Especifique'),
                  validator: (v) {
                    if (_selectedCategory == 'Otros' && (v == null || v.isEmpty)) return 'Ingrese descripción';
                    return null;
                  },
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
