// lib/screens/products_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart'; // Para la acción de agregar

class ProductsScreen extends StatelessWidget {
  // Referencia a la colección 'productos' con el conversor (ProductModel)
  final productsRef = FirebaseFirestore.instance
      .collection('productos')
      .withConverter<Producto>(
    fromFirestore: Producto.fromFirestore,
    toFirestore: (Producto product, _) => product.toFirestore(),
  );
  @override
  Widget build(BuildContext context) {
    // Definimos el color secundario para los botones (Verde)
    final successColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot<Producto>>(
        // El Stream escucha continuamente los cambios en la colección
        stream: productsRef.snapshots(),
        builder: (context, snapshot) {
          // --- Manejo de Estados ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar productos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aún no hay productos registrados.'));
          }

          // Obtiene la lista de documentos (productos)
          final loadedProducts = snapshot.data!.docs.map((doc) => doc.data()).toList();

          // --- Estructura de la Tabla (DataTable) ---
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Permite desplazar horizontalmente si hay muchas columnas
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Theme.of(context).colorScheme.surface.withOpacity(0.5)),
                columns: const [
                  DataColumn(label: Text('NOMBRE', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('CATEGORÍA', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('PESO (G)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: loadedProducts.map((product) {
                  return DataRow(
                    cells: [
                      DataCell(Text('${product.nombre} ${product.sabor}')),
                      DataCell(Text(product.sku)),
                      // Chip para la Categoría (Estilo similar a la imagen)
                      DataCell(
                        Chip(
                          label: Text(product.categoria),
                          backgroundColor: product.categoria == 'Papas'
                              ? Colors.yellow.shade700 // Color para Papas
                              : Colors.orange.shade700, // Color para Chifles
                          labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(product.pesoGramos.toString())),
                      DataCell(
                        Row(
                          children: [
                            // Botón de Editar
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () {
                                // TODO: Implementar función de editar
                              },
                            ),
                            // Botón de Eliminar
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                _deleteProduct(context, product.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),

      // Botón flotante para agregar nuevos productos (con estilo verde de "Éxito/Venta")
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const AddProductScreen()),
          );
        },
        label: const Text('Nuevo Producto'),
        icon: const Icon(Icons.add_circle),
        backgroundColor: successColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  // --- Lógica de Eliminación (Delete) ---
  void _deleteProduct(BuildContext context, String productId) async {
    // Muestra una confirmación antes de eliminar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este producto?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await productsRef.doc(productId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado con éxito!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }
}