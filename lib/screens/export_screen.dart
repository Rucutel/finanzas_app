import 'package:flutter/material.dart';
import '../services/excel_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ExcelService _excel = ExcelService();
  bool _loading = false;
  String? _lastPath;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final path = await _excel.generateExcel();
      setState(() => _lastPath = path);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel guardado: $path')));
      // opcional: abrir el diálogo para compartir
      // await Share.shareFiles([path]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar a Excel'),
      ),
      body: Center(
        child: _loading
          ? const CircularProgressIndicator()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.file_download),
                  label: const Text('Generar Excel'),
                  onPressed: _generate,
                ),
                if (_lastPath != null) ...[
                  const SizedBox(height: 12),
                  SelectableText('Archivo: $_lastPath'),
                ]
              ],
            ),
      ),
    );
  }
}
