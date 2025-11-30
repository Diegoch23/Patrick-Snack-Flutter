import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/barcode_model.dart';
import '../models/inventory_model.dart';
import '../models/product_model.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String _scanResult = 'Presiona el botón para abrir el escáner.';
  bool _isLoading = false;

  // Controller para mobile_scanner (versión 7.1.3)
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final barcodesRef = FirebaseFirestore.instance.collection('codigosDeBarras')
      .withConverter<CodigoBarras>(
    fromFirestore: CodigoBarras.fromFirestore,
    toFirestore: (CodigoBarras barcode, _) => barcode.toFirestore(),
  );

  final inventoryRef = FirebaseFirestore.instance.collection('inventario')
      .withConverter<Inventario>(
    fromFirestore: Inventario.fromFirestore,
    toFirestore: (Inventario item, _) => item.toFirestore(),
  );

  final productsRef = FirebaseFirestore.instance.collection('productos')
      .withConverter<Producto>(
    fromFirestore: Producto.fromFirestore,
    toFirestore: (Producto product, _) => product.toFirestore(),
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // --- ABRIR PANTALLA DE ESCANEO ---
  Future<void> _openScanner() async {
    final String? scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => _BarcodeScannerPage(controller: _scannerController),
      ),
    );

    if (scannedCode == null || scannedCode.isEmpty) {
      if (mounted) setState(() => _scanResult = 'Escaneo cancelado.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _scanResult = 'Escaneado: $scannedCode';
      _isLoading = true;
    });

    await _processScan(scannedCode);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  // --- LÓGICA DE PROCESAMIENTO E INVENTARIO ---
  Future<void> _processScan(String barcodeValue) async {
    try {
      final barcodeQuery = await barcodesRef
          .where('barcodeValue', isEqualTo: barcodeValue)
          .limit(1)
          .get();

      if (barcodeQuery.docs.isEmpty) {
        if (mounted) setState(() => _scanResult = 'Error: Código no encontrado en la base de datos.');
        return;
      }

      final CodigoBarras scannedBarcode = barcodeQuery.docs.first.data();
      final String productId = scannedBarcode.productId;

      final productDoc = await productsRef.doc(productId).get();
      final Producto? product = productDoc.data();

      if (product == null) {
        if (mounted) setState(() => _scanResult = 'Error: Producto vinculado no encontrado.');
        return;
      }

      final inventoryQuery = await inventoryRef
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      final currentInventory = inventoryQuery.docs.isEmpty ? null : inventoryQuery.docs.first.data();
      final currentInventoryDocId = inventoryQuery.docs.isEmpty ? null : inventoryQuery.docs.first.id;

      await _showInventoryActionDialog(
        product: product,
        currentStock: currentInventory?.cantidadActual ?? 0,
        inventoryDocId: currentInventoryDocId,
        productId: productId,
      );

    } catch (e) {
      if (mounted) setState(() => _scanResult = 'Error de procesamiento: $e');
    }
  }

  // --- INTERFAZ MODULAR (AlertDialog) ---
  Future<void> _showInventoryActionDialog({
    required Producto product,
    required int currentStock,
    String? inventoryDocId,
    required String productId,
  }) async {
    bool isInput = true;
    final quantityController = TextEditingController(text: '1');

    if (mounted) setState(() => _scanResult = 'Escaneado: ${product.nombre}. Esperando acción...');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Producto: ${product.nombre} ${product.sabor}'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Stock Actual: $currentStock', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          context: context,
                          icon: Icons.add_circle,
                          label: 'ENTRADA',
                          isSelected: isInput,
                          color: Theme.of(context).colorScheme.secondary,
                          onTap: () => setStateDialog(() => isInput = true),
                        ),
                        const SizedBox(width: 10),
                        _buildActionButton(
                          context: context,
                          icon: Icons.remove_circle,
                          label: 'VENTA / SALIDA',
                          isSelected: !isInput,
                          color: Colors.red.shade700,
                          onTap: () => setStateDialog(() => isInput = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad a mover',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (mounted) setState(() => _scanResult = 'Acción cancelada.');
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateInventory(
                      isInput: isInput,
                      quantity: int.tryParse(quantityController.text) ?? 0,
                      currentStock: currentStock,
                      inventoryDocId: inventoryDocId,
                      productId: productId,
                      productName: product.nombre,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInput
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.red.shade700,
                  ),
                  child: Text(isInput ? 'Registrar ENTRADA' : 'Registrar VENTA'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.8) : Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _updateInventory({
    required bool isInput,
    required int quantity,
    required int currentStock,
    String? inventoryDocId,
    required String productId,
    required String productName,
  }) async {
    if (quantity <= 0) {
      _showSuccessMessage('Cantidad inválida. Operación cancelada.', Colors.orange);
      return;
    }

    int newQuantity = currentStock;
    String operation = isInput ? 'ENTRADA' : 'VENTA';
    Color color = isInput ? Theme.of(context).colorScheme.secondary : Colors.red.shade700;

    if (isInput) {
      newQuantity = currentStock + quantity;
    } else {
      if (currentStock < quantity) {
        _showSuccessMessage('Error: No hay suficiente stock para esta venta ($currentStock disponibles).', Colors.red);
        return;
      }
      newQuantity = currentStock - quantity;
    }

    try {
      if (inventoryDocId == null) {
        final newInventoryItem = Inventario(
          productId: productId,
          cantidadActual: newQuantity,
        );
        await inventoryRef.add(newInventoryItem);
      } else {
        await inventoryRef.doc(inventoryDocId).update({
          'cantidadActual': newQuantity,
          'ultimaActualizacion': FieldValue.serverTimestamp(),
        });
      }

      _showSuccessMessage('$operation de $quantity de $productName registrada. Nuevo stock: $newQuantity', color);

    } catch (e) {
      _showSuccessMessage('Error al actualizar inventario: $e', Colors.red);
    }
  }

  void _showSuccessMessage(String message, Color backgroundColor) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
    setState(() => _scanResult = 'Operación Finalizada.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escáner de Inventario')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _scanResult,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 50),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _openScanner,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Escanear Producto'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA DE ESCANEO CON MOBILE_SCANNER ---
class _BarcodeScannerPage extends StatefulWidget {
  final MobileScannerController controller;

  const _BarcodeScannerPage({required this.controller});

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  bool _hasScanned = false;
  bool _torchEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código'),
        actions: [
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: _torchEnabled ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              setState(() => _torchEnabled = !_torchEnabled);
              widget.controller.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => widget.controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: widget.controller,
            onDetect: (capture) {
              if (_hasScanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final barcode = barcodes.first;
              final String? code = barcode.rawValue;

              if (code != null && code.isNotEmpty) {
                setState(() => _hasScanned = true);
                Navigator.pop(context, code);
              }
            },
          ),
          // Overlay con línea de escaneo
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  height: 2,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          // Instrucciones
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                'Alinea el código de barras dentro del recuadro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}