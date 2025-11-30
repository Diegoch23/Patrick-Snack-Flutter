import 'package:cloud_firestore/cloud_firestore.dart';

class Inventario {
  // El ID del documento, si decides que sea diferente al ProductId
  String id;
  // ID del documento en la colección 'productos' (Clave de vinculación)
  final String productId;
  // Cantidad actual de stock
  final int cantidadActual;
  // Para saber cuándo fue la última entrada/salida
  final Timestamp? ultimaActualizacion;

  Inventario({
    this.id = '',
    required this.productId,
    required this.cantidadActual,
    this.ultimaActualizacion,
  });

  // Convertir a Firestore (Para guardar)
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'cantidadActual': cantidadActual,
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    };
  }

  // Crear Objeto desde Firestore (Para leer)
  factory Inventario.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return Inventario(
      id: snapshot.id,
      productId: data?['productId'] ?? '',
      cantidadActual: data?['cantidadActual'] ?? 0,
      ultimaActualizacion: data?['ultimaActualizacion'] as Timestamp?,
    );
  }
}