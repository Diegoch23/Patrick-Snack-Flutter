import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Asegúrate de que las rutas sean correctas
import 'firebase_options.dart';
import 'screens/home_screen.dart'; // Usaremos HomeScreen como pantalla inicial

Future<void> main() async {
  // Asegura que los widgets de Flutter estén inicializados antes de inicializar Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la aplicación de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ejecuta la aplicación principal
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Definición de colores clave basados en tus imágenes
  static const Color darkBackground = Color(0xFF111827); // Fondo Oscuro Principal
  static const Color cardBackground = Color(0xFF1F2937); // Fondo de Contenedores/Cartas
  static const Color primaryBlue = Color(0xFF0D6EFD);    // Azul de Botones/Acción
  static const Color successGreen = Color(0xFF198754);  // Verde de Botones/Éxito

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patrick Snack App',

      // --- ELIMINA LA ETIQUETA 'DEBUG' ---
      debugShowCheckedModeBanner: false,

      // --- Tema Oscuro Personalizado ---
      theme: ThemeData(
        // Establece el esquema de colores principal
        colorScheme: const ColorScheme.dark(
          primary: primaryBlue,        // Color de elementos activos
          secondary: successGreen,     // Color secundario
          background: darkBackground,  // Fondo de la pantalla
          surface: cardBackground,     // Fondo de contenedores/cartas
          onSurface: Colors.white,     // Texto en superficies oscuras
        ),

        // Estilo de la AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBackground,
          elevation: 0,
        ),

        // Estilo de los Botones Elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue, // Botón principal azul
            foregroundColor: Colors.white, // Texto del botón blanco
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        // Estilo de texto general
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),

        scaffoldBackgroundColor: darkBackground, // Fondo del Scaffold
        useMaterial3: true,
      ),

      // --- Pantalla Inicial ---
      // Usamos HomeScreen, que contiene el Drawer con todas las opciones.
      home: const HomeScreen(),
    );
  }
}