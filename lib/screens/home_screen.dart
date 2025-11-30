import 'package:flutter/material.dart';
import 'package:patrick_snack_app/screens/products_screen.dart';
import 'package:patrick_snack_app/screens/scanner_screen.dart';
import 'add_product_screen.dart';
import 'generate_barcode_screen.dart';
import 'inventory_screen.dart'; // Asegúrate de la ruta de tu pantalla

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patrick Snack - Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),

      // --- Navegador Lateral (Drawer) ---
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface, // Usa el color del fondo de contenido
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Encabezado del Drawer
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, // Azul principal
              ),
              child: const Text(
                'Menú Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),

            // Opción: Dashboard
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.white70),
              title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                // Aquí va la lógica para ir al Dashboard
              },
            ),
            // **NUEVA OPCIÓN: Ver Inventario/Stock**
            ListTile(
              leading: const Icon(Icons.inventory, color: Colors.white70),
              title: const Text('Ver Stock (Inventario)', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => InventoryScreen()),
                );
              },
            ),
            // **NUEVA OPCIÓN: Escáner de Códigos de Barras**
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.white70),
              title: const Text('Escáner de Inventario', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const ScannerScreen()),
                );
              },
            ),
            // **NUEVA OPCIÓN: Generar Código de Barras**
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: Colors.white70),
              title: const Text('Generar Código', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const GenerateBarcodeScreen()), // <-- Navega a la nueva pantalla
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: Colors.white70),
              title: const Text('Productos', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => ProductsScreen()), // <-- Navega a la lista
                );
              },
            ),
            // Opción: Agregar Producto (El fragmento de código que solicitaste)
            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.white70),
              title: const Text('Agregar Producto', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const AddProductScreen(), // Navega a la nueva pantalla
                  ),
                );
              },
            ),

          ],
        ),
      ),

      // --- Cuerpo de la Pantalla ---
      body: const Center(
        child: Text('Bienvenido al Sistema de Patrick Snack', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}