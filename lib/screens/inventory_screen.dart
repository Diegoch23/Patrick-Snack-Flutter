import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';
import '../models/product_model.dart';

// --- Definición de la Pantalla de Inventario ---
class InventoryScreen extends StatelessWidget {
  InventoryScreen({super.key});

  // Referencias a Firestore
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

  // Mapa para guardar en caché los detalles del producto y evitar múltiples lecturas
  final Map<String, Producto> _productCache = {};

  // Función para obtener el detalle de un producto (o de la caché)
  Future<Producto?> _fetchProductDetails(String productId) async {
    if (_productCache.containsKey(productId)) {
      return _productCache[productId];
    }

    try {
      final doc = await productsRef.doc(productId).get();
      final product = doc.data();
      if (product != null) {
        _productCache[productId] = product;
      }
      return product;
    } catch (e) {
      // Manejar error si el producto no se encuentra
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos un color para el stock bajo (opcional)
    final lowStockColor = Colors.red.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Stock', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot<Inventario>>(
        stream: inventoryRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el inventario: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final inventoryItems = snapshot.data!.docs.map((doc) => doc.data()).toList();

          if (inventoryItems.isEmpty) {
            return const Center(
              child: Text('No hay productos registrados en el inventario.', style: TextStyle(fontSize: 18, color: Colors.white70)),
            );
          }

          // Usamos FutureBuilder para esperar los detalles de los productos
          return FutureBuilder<List<Producto?>>(
            future: Future.wait(
              inventoryItems.map((item) => _fetchProductDetails(item.productId)).toList(),
            ),
            builder: (context, productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (productSnapshot.hasError) {
                return Center(child: Text('Error al obtener detalles de productos: ${productSnapshot.error}'));
              }

              final productDetails = productSnapshot.data ?? [];

              // Crear la tabla con los datos combinados
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Theme.of(context).colorScheme.surface.withOpacity(0.5)),
                  columns: const [
                    DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('NOMBRE', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('SABOR', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('STOCK ACTUAL', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(inventoryItems.length, (index) {
                    final item = inventoryItems[index];
                    final product = productDetails[index];

                    // Colorear filas con stock bajo (ejemplo: stock < 10)
                    final isLowStock = item.cantidadActual < 10;

                    final rowColor = MaterialStateProperty.resolveWith<Color?>((states) {
                      if (isLowStock) {
                        return lowStockColor.withOpacity(0.2); // Fondo rojo claro
                      }
                      return null; // Color por defecto
                    });

                    return DataRow(
                      color: rowColor,
                      cells: [
                        DataCell(Text(product?.sku ?? 'N/D')),
                        DataCell(Text(product?.nombre ?? 'Producto Eliminado')),
                        DataCell(Text(product?.sabor ?? 'N/D')),
                        DataCell(
                          Text(
                            item.cantidadActual.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? lowStockColor : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              );
            },
          );
        },
      ),
    );
  }
}