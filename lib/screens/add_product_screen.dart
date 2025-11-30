// lib/screens/add_product_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart'; // Asegúrate de que la ruta sea correcta

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // Clave global para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _skuController = TextEditingController();
  final _nombreController = TextEditingController();
  final _pesoController = TextEditingController();

  // Opciones predefinidas para los Selectores (Dropdowns)
  final List<String> _categorias = ['Papas', 'Chifles'];
  final List<String> _sabores = ['Natural', 'Limón', 'Picante', 'Orégano'];

  String? _selectedCategoria;
  String? _selectedSabor;

  @override
  void dispose() {
    _skuController.dispose();
    _nombreController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  // Lógica para guardar en Firestore (Paso 3)
  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // 1. Crear el objeto Producto
      final newProduct = Producto(
        sku: _skuController.text,
        nombre: _nombreController.text,
        categoria: _selectedCategoria!,
        sabor: _selectedSabor!,
        pesoGramos: int.parse(_pesoController.text),
      );

      // 2. Obtener la referencia a la colección de Firestore
      final productsRef = FirebaseFirestore.instance
          .collection('productos')
          .withConverter(
        fromFirestore: Producto.fromFirestore,
        toFirestore: (Producto product, _) => product.toFirestore(),
      );

      // 3. Agregar el producto a Firestore
      try {
        await productsRef.add(newProduct);

        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto guardado con éxito!')),
        );
        // Limpiar el formulario y navegar atrás
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Nuevo Producto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU (Stock Keeping Unit)'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),

              // Selector de Categoría
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoría'),
                value: _selectedCategoria,
                items: _categorias.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategoria = newValue;
                  });
                },
                validator: (value) => value == null ? 'Selecciona una categoría' : null,
              ),

              // Selector de Sabor
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Sabor'),
                value: _selectedSabor,
                items: _sabores.map((String flavor) {
                  return DropdownMenuItem<String>(
                    value: flavor,
                    child: Text(flavor),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSabor = newValue;
                  });
                },
                validator: (value) => value == null ? 'Selecciona un sabor' : null,
              ),

              TextFormField(
                controller: _pesoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Peso (Gramos)'),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo requerido';
                  if (int.tryParse(value) == null) return 'Debe ser un número';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveProduct,
                child: const Text('Guardar Producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}