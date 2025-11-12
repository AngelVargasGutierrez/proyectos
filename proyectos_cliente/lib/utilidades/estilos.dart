import 'package:flutter/material.dart';

class Colores {
  static const Color primario = Color(0xFF1565C0);
  static const Color secundario = Color(0xFF0D47A1);
  static const Color acento = Color(0xFF42A5F5);
  static const Color fondo = Color(0xFFF5F5F5);
  static const Color blanco = Colors.white;
  static const Color negro = Color(0xFF212121);
  static const Color gris = Color(0xFF757575);
  static const Color grisClaro = Color(0xFFE0E0E0);
  static const Color exito = Color(0xFF4CAF50);
  static const Color advertencia = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
}

class Estilos {
  static const TextStyle titulo = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colores.negro,
  );

  static const TextStyle subtitulo = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colores.negro,
  );

  static const TextStyle cuerpo = TextStyle(
    fontSize: 16,
    color: Colores.negro,
  );

  static const TextStyle cuerpoSecundario = TextStyle(
    fontSize: 14,
    color: Colores.gris,
  );

  static const TextStyle boton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colores.blanco,
  );

  static const EdgeInsets paddingGeneral = EdgeInsets.all(16.0);
  static const EdgeInsets paddingPequeno = EdgeInsets.all(8.0);
  static const EdgeInsets paddingGrande = EdgeInsets.all(24.0);

  static const BorderRadius bordeRedondeado = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius bordeRedondeadoGrande = BorderRadius.all(Radius.circular(16.0));

  static BoxShadow get sombraCard => BoxShadow(
    color: Colors.grey.withOpacity(0.2),
    spreadRadius: 1,
    blurRadius: 4,
    offset: const Offset(0, 2),
  );
}