import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../proveedores/proveedor_concursos.dart';
import '../modelos/categoria.dart';

class PantallaCrearConcurso extends StatefulWidget {
  const PantallaCrearConcurso({super.key});

  @override
  State<PantallaCrearConcurso> createState() => _PantallaCrearConcursoState();
}

class _PantallaCrearConcursoState extends State<PantallaCrearConcurso> {
  final _formKey = GlobalKey<FormState>();
  final _controladorNombre = TextEditingController();
  final _controladorNombreCategoria = TextEditingController();
  final _controladorRangoCiclos = TextEditingController();
  
  DateTime? _fechaLimiteInscripcion;
  DateTime? _fechaRevision;
  DateTime? _fechaConfirmacionAceptados;
  
  final List<Categoria> _categorias = [];

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorNombreCategoria.dispose();
    _controladorRangoCiclos.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context, String tipoFecha) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (fechaSeleccionada != null && mounted) {
      setState(() {
        switch (tipoFecha) {
          case 'inscripcion':
            _fechaLimiteInscripcion = fechaSeleccionada;
            break;
          case 'revision':
            _fechaRevision = fechaSeleccionada;
            break;
          case 'confirmacion':
            _fechaConfirmacionAceptados = fechaSeleccionada;
            break;
        }
      });
    }
  }

  void _agregarCategoria() {
    final nombreCategoria = _controladorNombreCategoria.text.trim();
    final rangoCiclos = _controladorRangoCiclos.text.trim();

    if (nombreCategoria.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese el nombre de la categoria')),
      );
      return;
    }

    if (rangoCiclos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese el rango de ciclos')),
      );
      return;
    }

    // Verificar que no exista una categoria con el mismo nombre
    if (_categorias.any((cat) => cat.nombre.toLowerCase() == nombreCategoria.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya existe una categoria con ese nombre')),
      );
      return;
    }

    setState(() {
      _categorias.add(Categoria(
        nombre: nombreCategoria,
        rangoCiclos: rangoCiclos,
      ));
      _controladorNombreCategoria.clear();
      _controladorRangoCiclos.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Categoria "$nombreCategoria" agregada exitosamente'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _eliminarCategoria(int indice) {
    setState(() {
      _categorias.removeAt(indice);
    });
  }

  Future<void> _crearConcurso() async {
    if (_formKey.currentState!.validate() && _validarDatos()) {
      final proveedor = Provider.of<ProveedorConcursos>(context, listen: false);
      
      final exito = await proveedor.crearConcurso(
        nombre: _controladorNombre.text.trim(),
        categorias: _categorias,
        fechaLimiteInscripcion: _fechaLimiteInscripcion!,
        fechaRevision: _fechaRevision!,
        fechaConfirmacionAceptados: _fechaConfirmacionAceptados!,
      );

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Concurso creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _limpiarFormulario();
      }
    }
  }

  bool _validarDatos() {
    if (_fechaLimiteInscripcion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione la fecha limite de inscripcion')),
      );
      return false;
    }
    if (_fechaRevision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione la fecha de revision')),
      );
      return false;
    }
    if (_fechaConfirmacionAceptados == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione la fecha de confirmacion de aceptados')),
      );
      return false;
    }
    if (_categorias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregue al menos una categoria')),
      );
      return false;
    }
    if (_fechaRevision!.isBefore(_fechaLimiteInscripcion!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de revision debe ser posterior a la fecha limite de inscripcion')),
      );
      return false;
    }
    if (_fechaConfirmacionAceptados!.isBefore(_fechaRevision!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de confirmacion debe ser posterior a la fecha de revision')),
      );
      return false;
    }
    return true;
  }

  void _limpiarFormulario() {
    setState(() {
      _controladorNombre.clear();
      _categorias.clear();
      _fechaLimiteInscripcion = null;
      _fechaRevision = null;
      _fechaConfirmacionAceptados = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crear Nuevo Concurso',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _controladorNombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Concurso',
                  prefixIcon: Icon(Icons.event),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese el nombre del concurso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Fechas del Concurso',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _seleccionarFecha(context, 'inscripcion'),
                icon: const Icon(Icons.calendar_today),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Limite de Inscripcion',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                    Text(
                      _fechaLimiteInscripcion != null
                          ? formatoFecha.format(_fechaLimiteInscripcion!)
                          : 'Toque para seleccionar',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _fechaLimiteInscripcion != null ? Colors.blue[100] : Colors.grey[200],
                  foregroundColor: _fechaLimiteInscripcion != null ? Colors.blue[800] : Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _seleccionarFecha(context, 'revision'),
                icon: const Icon(Icons.calendar_today),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Fecha de Revision',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                    Text(
                      _fechaRevision != null
                          ? formatoFecha.format(_fechaRevision!)
                          : 'Toque para seleccionar',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _fechaRevision != null ? Colors.green[100] : Colors.grey[200],
                  foregroundColor: _fechaRevision != null ? Colors.green[800] : Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _seleccionarFecha(context, 'confirmacion'),
                icon: const Icon(Icons.calendar_today),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Confirmacion de Aceptados',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                    Text(
                      _fechaConfirmacionAceptados != null
                          ? formatoFecha.format(_fechaConfirmacionAceptados!)
                          : 'Toque para seleccionar',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _fechaConfirmacionAceptados != null ? Colors.orange[100] : Colors.grey[200],
                  foregroundColor: _fechaConfirmacionAceptados != null ? Colors.orange[800] : Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Categorias del Concurso',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _controladorNombreCategoria,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de Categoria',
                            hintText: 'Ej: Categoria A',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _controladorRangoCiclos,
                          decoration: const InputDecoration(
                            labelText: 'Rango de Ciclos',
                            hintText: 'Ej: V a VII ciclo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _agregarCategoria,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Categoria'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_categorias.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.category, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Categorias agregadas:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _categorias.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final categoria = _categorias[index];
                          return ListTile(
                            title: Text(categoria.nombre),
                            subtitle: Text(categoria.rangoCiclos),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarCategoria(index),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Consumer<ProveedorConcursos>(
                builder: (context, proveedor, child) {
                  if (proveedor.mensajeError != null) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              proveedor.mensajeError!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Consumer<ProveedorConcursos>(
                builder: (context, proveedor, child) {
                  return ElevatedButton(
                    onPressed: proveedor.cargando ? null : _crearConcurso,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: proveedor.cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Crear Concurso',
                            style: TextStyle(fontSize: 16),
                          ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}