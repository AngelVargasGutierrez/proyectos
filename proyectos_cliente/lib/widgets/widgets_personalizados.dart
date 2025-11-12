import 'package:flutter/material.dart';
import '../utilidades/estilos.dart';

class BotonPersonalizado extends StatelessWidget {
  final String texto;
  final VoidCallback? alPresionar;
  final bool cargando;
  final Color? color;
  final double? ancho;

  const BotonPersonalizado({
    super.key,
    required this.texto,
    this.alPresionar,
    this.cargando = false,
    this.color,
    this.ancho,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho ?? double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: cargando ? null : alPresionar,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colores.primario,
          foregroundColor: Colores.blanco,
          shape: RoundedRectangleBorder(
            borderRadius: Estilos.bordeRedondeado,
          ),
          elevation: 2,
        ),
        child: cargando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colores.blanco),
                ),
              )
            : Text(
                texto,
                style: Estilos.boton,
              ),
      ),
    );
  }
}

class CampoTextoPersonalizado extends StatelessWidget {
  final String etiqueta;
  final String? sugerencia;
  final TextEditingController? controlador;
  final String? Function(String?)? validador;
  final bool obscureText;
  final TextInputType? tipoTeclado;
  final Widget? iconoPrefijo;
  final Widget? iconoSufijo;
  final int maxLineas;

  const CampoTextoPersonalizado({
    super.key,
    required this.etiqueta,
    this.sugerencia,
    this.controlador,
    this.validador,
    this.obscureText = false,
    this.tipoTeclado,
    this.iconoPrefijo,
    this.iconoSufijo,
    this.maxLineas = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: Estilos.cuerpo.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controlador,
          validator: validador,
          obscureText: obscureText,
          keyboardType: tipoTeclado,
          maxLines: maxLineas,
          decoration: InputDecoration(
            hintText: sugerencia,
            prefixIcon: iconoPrefijo,
            suffixIcon: iconoSufijo,
            border: OutlineInputBorder(
              borderRadius: Estilos.bordeRedondeado,
              borderSide: const BorderSide(color: Colores.grisClaro),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: Estilos.bordeRedondeado,
              borderSide: const BorderSide(color: Colores.primario),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: Estilos.bordeRedondeado,
              borderSide: const BorderSide(color: Colores.error),
            ),
            filled: true,
            fillColor: Colores.blanco,
          ),
        ),
      ],
    );
  }
}

class TarjetaPersonalizada extends StatelessWidget {
  final Widget hijo;
  final EdgeInsets? padding;
  final VoidCallback? alPresionar;

  const TarjetaPersonalizada({
    super.key,
    required this.hijo,
    this.padding,
    this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: Estilos.bordeRedondeado,
      ),
      child: InkWell(
        onTap: alPresionar,
        borderRadius: Estilos.bordeRedondeado,
        child: Padding(
          padding: padding ?? Estilos.paddingGeneral,
          child: hijo,
        ),
      ),
    );
  }
}