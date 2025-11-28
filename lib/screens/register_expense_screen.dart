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
  String? _selectedStatus;

  final List<String> _categories = [
    'CASA',
    'TARJETAS',
    'CELULARES',
    'MOTO',
    'EXTRAS',
    'OTROS'
  ];

  final Map<String, List<String>> _subcategories = {
    'CASA': ['ALQUILER','DESAYUNO','ALMUERZO','DESPENSA','LIMPIEZA','GAS','INTERNET'],
    'TARJETAS': ['INTERBANK','RIPLEY','CMR'],
    'CELULARES': ['RUBEN','ALEXA'],
    'MOTO': ['MANTENIMIENTO','GASOLINA','REPUESTOS','SOAT','LICENCIA','REV. TECNICA'],
    'EXTRAS': ['KAREN','PASAJES','PASTILLAS','CREMAS','SALIDAS'],
    'OTROS': ['OTROS'],
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
      status: _selectedStatus!,   // ✔️ YA RESPETA EL VALOR ELEGIDO
      date: DateTime.now(),
      note: _noteCtrl.text,
    );

    try {
      await FirestoreHelper.addExpense(expense);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gasto registrado')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,   // ✔️ IMPORTANTE PARA EVITAR OVERFLOW
      appBar: AppBar(title: const Text('Registrar Gasto')),
      
      body: SingleChildScrollView(       // ✔️ AGREGO SCROLL
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  items: _subcategories[_selectedCategory]!
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedSubcategory = val),
                  validator: (v) => (v == null) ? 'Seleccione subcategoría' : null,
                ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'Pagado', child: Text('Pagado')),
                  DropdownMenuItem(value: 'Falta pagar', child: Text('Falta pagar')),
                ],
                onChanged: (val) => setState(() => _selectedStatus = val),
                validator: (v) => (v == null) ? 'Seleccione estado' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
