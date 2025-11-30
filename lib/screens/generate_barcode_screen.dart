// lib/screens/generate_barcode_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../models/product_model.dart';
import '../models/barcode_model.dart';

class GenerateBarcodeScreen extends StatefulWidget {
  const GenerateBarcodeScreen({super.key});

  @override
  State<GenerateBarcodeScreen> createState() => _GenerateBarcodeScreenState();
}

class _GenerateBarcodeScreenState extends State<GenerateBarcodeScreen> {
  // Estado para el producto seleccionado (ahora guardamos el ID en lugar del objeto)
  String? _selectedProductId;
  Producto? _selectedProduct;
  String _generatedBarcodeValue = '';

  // Referencias de Firestore
  final productsRef = FirebaseFirestore.instance.collection('productos').withConverter<Producto>(
    fromFirestore: Producto.fromFirestore,
    toFirestore: (Producto product, _) => product.toFirestore(),
  );

  final barcodesRef = FirebaseFirestore.instance.collection('codigosDeBarras').withConverter<CodigoBarras>(
    fromFirestore: CodigoBarras.fromFirestore,
    toFirestore: (CodigoBarras barcode, _) => barcode.toFirestore(),
  );

  // --- Lógica de Generación del Código ---
  void _generateBarcode() {
    if (_selectedProduct == null) {
      setState(() {
        _generatedBarcodeValue = 'Selecciona un producto.';
      });
      return;
    }

    // Generación del código: Usamos el ID del documento para asegurar unicidad
    final newBarcodeValue = '${_selectedProduct!.sku}-${_selectedProduct!.id.substring(0, 4)}';

    setState(() {
      _generatedBarcodeValue = newBarcodeValue;
    });
  }

  // --- Lógica para Guardar en Firestore ---
  void _saveBarcode() async {
    if (_selectedProduct == null || _generatedBarcodeValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona y genera un código primero.')),
      );
      return;
    }

    try {
      // Verificar si ya existe un código para este producto
      final existingBarcode = await barcodesRef
          .where('productId', isEqualTo: _selectedProduct!.id)
          .limit(1)
          .get();

      if (existingBarcode.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este producto ya tiene un código de barras asignado.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final newBarcode = CodigoBarras(
        productId: _selectedProduct!.id,
        barcodeValue: _generatedBarcodeValue,
      );

      // Guardar en la colección 'codigosDeBarras'
      await barcodesRef.add(newBarcode);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código de barras guardado: $_generatedBarcodeValue'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpiar
      setState(() {
        _selectedProductId = null;
        _selectedProduct = null;
        _generatedBarcodeValue = '';
      });

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generar Código de Barras')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Selector de Producto ---
            const Text(
              '1. Elegir Producto:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot<Producto>>(
              stream: productsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'No hay productos disponibles. Agrega productos primero.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  );
                }

                // Obtener productos con sus IDs de documento
                final productsWithIds = snapshot.data!.docs.map((doc) {
                  final product = doc.data();
                  // Crear producto con todos los campos requeridos
                  return Producto(
                    id: doc.id,
                    nombre: product.nombre,
                    sabor: product.sabor,
                    pesoGramos: product.pesoGramos,
                    sku: product.sku,
                    categoria: product.categoria,
                  );
                }).toList();

                return DropdownButtonFormField<String>(
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  value: _selectedProductId,
                  hint: const Text('Selecciona un producto...'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: productsWithIds.map((Producto product) {
                    return DropdownMenuItem<String>(
                      value: product.id, // Usar el ID como value (único)
                      child: Text(
                        '${product.nombre} ${product.sabor} (${product.pesoGramos}g)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      // Buscar el producto completo por ID
                      final selected = productsWithIds.firstWhere((p) => p.id == newValue);
                      setState(() {
                        _selectedProductId = newValue;
                        _selectedProduct = selected;
                        _generatedBarcodeValue = ''; // Limpiar al cambiar
                      });
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // --- Botón Generar ---
            ElevatedButton.icon(
              onPressed: _generateBarcode,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generar Código'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 30),

            // --- Vista del Código de Barras Generado ---
            const Text(
              '2. Código de Barras Generado:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              height: 150,
              child: _generatedBarcodeValue.isNotEmpty && _selectedProduct != null
                  ? BarcodeWidget(
                barcode: Barcode.code128(),
                data: _generatedBarcodeValue,
                drawText: true,
                color: Colors.black,
                style: const TextStyle(fontSize: 14),
              )
                  : Center(
                child: Text(
                  _generatedBarcodeValue.isEmpty
                      ? 'Selecciona y genera un código.'
                      : _generatedBarcodeValue,
                  style: const TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Información del código ---
            if (_generatedBarcodeValue.isNotEmpty && _selectedProduct != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Producto: ${_selectedProduct!.nombre} ${_selectedProduct!.sabor}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('SKU: ${_selectedProduct!.sku}'),
                    Text('Código: $_generatedBarcodeValue'),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // --- Botón Guardar ---
            ElevatedButton.icon(
              onPressed: _saveBarcode,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Código y Vínculo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}