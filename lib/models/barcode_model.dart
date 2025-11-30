// lib/models/barcode_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CodigoBarras {
  String id; // ID del documento de Firestore
  final String productId; // ID del documento del producto al que pertenece
  final String barcodeValue; // El string que representa el código de barras (ej: PSN-001-1)

  CodigoBarras({
    this.id = '',
    required this.productId,
    required this.barcodeValue,
  });

  // Convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'barcodeValue': barcodeValue,
      'timestamp': FieldValue.serverTimestamp(), // Para saber cuándo se generó
    };
  }

  // Crear Objeto desde Firestore
  factory CodigoBarras.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return CodigoBarras(
      id: snapshot.id,
      productId: data?['productId'] ?? '',
      barcodeValue: data?['barcodeValue'] ?? '',
    );
  }
}