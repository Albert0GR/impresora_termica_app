import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

class UsbPrint {
  final FlutterThermalPrinter _printerPlugin = FlutterThermalPrinter.instance;

  /// Imprime el texto directamente en la impresora USB conectada
  Future<void> printText(String text) async {
    try {
      // Obtener la lista de impresoras USB conectadas
      await _printerPlugin.getPrinters(connectionTypes: [ConnectionType.USB]);
      final List<Printer> printers = await _printerPlugin.devicesStream.first;

      if (printers.isEmpty) {
        throw 'No se encontró ninguna impresora USB conectada.';
      }

      // Conectar con la primera impresora de la lista
      Printer selectedPrinter = printers.first;

      // Configurar e imprimir
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = generator.text(
        text,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      );

      // Añadir un salto de línea y cortar el papel
      bytes += generator.feed(2);
      bytes += generator.cut();

      // Enviar datos a la impresora
      await _printerPlugin.printData(
        selectedPrinter,
        bytes,
        longData: true,
      );
    } catch (e) {
      throw Exception('Error al imprimir el texto: $e');
    }
  }
}
