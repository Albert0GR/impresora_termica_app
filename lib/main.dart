import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
  final TextEditingController _textController = TextEditingController();

  List<Printer> printers = [];
  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startScan();
    });
  }

  @override
  void dispose() {
    _devicesStreamSubscription?.cancel();
    super.dispose();
  }

  // Start scanning for printers
  void startScan() async {
    _devicesStreamSubscription?.cancel();
    await _flutterThermalPrinterPlugin.getPrinters(connectionTypes: [
      ConnectionType.USB,
    ]);
    _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream
        .listen((List<Printer> event) {
      log(event.map((e) => e.name).toList().toString());
      setState(() {
        printers = event;
        printers.removeWhere(
            (printer) => printer.name == null || printer.name!.isEmpty);
      });
    });
  }

  // Stop scanning for printers
  void stopScan() {
    _flutterThermalPrinterPlugin.stopScan();
  }

  // Print text to a connected printer
  Future<void> printText(Printer printer, String text) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = generator.text(
        text,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.cut();
      await _flutterThermalPrinterPlugin.printData(printer, bytes);
    } catch (e) {
      log("Error printing text: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('USB Thermal Printer'),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Texto a imprimir',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: startScan,
              child: const Text('Escanear impresoras'),
            ),
            ElevatedButton(
              onPressed: stopScan,
              child: const Text('Detener escaneo'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: printers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(printers[index].name ?? 'Sin nombre'),
                    subtitle: Text(
                        "Conectada: ${printers[index].isConnected ?? false}"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        String text = _textController.text.trim();
                        if (text.isNotEmpty) {
                          printText(printers[index], text);
                        } else {
                          log('El texto está vacío. Ingresa algo para imprimir.');
                        }
                      },
                      child: const Text('Imprimir'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
