// lib/models/product_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Producto {
  // ID para Firestore (será el ID del documento, generado automáticamente)
  String id;

  // Identificador de stock, útil para la lógica del código de barras
  final String sku;

  // Caracteristicas del producto
  final String nombre;
  final String categoria; // Papas, Chifles, etc.
  final String sabor; // Limón, Picante, Natural, etc.
  final int pesoGramos; // 180, 150, etc.

  // Constructor
  Producto({
    this.id = '', // Por defecto vacío, se llenará al leer de Firestore
    required this.sku,
    required this.nombre,
    required this.categoria,
    required this.sabor,
    required this.pesoGramos,
  });

  // --- MÉTODOS DE CONVERSIÓN ---

  // 1. Convertir Objeto Producto a un mapa (JSON) para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'sku': sku,
      'nombre': nombre,
      'categoria': categoria,
      'sabor': sabor,
      'pesoGramos': pesoGramos,
    };
  }

  // 2. Crear Objeto Producto a partir de un Documento de Firestore
  factory Producto.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return Producto(
      id: snapshot.id, // Obtenemos el ID del documento
      sku: data?['sku'],
      nombre: data?['nombre'],
      categoria: data?['categoria'],
      sabor: data?['sabor'],
      pesoGramos: data?['pesoGramos'],
    );
  }
}