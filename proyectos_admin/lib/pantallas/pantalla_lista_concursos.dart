import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../proveedores/proveedor_concursos.dart';
import '../proveedores/proveedor_autenticacion.dart';
import '../modelos/administrador.dart';
import '../modelos/concurso.dart';
import 'pantalla_editar_concurso.dart';
import 'pantalla_proyectos_concurso.dart';

class PantallaListaConcursos extends StatelessWidget {
  const PantallaListaConcursos({super.key});

  void _mostrarDetallesConcurso(BuildContext context, Concurso concurso) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(concurso.nombre),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Estado: ${concurso.estadoConcurso}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: concurso.estaVigente ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fechas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Limite de inscripcion: ${formatoFecha.format(concurso.fechaLimiteInscripcion)}'),
                Text('Revision: ${formatoFecha.format(concurso.fechaRevision)}'),
                Text('Confirmacion de aceptados: ${formatoFecha.format(concurso.fechaConfirmacionAceptados)}'),
                const SizedBox(height: 12),
                const Text(
                  'Categorias:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...concurso.categorias.map((categoria) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ${categoria.nombre}: ${categoria.rangoCiclos}'),
                      if (categoria.juradosAsignados.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 2),
                          child: Text(
                            'Jurados: ${categoria.juradosAsignados.join(', ')}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _editarConcurso(BuildContext context, Concurso concurso) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PantallaEditarConcurso(concurso: concurso),
      ),
    );

    if (resultado == true && context.mounted) {
      // Recargar la lista si se actualizó exitosamente
      Provider.of<ProveedorConcursos>(context, listen: false).cargarConcursos();
    }
  }

  void _confirmarEliminarConcurso(BuildContext context, Concurso concurso) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Concurso'),
          content: Text('Estas seguro de que deseas eliminar el concurso "${concurso.nombre}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final proveedor = Provider.of<ProveedorConcursos>(context, listen: false);
                final exito = await proveedor.eliminarConcurso(concurso.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(exito 
                          ? 'Concurso eliminado exitosamente' 
                          : 'Error al eliminar el concurso'),
                      backgroundColor: exito ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Widget _construirTarjetaConcurso(BuildContext context, Concurso concurso) {
    final auth = Provider.of<ProveedorAutenticacion>(context, listen: false);
    final esJurado = auth.administradorActual?.rol == RolUsuario.jurado;
    final formatoFecha = DateFormat('dd/MM/yyyy');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PantallaProyectosConcurso(concurso: concurso),
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
                    concurso.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Menú de acciones: restringido para jurado
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'ver_detalles':
                        _mostrarDetallesConcurso(context, concurso);
                        break;
                      case 'editar':
                        if (!esJurado) {
                          _editarConcurso(context, concurso);
                        }
                        break;
                      case 'eliminar':
                        if (!esJurado) {
                          _confirmarEliminarConcurso(context, concurso);
                        }
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    final items = <PopupMenuItem<String>>[
                      const PopupMenuItem<String>(
                        value: 'ver_detalles',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(width: 8),
                            Text('Ver Detalles'),
                          ],
                        ),
                      ),
                    ];
                    if (!esJurado) {
                      items.addAll(const [
                        PopupMenuItem<String>(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ]);
                    }
                    return items;
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: concurso.estaVigente ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: concurso.estaVigente ? Colors.green[300]! : Colors.orange[300]!,
                ),
              ),
              child: Text(
                concurso.estadoConcurso,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: concurso.estaVigente ? Colors.green[700] : Colors.orange[700],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Limite: ${formatoFecha.format(concurso.fechaLimiteInscripcion)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${concurso.categorias.length} categoria${concurso.categorias.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _mostrarDetallesConcurso(context, concurso),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Detalles'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                    if (!esJurado)
                      TextButton.icon(
                        onPressed: () => _editarConcurso(context, concurso),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Editar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Creado: ${formatoFecha.format(concurso.fechaCreacion)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<ProveedorConcursos>(context, listen: false).cargarConcursos();
      },
      child: Consumer<ProveedorConcursos>(
        builder: (context, proveedor, child) {
          if (proveedor.cargando && proveedor.concursos.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (proveedor.mensajeError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar concursos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    proveedor.mensajeError!,
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => proveedor.cargarConcursos(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final auth = Provider.of<ProveedorAutenticacion>(context, listen: false);
          final esJurado = auth.administradorActual?.rol == RolUsuario.jurado;
          if (proveedor.concursos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    esJurado ? 'No hay concursos disponibles' : 'No hay concursos creados',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!esJurado)
                    Text(
                      'Crea tu primer concurso usando la pestana "Crear Concurso"',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        esJurado
                            ? 'Concursos disponibles: ${proveedor.concursos.length}'
                            : 'Tienes ${proveedor.concursos.length} concurso${proveedor.concursos.length != 1 ? 's' : ''} creado${proveedor.concursos.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: proveedor.concursos.length,
                  itemBuilder: (context, index) {
                    final concurso = proveedor.concursos[index];
                    return _construirTarjetaConcurso(context, concurso);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}