import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../modelos/proyecto.dart';
import '../modelos/concurso.dart';
import '../proveedores/proveedor_proyectos.dart';
import '../proveedores/proveedor_autenticacion.dart';
import '../modelos/administrador.dart';

class PantallaDetalleProyecto extends StatefulWidget {
  final Proyecto proyecto;
  final Concurso concurso;

  const PantallaDetalleProyecto({
    super.key,
    required this.proyecto,
    required this.concurso,
  });

  @override
  State<PantallaDetalleProyecto> createState() => _PantallaDetalleProyectoState();
}

class _PantallaDetalleProyectoState extends State<PantallaDetalleProyecto> {
  final _controladorComentarios = TextEditingController();
  final _controladorPuntuacion = TextEditingController();

  // Criterios de evaluación para jurados (0-4 cada uno)
  final Map<String, int> _criterios = {
    'Creatividad': 0,
    'Diseño': 0,
    'Trabajo Colaborativo': 0,
    'Complejidad técnica': 0,
    'Grado de explicación del proyecto': 0,
    'Uso de herramientas tecnológicas': 0,
    'Aplicación práctica': 0,
  };

  @override
  void initState() {
    super.initState();
    _controladorComentarios.text = widget.proyecto.comentarios ?? '';
    _controladorPuntuacion.text = widget.proyecto.puntuacion?.toString() ?? '';
  }

  @override
  void dispose() {
    _controladorComentarios.dispose();
    _controladorPuntuacion.dispose();
    super.dispose();
  }

  Color _obtenerColorEstado(EstadoProyecto estado) {
    switch (estado) {
      case EstadoProyecto.enviado:
        return Colors.blue;
      case EstadoProyecto.enRevision:
        return Colors.orange;
      case EstadoProyecto.aprobado:
        return Colors.green;
      case EstadoProyecto.rechazado:
        return Colors.red;
      case EstadoProyecto.ganador:
        return Colors.purple;
    }
  }

