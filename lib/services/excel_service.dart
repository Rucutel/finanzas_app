import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../database/db_helper.dart';
import '../models/income.dart';
import '../models/expense.dart';

class ExcelService {
  final DBHelper _db = DBHelper();

  Future<String> generateExcel() async {
    final List<Income> incomes = await _db.getAllIncomes();
    final List<Expense> expenses = await _db.getAllExpenses();

    final Excel excel = Excel.createExcel();
    final DateFormat df = DateFormat('yyyy-MM-dd HH:mm');

    // Hoja Ingresos
    final Sheet sheetI = excel['Ingresos'];
    sheetI.appendRow(['ID', 'Monto', 'Descripcion', 'Fecha']);
    for (var i in incomes) {
      sheetI.appendRow([i.id ?? 0, i.amount, i.description, df.format(i.date)]);
    }

    // Hoja Gastos
    final Sheet sheetG = excel['Gastos'];
    sheetG.appendRow(['ID', 'Categoria', 'Subcategoria', 'Monto', 'Estado', 'Fecha', 'Nota']);
    for (var e in expenses) {
      sheetG.appendRow([
        e.id,
        e.category,
        e.subcategory,
        e.amount,
        e.status,
        df.format(e.date),
        e.note ?? '',
      ]);
    }

    // Hoja Resumen
    final Sheet sheetR = excel['Resumen'];
    double totalIngresos = incomes.fold(0.0, (sum, i) => sum + i.amount);
    double totalGastos = expenses.fold(0.0, (sum, e) => sum + e.amount);
    sheetR.appendRow(['Total Ingresos', totalIngresos]);
    sheetR.appendRow(['Total Gastos', totalGastos]);
    sheetR.appendRow(['Sobrante', totalIngresos - totalGastos]);

    // Guardar archivo
    final Directory directory = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final String fileName = 'finanzas_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final String filePath = '${directory.path}/$fileName';

    final List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      final File file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(fileBytes);
    }

    return filePath;
  }
}
