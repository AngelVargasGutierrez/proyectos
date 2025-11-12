import 'package:flutter/material.dart';
import '../servicios/servicio_autenticacion.dart';
import '../utilidades/estilos.dart';
import '../utilidades/validadores.dart';
import '../widgets/widgets_personalizados.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();
  final _controladorNombres = TextEditingController();
  final _controladorApellidos = TextEditingController();
  final _controladorCodigo = TextEditingController();
  final _controladorCorreo = TextEditingController();
  final _controladorTelefono = TextEditingController();
  final _controladorCiclo = TextEditingController();
  final _controladorContrasena = TextEditingController();
  final _controladorConfirmarContrasena = TextEditingController();
  bool _cargando = false;
  bool _mostrarContrasena = false;
  bool _mostrarConfirmarContrasena = false;

  @override
  void dispose() {
    _controladorNombres.dispose();
    _controladorApellidos.dispose();
    _controladorCodigo.dispose();
    _controladorCorreo.dispose();
    _controladorTelefono.dispose();
    _controladorCiclo.dispose();
    _controladorContrasena.dispose();
    _controladorConfirmarContrasena.dispose();
    super.dispose();
  }

  String? _validarConfirmarContrasena(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Confirma tu contrasena';
    }
    if (valor != _controladorContrasena.text) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }

  Future<void> _registrarse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
    });

    try {
      final exito = await ServicioAutenticacion.instancia.registrarEstudiante(
        nombres: _controladorNombres.text.trim(),
        apellidos: _controladorApellidos.text.trim(),
        codigoUniversitario: _controladorCodigo.text.trim(),
        correo: _controladorCorreo.text.trim(),
        numeroTelefonico: _controladorTelefono.text.trim(),
        ciclo: int.parse(_controladorCiclo.text.trim()),
        contrasena: _controladorContrasena.text,
      );

      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro exitoso. Ahora puedes iniciar sesion'),
              backgroundColor: Colores.exito,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al registrarse. Intenta nuevamente'),
              backgroundColor: Colores.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexion'),
            backgroundColor: Colores.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Colores.primario,
        foregroundColor: Colores.blanco,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Estilos.paddingGeneral,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                const Text(
                  'Crea tu cuenta',
                  style: Estilos.titulo,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                const Text(
                  'Completa todos los campos para registrarte',
                  style: Estilos.cuerpoSecundario,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Campos del formulario
                CampoTextoPersonalizado(
                  etiqueta: 'Nombres',
                  sugerencia: 'Ingresa tus nombres',
                  controlador: _controladorNombres,
                  validador: Validadores.validarNombre,
                  iconoPrefijo: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 16),

                CampoTextoPersonalizado(
                  etiqueta: 'Apellidos',
                  sugerencia: 'Ingresa tus apellidos',
                  controlador: _controladorApellidos,
                  validador: Validadores.validarNombre,
                  iconoPrefijo: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 16),

                CampoTextoPersonalizado(
                  etiqueta: 'Codigo Universitario',
                  sugerencia: '2020123456',
                  controlador: _controladorCodigo,
                  validador: Validadores.validarCodigoUniversitario,
                  tipoTeclado: TextInputType.number,
                  iconoPrefijo: const Icon(Icons.badge_outlined),
                ),
                const SizedBox(height: 16),

                CampoTextoPersonalizado(
                  etiqueta: 'Correo Electronico',
                  sugerencia: 'ejemplo@ejemplo.com',
                  controlador: _controladorCorreo,
                  validador: Validadores.validarCorreo,
                  tipoTeclado: TextInputType.emailAddress,
                  iconoPrefijo: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: 16),

                CampoTextoPersonalizado(
                  etiqueta: 'Numero Telefonico',
                  sugerencia: '987654321',
                  controlador: _controladorTelefono,
                  validador: Validadores.validarTelefono,
                  tipoTeclado: TextInputType.phone,
                  iconoPrefijo: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 16),

                CampoTextoPersonalizado(
                  etiqueta: 'Ciclo',
                  sugerencia: '8',
                  controlador: _controladorCiclo,
                  validador: Validadores.validarCiclo,
                  tipoTeclado: TextInputType.number,
                  iconoPrefijo: const Icon(Icons.school_outlined),
                ),
                const SizedBox(height: 16),

                CampoTextoPersonalizado(
                  etiqueta: 'Contrasena',
                  sugerencia: 'Minimo 6 caracteres',
                  controlador: _controladorContrasena,
                  validador: Validadores.validarContrasena,
                  obscureText: !_mostrarContrasena,
                  iconoPrefijo: const Icon(Icons.lock_outline),
                  iconoSufijo: IconButton(
                    icon: Icon(
                      _mostrarContrasena
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarContrasena = !_mostrarContrasena;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                CampoTextoPersonalizado(
                  etiqueta: 'Confirmar Contrasena',
                  sugerencia: 'Repite tu contrasena',
                  controlador: _controladorConfirmarContrasena,
                  validador: _validarConfirmarContrasena,
                  obscureText: !_mostrarConfirmarContrasena,
                  iconoPrefijo: const Icon(Icons.lock_outline),
                  iconoSufijo: IconButton(
                    icon: Icon(
                      _mostrarConfirmarContrasena
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarConfirmarContrasena = !_mostrarConfirmarContrasena;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Boton de registro
                BotonPersonalizado(
                  texto: 'Registrarse',
                  alPresionar: _registrarse,
                  cargando: _cargando,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}