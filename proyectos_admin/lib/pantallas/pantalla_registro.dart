import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../proveedores/proveedor_autenticacion.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();
  final _controladorNombres = TextEditingController();
  final _controladorApellidos = TextEditingController();
  final _controladorCorreo = TextEditingController();
  final _controladorTelefono = TextEditingController();
  final _controladorContrasena = TextEditingController();
  final _controladorConfirmarContrasena = TextEditingController();
  bool _ocultarContrasena = true;
  bool _ocultarConfirmarContrasena = true;

  @override
  void dispose() {
    _controladorNombres.dispose();
    _controladorApellidos.dispose();
    _controladorCorreo.dispose();
    _controladorTelefono.dispose();
    _controladorContrasena.dispose();
    _controladorConfirmarContrasena.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_formKey.currentState!.validate()) {
      final proveedor = Provider.of<ProveedorAutenticacion>(context, listen: false);
      
      final exito = await proveedor.registrar(
        nombres: _controladorNombres.text.trim(),
        apellidos: _controladorApellidos.text.trim(),
        correo: _controladorCorreo.text.trim(),
        numeroTelefonico: _controladorTelefono.text.trim(),
        contrasena: _controladorContrasena.text,
      );

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro exitoso. Ahora puedes iniciar sesion.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Administrador'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              TextFormField(
                controller: _controladorNombres,
                decoration: const InputDecoration(
                  labelText: 'Nombres',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese sus nombres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controladorApellidos,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese sus apellidos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controladorCorreo,
                decoration: const InputDecoration(
                  labelText: 'Correo electronico',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su correo';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Por favor ingrese un correo valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controladorTelefono,
                decoration: const InputDecoration(
                  labelText: 'Numero telefonico',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese su numero telefonico';
                  }
                  if (value.trim().length < 9) {
                    return 'El numero debe tener al menos 9 digitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controladorContrasena,
                decoration: InputDecoration(
                  labelText: 'Contrasena',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarContrasena ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _ocultarContrasena = !_ocultarContrasena;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _ocultarContrasena,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una contrasena';
                  }
                  if (value.length < 6) {
                    return 'La contrasena debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controladorConfirmarContrasena,
                decoration: InputDecoration(
                  labelText: 'Confirmar contrasena',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarConfirmarContrasena ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _ocultarConfirmarContrasena = !_ocultarConfirmarContrasena;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _ocultarConfirmarContrasena,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor confirme su contrasena';
                  }
                  if (value != _controladorContrasena.text) {
                    return 'Las contrasenas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Consumer<ProveedorAutenticacion>(
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
              Consumer<ProveedorAutenticacion>(
                builder: (context, proveedor, child) {
                  return ElevatedButton(
                    onPressed: proveedor.cargando ? null : _registrar,
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
                            'Registrarse',
                            style: TextStyle(fontSize: 16),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}