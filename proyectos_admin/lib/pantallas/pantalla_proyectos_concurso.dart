import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../proveedores/proveedor_proyectos.dart';
import '../modelos/concurso.dart';
import '../modelos/proyecto.dart';
import 'pantalla_detalle_proyecto.dart';

class PantallaProyectosConcurso extends StatefulWidget {
  final Concurso concurso;

  const PantallaProyectosConcurso({super.key, required this.concurso});

  @override
  State<PantallaProyectosConcurso> createState() => _PantallaProyectosConcursoState();
}

class _PantallaProyectosConcursoState extends State<PantallaProyectosConcurso> {
  String? _categoriaSeleccionada;
  EstadoProyecto? _estadoSeleccionado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProveedorProyectos>(context, listen: false)
          .cargarProyectosPorConcurso(widget.concurso.id);
    });
  }

  void _filtrarPorCategoria(String? categoria) {
    setState(() {
      _categoriaSeleccionada = categoria;
    });
  }

  void _filtrarPorEstado(EstadoProyecto? estado) {
    setState(() {
      _estadoSeleccionado = estado;
    });
  }

  List<Proyecto> _aplicarFiltros(List<Proyecto> proyectos) {
    var proyectosFiltrados = proyectos;

    if (_categoriaSeleccionada != null) {
      proyectosFiltrados = proyectosFiltrados
          .where((p) => p.categoriaId == _categoriaSeleccionada)
          .toList();
    }

    if (_estadoSeleccionado != null) {
      proyectosFiltrados = proyectosFiltrados
          .where((p) => p.estado == _estadoSeleccionado)
          .toList();
    }

    return proyectosFiltrados;
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

  Widget _construirTarjetaProyecto(Proyecto proyecto) {
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PantallaDetalleProyecto(
                proyecto: proyecto,
                concurso: widget.concurso,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      proyecto.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _obtenerColorEstado(proyecto.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _obtenerColorEstado(proyecto.estado).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      proyecto.estadoTexto,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _obtenerColorEstado(proyecto.estado),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      proyecto.nombreEstudiante,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      proyecto.correoEstudiante,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    proyecto.categoriaId,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    formatoFecha.format(proyecto.fechaEnvio),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final enlace = proyecto.linkGithub.trim();
                        if (enlace.isEmpty) return;
                        final uri = Uri.parse(enlace);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se pudo abrir el enlace de GitHub')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.code, size: 16),
                      label: const Text('GitHub'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final url = proyecto.archivoZip.trim();
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
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('ZIP'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  if (proyecto.puntuacion != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${proyecto.puntuacion!.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
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
      ),
    );
  }

  Widget _construirEstadisticas(Map<EstadoProyecto, int> estadisticas) {
    final total = estadisticas.values.fold(0, (sum, count) => sum + count);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Estadísticas del Concurso',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: $total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: estadisticas.entries.map((entry) {
                final estado = entry.key;
                final count = entry.value;
                final color = _obtenerColorEstado(estado);
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_obtenerTextoEstado(estado)}: $count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _obtenerTextoEstado(EstadoProyecto estado) {
    switch (estado) {
      case EstadoProyecto.enviado:
        return 'Enviados';
      case EstadoProyecto.enRevision:
        return 'En Revisión';
      case EstadoProyecto.aprobado:
        return 'Aprobados';
      case EstadoProyecto.rechazado:
        return 'Rechazados';
      case EstadoProyecto.ganador:
        return 'Ganadores';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Proyectos - ${widget.concurso.nombre}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') {
                Provider.of<ProveedorProyectos>(context, listen: false)
                    .cargarProyectosPorConcurso(widget.concurso.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Actualizar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ProveedorProyectos>(
        builder: (context, proveedor, child) {
          if (proveedor.cargando && proveedor.proyectos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (proveedor.mensajeError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar proyectos',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    proveedor.mensajeError!,
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => proveedor.cargarProyectosPorConcurso(widget.concurso.id),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final proyectosFiltrados = _aplicarFiltros(proveedor.proyectos);

          if (proveedor.proyectos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay proyectos enviados',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Los estudiantes aún no han enviado proyectos para este concurso',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Estadísticas
              _construirEstadisticas(proveedor.estadisticas),
              
              // Filtros
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _categoriaSeleccionada,
                        hint: const Text('Todas las categorías'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todas las categorías'),
                          ),
                          ...widget.concurso.categorias.map(
                            (categoria) => DropdownMenuItem<String>(
                              value: categoria.nombre,
                              child: Text(categoria.nombre),
                            ),
                          ),
                        ],
                        onChanged: _filtrarPorCategoria,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<EstadoProyecto>(
                        value: _estadoSeleccionado,
                        hint: const Text('Todos los estados'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<EstadoProyecto>(
                            value: null,
                            child: Text('Todos los estados'),
                          ),
                          ...EstadoProyecto.values.map(
                            (estado) => DropdownMenuItem<EstadoProyecto>(
                              value: estado,
                              child: Text(_obtenerTextoEstado(estado)),
                            ),
                          ),
                        ],
                        onChanged: _filtrarPorEstado,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de proyectos
              Expanded(
                child: proyectosFiltrados.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No hay proyectos con los filtros aplicados',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => proveedor.cargarProyectosPorConcurso(widget.concurso.id),
                        child: ListView.builder(
                          itemCount: proyectosFiltrados.length,
                          itemBuilder: (context, index) {
                            return _construirTarjetaProyecto(proyectosFiltrados[index]);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}