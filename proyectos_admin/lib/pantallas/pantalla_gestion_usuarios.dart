import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modelos/administrador.dart';
import '../proveedores/proveedor_usuarios.dart';

class PantallaGestionUsuarios extends StatefulWidget {
  const PantallaGestionUsuarios({super.key});

  @override
  State<PantallaGestionUsuarios> createState() => _PantallaGestionUsuariosState();
}

class _PantallaGestionUsuariosState extends State<PantallaGestionUsuarios> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProveedorUsuarios>(context, listen: false).cargarUsuarios();
    });
  }

  void _mostrarDialogoCrearUsuario() {
    showDialog(
      context: context,
      builder: (context) => const DialogoCrearUsuario(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProveedorUsuarios>(
        builder: (context, proveedor, child) {
          if (proveedor.cargando && proveedor.usuarios.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (proveedor.mensajeError != null && proveedor.usuarios.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    proveedor.mensajeError!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => proveedor.cargarUsuarios(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (proveedor.usuarios.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay usuarios creados',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _mostrarDialogoCrearUsuario,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Usuario'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (proveedor.mensajeExito != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          proveedor.mensajeExito!,
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => proveedor.limpiarMensajes(),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => proveedor.cargarUsuarios(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: proveedor.usuarios.length,
                    itemBuilder: (context, index) {
                      final usuario = proveedor.usuarios[index];
                      final esAdministrador = usuario['rol'] == 'administrador';
                      final metodoAuth = usuario['metodoAutenticacion'] ?? 'email';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: esAdministrador ? Colors.blue[700] : Colors.orange[700],
                            child: Icon(
                              esAdministrador ? Icons.admin_panel_settings : Icons.gavel,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '${usuario['nombres']} ${usuario['apellidos']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(usuario['correo']),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: esAdministrador ? Colors.blue[100] : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      esAdministrador ? 'Administrador' : 'Jurado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: esAdministrador ? Colors.blue[900] : Colors.orange[900],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: metodoAuth == 'microsoft' ? Colors.purple[100] : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          metodoAuth == 'microsoft' ? Icons.business : Icons.email,
                                          size: 12,
                                          color: metodoAuth == 'microsoft' ? Colors.purple[900] : Colors.grey[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          metodoAuth == 'microsoft' ? 'Microsoft' : 'Email',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: metodoAuth == 'microsoft' ? Colors.purple[900] : Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: metodoAuth == 'microsoft'
                              ? IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red[700]),
                                  onPressed: () => _confirmarEliminarUsuario(
                                    context,
                                    usuario['correo'],
                                    usuario['rol'],
                                    '${usuario['nombres']} ${usuario['apellidos']}',
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoCrearUsuario,
        icon: const Icon(Icons.add),
        label: const Text('Crear Usuario'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  void _confirmarEliminarUsuario(BuildContext context, String correo, String rol, String nombre) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Usuario'),
          content: Text('¿Estás seguro de que deseas eliminar a $nombre?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Provider.of<ProveedorUsuarios>(context, listen: false)
                    .eliminarUsuario(correo, rol);
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
}

class DialogoCrearUsuario extends StatefulWidget {
  const DialogoCrearUsuario({super.key});

  @override
  State<DialogoCrearUsuario> createState() => _DialogoCrearUsuarioState();
}

class _DialogoCrearUsuarioState extends State<DialogoCrearUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _controladorNombres = TextEditingController();
  final _controladorApellidos = TextEditingController();
  final _controladorCorreo = TextEditingController();
  final _controladorTelefono = TextEditingController();
  RolUsuario _rolSeleccionado = RolUsuario.jurado;

  @override
  void dispose() {
    _controladorNombres.dispose();
    _controladorApellidos.dispose();
    _controladorCorreo.dispose();
    _controladorTelefono.dispose();
    super.dispose();
  }

  Future<void> _crearUsuario() async {
    if (_formKey.currentState!.validate()) {
      final proveedor = Provider.of<ProveedorUsuarios>(context, listen: false);

      final exito = await proveedor.crearUsuario(
        nombres: _controladorNombres.text,
        apellidos: _controladorApellidos.text,
        correo: _controladorCorreo.text,
        numeroTelefonico: _controladorTelefono.text,
        rol: _rolSeleccionado,
      );

      if (exito && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Nuevo Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Este usuario iniciará sesión con Microsoft',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controladorNombres,
                decoration: const InputDecoration(
                  labelText: 'Nombres',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese los nombres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controladorApellidos,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese los apellidos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controladorCorreo,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico (Microsoft)',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el correo';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Por favor ingrese un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controladorTelefono,
                decoration: const InputDecoration(
                  labelText: 'Número Telefónico',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el número telefónico';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RolUsuario>(
                value: _rolSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.security),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: RolUsuario.administrador,
                    child: Text('Administrador'),
                  ),
                  DropdownMenuItem(
                    value: RolUsuario.jurado,
                    child: Text('Jurado'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _rolSeleccionado = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Consumer<ProveedorUsuarios>(
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        Consumer<ProveedorUsuarios>(
          builder: (context, proveedor, child) {
            return ElevatedButton(
              onPressed: proveedor.cargando ? null : _crearUsuario,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
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
                  : const Text('Crear Usuario'),
            );
          },
        ),
      ],
    );
  }
}
