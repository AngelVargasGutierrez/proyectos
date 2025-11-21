import 'package:flutter/material.dart';
import '../modelos/concurso.dart';
import '../servicios/servicio_concursos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utilidades/estilos.dart';
import '../widgets/widgets_personalizados.dart';
import 'pantalla_enviar_proyecto.dart';

class PantallaDetalleConcurso extends StatelessWidget {
  final Concurso concurso;

  const PantallaDetalleConcurso({super.key, required this.concurso});

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
        builder: (context) =>
            PantallaEnviarProyecto(concurso: concurso, categoria: categoria),
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
                        child: Text(concurso.nombre, style: Estilos.titulo),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: concurso.estaVigente
                              ? Colores.exito
                              : Colores.gris,
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

                  Text('Descripcion', style: Estilos.subtitulo),
                  const SizedBox(height: 8),
                  Text(concurso.descripcion, style: Estilos.cuerpo),
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

            // Bases del concurso (PDF)
            if ((concurso.basesUrl ?? '').isNotEmpty)
              TarjetaPersonalizada(
                hijo: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Colores.advertencia,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bases del concurso (PDF)',
                        style: Estilos.cuerpo,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(concurso.basesUrl!.trim());
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Cronograma
            TarjetaPersonalizada(
              hijo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cronograma', style: Estilos.subtitulo),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event_note, color: Colores.primario),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Revisión: ${concurso.fechaRevision != null ? '${concurso.fechaRevision!.day}/${concurso.fechaRevision!.month}/${concurso.fechaRevision!.year}' : 'No definida'}',
                          style: Estilos.cuerpo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.event_available,
                        color: Colores.primario,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Confirmación aceptados: ${concurso.fechaConfirmacionAceptados != null ? '${concurso.fechaConfirmacionAceptados!.day}/${concurso.fechaConfirmacionAceptados!.month}/${concurso.fechaConfirmacionAceptados!.year}' : 'No definida'}',
                          style: Estilos.cuerpo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Titulo de categorias
            Text('Categorias Disponibles', style: Estilos.subtitulo),
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
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final categoria = concurso.categorias[index];
                  return _construirTarjetaCategoria(context, categoria);
                },
              ),

            const SizedBox(height: 24),

            // Aptos y Ganadores
            TarjetaPersonalizada(
              hijo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Listas Oficiales', style: Estilos.subtitulo),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final lista = await ServicioConcursos.instancia
                              .obtenerAptos(concurso.id);
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Proyectos Aptos'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: lista
                                      .map(
                                        (e) => ListTile(
                                          title: Text(e['nombre'] ?? ''),
                                          subtitle: Text(e['categoria'] ?? ''),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Aptos'),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () async {
                          final lista = await ServicioConcursos.instancia
                              .obtenerGanadores(concurso.id);
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Ganadores por Categoría'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: lista
                                      .map(
                                        (e) => ListTile(
                                          title: Text(e['nombre'] ?? ''),
                                          subtitle: Text(e['categoria'] ?? ''),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('Ganadores'),
                      ),
                    ],
                  ),
                ],
              ),
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
              Icon(Icons.category, color: Colores.primario, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(categoria.nombre, style: Estilos.subtitulo)),
              Icon(Icons.arrow_forward_ios, color: Colores.gris, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(categoria.descripcion, style: Estilos.cuerpo),
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
