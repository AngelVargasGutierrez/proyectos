import 'package:flutter/material.dart';
import '../modelos/concurso.dart';
import '../utilidades/estilos.dart';
import '../widgets/widgets_personalizados.dart';
import 'pantalla_enviar_proyecto.dart';

class PantallaDetalleConcurso extends StatelessWidget {
  final Concurso concurso;

  const PantallaDetalleConcurso({
    super.key,
    required this.concurso,
  });

  void _seleccionarCategoria(BuildContext context, Categoria categoria) {
    if (!concurso.estaVigente) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este concurso no esta activo'),
          backgroundColor: Colores.advertencia,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PantallaEnviarProyecto(
          concurso: concurso,
          categoria: categoria,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        title: const Text('Detalle del Concurso'),
        backgroundColor: Colores.primario,
        foregroundColor: Colores.blanco,
      ),
      body: SingleChildScrollView(
        padding: Estilos.paddingGeneral,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informacion del concurso
            TarjetaPersonalizada(
              hijo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          concurso.nombre,
                          style: Estilos.titulo,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: concurso.estaVigente ? Colores.exito : Colores.gris,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          concurso.estaVigente ? 'Activo' : 'Inactivo',
                          style: const TextStyle(
                            color: Colores.blanco,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Descripcion',
                    style: Estilos.subtitulo,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    concurso.descripcion,
                    style: Estilos.cuerpo,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha de Inicio',
                              style: Estilos.cuerpoSecundario,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${concurso.fechaInicio.day}/${concurso.fechaInicio.month}/${concurso.fechaInicio.year}',
                              style: Estilos.cuerpo.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha de Fin',
                              style: Estilos.cuerpoSecundario,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${concurso.fechaFin.day}/${concurso.fechaFin.month}/${concurso.fechaFin.year}',
                              style: Estilos.cuerpo.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Titulo de categorias
            Text(
              'Categorias Disponibles',
              style: Estilos.subtitulo,
            ),
            const SizedBox(height: 16),

            // Lista de categorias
            if (concurso.categorias.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Colores.gris,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay categorias disponibles',
                        style: Estilos.subtitulo,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: concurso.categorias.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final categoria = concurso.categorias[index];
                  return _construirTarjetaCategoria(context, categoria);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaCategoria(BuildContext context, Categoria categoria) {
    return TarjetaPersonalizada(
      alPresionar: () => _seleccionarCategoria(context, categoria),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category,
                color: Colores.primario,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  categoria.nombre,
                  style: Estilos.subtitulo,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colores.gris,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              categoria.descripcion,
              style: Estilos.cuerpo,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              'Toca para participar en esta categoria',
              style: Estilos.cuerpoSecundario.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}