  Future<void> _actualizarEstado(EstadoProyecto nuevoEstado) async {
    final proveedor = Provider.of<ProveedorProyectos>(context, listen: false);
    // Para administradores ya no se registra puntuación desde esta pantalla
    double? puntuacion;

    final exito = await proveedor.actualizarEstadoProyecto(
      widget.proyecto.id,
      nuevoEstado,
      comentarios: _controladorComentarios.text.trim().isEmpty 
          ? null 
          : _controladorComentarios.text.trim(),
      puntuacion: puntuacion,
    );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a: ${_obtenerTextoEstado(nuevoEstado)}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Indicar que se actualizó
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el estado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _totalEvaluacion() => _criterios.values.fold(0, (a, b) => a + b);

  Future<void> _enviarEvaluacionJurado() async {
    final proveedorAuth = Provider.of<ProveedorAutenticacion>(context, listen: false);
    final usuario = proveedorAuth.administradorActual;
    if (usuario == null || usuario.rol != RolUsuario.jurado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo jurados pueden evaluar')),
      );
      return;
    }
    final proveedorProj = Provider.of<ProveedorProyectos>(context, listen: false);
    final exito = await proveedorProj.enviarEvaluacionJurado(
      concursoId: widget.concurso.id,
      proyectoId: widget.proyecto.id,
      categoriaId: widget.proyecto.categoriaId,
      juradoUid: usuario.id,
      criterios: {
        'creatividad': _criterios['Creatividad']!,
        'diseno': _criterios['Diseño']!,
        'trabajo_colaborativo': _criterios['Trabajo Colaborativo']!,
        'complejidad_tecnica': _criterios['Complejidad técnica']!,
        'explicacion': _criterios['Grado de explicación del proyecto']!,
        'herramientas': _criterios['Uso de herramientas tecnológicas']!,
        'aplicacion_practica': _criterios['Aplicación práctica']!,
      },
    );
    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Evaluación enviada. Total: ${_totalEvaluacion()}')),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar evaluación')),
      );
    }
  }

  String _obtenerTextoEstado(EstadoProyecto estado) {
    switch (estado) {
      case EstadoProyecto.enviado:
        return 'Enviado';
      case EstadoProyecto.enRevision:
        return 'En Revisión';
      case EstadoProyecto.aprobado:
        return 'Aprobado';
      case EstadoProyecto.rechazado:
        return 'Rechazado';
      case EstadoProyecto.ganador:
        return 'Ganador';
    }
  }

  void _mostrarDialogoConfirmacion(EstadoProyecto nuevoEstado) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cambiar Estado a ${_obtenerTextoEstado(nuevoEstado)}'),
          content: Text(
            '¿Estás seguro de cambiar el estado del proyecto "${widget.proyecto.nombre}" a ${_obtenerTextoEstado(nuevoEstado)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _actualizarEstado(nuevoEstado);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _obtenerColorEstado(nuevoEstado),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Proyecto'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<EstadoProyecto>(
            onSelected: _mostrarDialogoConfirmacion,
            itemBuilder: (context) => EstadoProyecto.values
                .where((estado) => estado != widget.proyecto.estado)
                .map((estado) => PopupMenuItem<EstadoProyecto>(
                      value: estado,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _obtenerColorEstado(estado),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Marcar como ${_obtenerTextoEstado(estado)}'),
                        ],
                      ),
                    ))
                .toList(),
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información básica del proyecto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.proyecto.nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _obtenerColorEstado(widget.proyecto.estado).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _obtenerColorEstado(widget.proyecto.estado).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.proyecto.estadoTexto,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _obtenerColorEstado(widget.proyecto.estado),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Información del estudiante
                    _construirFilaInfo(Icons.person, 'Estudiante', widget.proyecto.nombreEstudiante),
                    const SizedBox(height: 8),
                    _construirFilaInfo(Icons.email, 'Correo', widget.proyecto.correoEstudiante),
                    const SizedBox(height: 8),
                    _construirFilaInfo(Icons.category, 'Categoría', widget.proyecto.categoriaId),
                    const SizedBox(height: 8),
                    _construirFilaInfo(Icons.access_time, 'Fecha de Envío', 
                        formatoFecha.format(widget.proyecto.fechaEnvio)),
                    
                    if (widget.proyecto.puntuacion != null) ...[
                      const SizedBox(height: 8),
                      _construirFilaInfo(Icons.star, 'Puntuación', 
                          '${widget.proyecto.puntuacion!.toStringAsFixed(1)}/20'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Enlaces del proyecto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enlaces del Proyecto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // GitHub
                    ListTile(
                      leading: const Icon(Icons.code, color: Colors.blue),
                      title: const Text('Repositorio GitHub'),
                      subtitle: Text(
                        widget.proyecto.linkGithub,
                        style: const TextStyle(color: Colors.blue),
                      ),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () async {
                        final enlace = widget.proyecto.linkGithub.trim();
                        if (enlace.isEmpty) return;
                        final uri = Uri.parse(enlace);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo abrir el enlace de GitHub')),
                          );
                        }
                      },
                    ),
                    
                    const Divider(),
                    
                    // Archivo ZIP
                    ListTile(
                      leading: const Icon(Icons.folder_zip, color: Colors.green),
                      title: const Text('Archivo del Proyecto'),
                      subtitle: Text(widget.proyecto.archivoZip),
                      trailing: const Icon(Icons.download),
                      onTap: () async {
                        final url = widget.proyecto.archivoZip.trim();
                        if (url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No hay archivo ZIP para descargar')),
                          );
                          return;
                        }
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo abrir el ZIP')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sección dependiente del rol
            Builder(builder: (context) {
              final auth = Provider.of<ProveedorAutenticacion>(context);
              final esJurado = auth.administradorActual?.rol == RolUsuario.jurado;

              if (!esJurado) {
                // Administrador: solo cambio de estado
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cambiar estado del proyecto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _mostrarDialogoConfirmacion(EstadoProyecto.aprobado),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Aprobar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _mostrarDialogoConfirmacion(EstadoProyecto.rechazado),
                                icon: const Icon(Icons.cancel),
                                label: const Text('Rechazar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _mostrarDialogoConfirmacion(EstadoProyecto.enRevision),
                                icon: const Icon(Icons.visibility),
                                label: const Text('En Revisión'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _mostrarDialogoConfirmacion(EstadoProyecto.ganador),
                                icon: const Icon(Icons.emoji_events),
                                label: const Text('Ganador'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Jurado: formulario de 7 criterios (0-4)
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evaluación del Jurado (0-4 por criterio)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._criterios.keys.map((nombre) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(nombre)),
                                DropdownButton<int>(
                                  value: _criterios[nombre]!,
                                  items: List.generate(5, (i) => DropdownMenuItem<int>(value: i, child: Text('$i'))),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setState(() {
                                      _criterios[nombre] = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 8),
                      Text('Total: ${_totalEvaluacion()} / 28'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _enviarEvaluacionJurado,
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Enviar evaluación'),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Mostrar comentarios existentes si los hay
            if (widget.proyecto.comentarios != null && widget.proyecto.comentarios!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comentarios Actuales',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(widget.proyecto.comentarios!),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _construirFilaInfo(IconData icono, String etiqueta, String valor) {
    return Row(
      children: [
        Icon(icono, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$etiqueta: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
      ],
    );
  }
}