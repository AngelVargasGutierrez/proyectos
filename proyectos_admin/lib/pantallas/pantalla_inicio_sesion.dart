import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../proveedores/proveedor_autenticacion.dart';
import 'pantalla_registro.dart';
import 'pantalla_principal.dart';

class PantallaInicioSesion extends StatefulWidget {
  const PantallaInicioSesion({super.key});

  @override
  State<PantallaInicioSesion> createState() => _PantallaInicioSesionState();
}

class _PantallaInicioSesionState extends State<PantallaInicioSesion> {
  final _formKey = GlobalKey<FormState>();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();
  bool _ocultarContrasena = true;

  @override
  void dispose() {
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (_formKey.currentState!.validate()) {
      final proveedor = Provider.of<ProveedorAutenticacion>(context, listen: false);
      
      final exito = await proveedor.iniciarSesion(
        correo: _controladorCorreo.text.trim(),
        contrasena: _controladorContrasena.text,
      );

      if (exito && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PantallaPrincipal()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesion'),
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
              const SizedBox(height: 32),
              Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Colors.blue[700],
              ),
              const SizedBox(height: 16),
              Text(
                'Administrador de Concurso de Proyectos EPIS',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
                    return 'Por favor ingrese su contrasena';
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
                    onPressed: proveedor.cargando ? null : _iniciarSesion,
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
                            'Iniciar Sesion',
                            style: TextStyle(fontSize: 16),
                          ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const PantallaRegistro()),
                  );
                },
                child: const Text('No tienes cuenta? Registrate aqui'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}