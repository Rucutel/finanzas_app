import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../firestore/firestore_helper.dart';
import '../models/income.dart';
import '../models/expense.dart';

class ExcelService {
  Future<String> generateExcel() async {
    // Obtener MES y AÑO actuales
    final now = DateTime.now();
    final int mes = now.month;
    final int year = now.year;

    // Obtener datos desde Firestore FILTRADOS por mes
    final List<Income> incomes =
        await FirestoreHelper.getIncomesByMonthYear(mes, year);

    final List<Expense> expenses =
        await FirestoreHelper.getExpensesByMonthYear(mes, year);

    // Crear archivo Excel
    final Excel excel = Excel.createExcel();
    final DateFormat df = DateFormat('yyyy-MM-dd HH:mm');

    // ============================
    // 📄 HOJA: INGRESOS
    // ============================
    final Sheet sheetI = excel['Ingresos'];
    sheetI.appendRow(['ID', 'Monto', 'Descripción', 'Fecha']);

    for (var i in incomes) {
      sheetI.appendRow([
        i.id ?? '-',
        i.amount,
        i.description, // description no nullable en tu modelo
        df.format(i.date),
      ]);
    }

    // ============================
    // 📄 HOJA: GASTOS
    // ============================
    final Sheet sheetG = excel['Gastos'];
    sheetG.appendRow([
      'ID',
      'Categoría',
      'Subcategoría',
      'Monto',
      'Estado',
      'Fecha',
      'Nota'
    ]);

    for (var e in expenses) {
      sheetG.appendRow([
        e.id ?? '-',
        e.category,
        e.subcategory,
        e.amount,
        e.status,
        df.format(e.date),
        e.note ?? '',
      ]);
    }

    // ============================
    // 📄 HOJA: RESUMEN
    // ============================
    final Sheet sheetR = excel['Resumen'];

    double totalIngresos =
        incomes.fold(0.0, (sum, i) => sum + i.amount);

    double totalGastos =
        expenses.fold(0.0, (sum, e) => sum + e.amount);

    sheetR.appendRow(['Mes', mes]);
    sheetR.appendRow(['Año', year]);
    sheetR.appendRow([]);
    sheetR.appendRow(['Total Ingresos', totalIngresos]);
    sheetR.appendRow(['Total Gastos', totalGastos]);
    sheetR.appendRow(['Sobrante', totalIngresos - totalGastos]);

    // ============================
    // 💾 GUARDAR ARCHIVO
    // ============================
    final Directory directory =
        await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();

    // filename correctamente interpolado (sin saltos de línea)
    final String fileName =
        'finanzas_${year}_${mes}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

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
