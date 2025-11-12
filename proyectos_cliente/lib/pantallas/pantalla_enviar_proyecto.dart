import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../modelos/concurso.dart';
import '../servicios/servicio_autenticacion.dart';
import '../servicios/servicio_concursos.dart';
import '../utilidades/estilos.dart';
import '../utilidades/validadores.dart';
import '../widgets/widgets_personalizados.dart';

class PantallaEnviarProyecto extends StatefulWidget {
  final Concurso concurso;
  final Categoria categoria;

  const PantallaEnviarProyecto({
    super.key,
    required this.concurso,
    required this.categoria,
  });

  @override
  State<PantallaEnviarProyecto> createState() => _PantallaEnviarProyectoState();
}

class _PantallaEnviarProyectoState extends State<PantallaEnviarProyecto> {
  final _formKey = GlobalKey<FormState>();
  final _controladorNombreProyecto = TextEditingController();
  final _controladorEnlaceGithub = TextEditingController();
  
  String? _archivoSeleccionado;
  Uint8List? _zipBytes;
  PlatformFile? _zipFile;
  bool _cargando = false;

  @override
  void dispose() {
    _controladorNombreProyecto.dispose();
    _controladorEnlaceGithub.dispose();
    super.dispose();
  }

  Future<void> _seleccionarArchivo() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'rar'],
        withData: true, // necesario en web para obtener bytes
      );
      final file = res?.files.first;
      // Limitar tamaño máximo para evitar problemas en Web (memoria/carga)
      const int maxBytes = 150 * 1024 * 1024; // 150 MB
      if (file != null && (file.bytes?.isNotEmpty ?? false)) {
        if ((file.size) > maxBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El archivo supera el límite de 150 MB'),
                backgroundColor: Colores.advertencia,
              ),
            );
          }
          return;
        }
        setState(() {
          _archivoSeleccionado = file.name;
          _zipBytes = file.bytes;
          _zipFile = file;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se seleccionó un archivo ZIP válido'),
              backgroundColor: Colores.advertencia,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al seleccionar archivo'),
            backgroundColor: Colores.error,
          ),
        );
      }
    }
  }

  Future<void> _abrirEnlaceGithub() async {
    final enlace = _controladorEnlaceGithub.text.trim();
    if (enlace.isNotEmpty) {
      try {
        final uri = Uri.parse(enlace);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el enlace'),
              backgroundColor: Colores.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _enviarProyecto() async {
    if (!_formKey.currentState!.validate()) return;
    // El archivo es opcional: no bloqueamos si no hay selección

    // Mostrar dialogo de confirmacion
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Envio'),
        content: const Text(
          'Una vez enviado el proyecto, quedara en estado "Pendiente de revision". ¿Estas seguro de continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colores.primario,
            ),
            child: const Text('Confirmar', style: TextStyle(color: Colores.blanco)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmar) return;

    setState(() {
      _cargando = true;
    });

    try {
      final estudiante = ServicioAutenticacion.instancia.estudianteActual!;

      // Nota: antes se bloqueaba si ya existía registro en el concurso.
      // Ahora dejamos que el servicio maneje el caso de duplicado y aun así cree la carpeta en backend.
      final existentes = await ServicioConcursos.instancia.obtenerProyectosEstudiante(estudiante.id);
      final yaRegistrado = existentes.any((p) => p.concursoId == widget.concurso.id);
      
      final exito = await ServicioConcursos.instancia.enviarProyecto(
        nombreProyecto: _controladorNombreProyecto.text.trim(),
        estudianteId: estudiante.id,
        concursoId: widget.concurso.id,
        categoriaId: widget.categoria.id,
        enlaceGithub: _controladorEnlaceGithub.text.trim(),
        archivoZipNombre: _archivoSeleccionado,
        archivoZipBytes: _zipBytes,
      );

      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proyecto enviado exitosamente'),
              backgroundColor: Colores.exito,
            ),
          );
          Navigator.of(context).pop();
        } else {
          // Si falló el envío, verificamos si ya está registrado en el concurso
          try {
            final proyectos = await ServicioConcursos.instancia.obtenerProyectosEstudiante(estudiante.id);
            final yaTieneEnEsteConcurso = proyectos.any((p) => p.concursoId == widget.concurso.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(yaTieneEnEsteConcurso ? 'Ya estás registrado/a' : 'Error al enviar el proyecto'),
                backgroundColor: yaTieneEnEsteConcurso ? Colores.advertencia : Colores.error,
              ),
            );
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al enviar el proyecto'),
                backgroundColor: Colores.error,
              ),
            );
          }
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
        title: const Text('Enviar Proyecto'),
        backgroundColor: Colores.primario,
        foregroundColor: Colores.blanco,
      ),
      body: SingleChildScrollView(
        padding: Estilos.paddingGeneral,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informacion del concurso y categoria
              TarjetaPersonalizada(
                hijo: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informacion del Concurso',
                      style: Estilos.subtitulo,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Concurso: ${widget.concurso.nombre}',
                      style: Estilos.cuerpo,
                    ),
                    Text(
                      'Categoria: ${widget.categoria.nombre}',
                      style: Estilos.cuerpo,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.categoria.descripcion,
                      style: Estilos.cuerpoSecundario,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Formulario
              Text(
                'Datos del Proyecto',
                style: Estilos.subtitulo,
              ),
              const SizedBox(height: 16),

              CampoTextoPersonalizado(
                etiqueta: 'Nombre del Proyecto',
                sugerencia: 'Ingresa el nombre de tu proyecto',
                controlador: _controladorNombreProyecto,
                validador: Validadores.validarNombreProyecto,
                iconoPrefijo: const Icon(Icons.assignment_outlined),
              ),
              const SizedBox(height: 16),

              CampoTextoPersonalizado(
                etiqueta: 'Enlace de GitHub',
                sugerencia: 'https://github.com/usuario/proyecto',
                controlador: _controladorEnlaceGithub,
                validador: Validadores.validarEnlaceGithub,
                tipoTeclado: TextInputType.url,
                iconoPrefijo: const Icon(Icons.link),
                iconoSufijo: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: _abrirEnlaceGithub,
                  tooltip: 'Abrir enlace',
                ),
              ),
              const SizedBox(height: 16),

              // Seleccion de archivo
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archivo del Proyecto (ZIP/RAR)',
                    style: Estilos.cuerpo.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colores.grisClaro),
                      borderRadius: Estilos.bordeRedondeado,
                      color: Colores.blanco,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _archivoSeleccionado != null
                              ? Icons.check_circle
                              : Icons.cloud_upload_outlined,
                          size: 48,
                          color: _archivoSeleccionado != null
                              ? Colores.exito
                              : Colores.gris,
                        ),
                        const SizedBox(height: 8),
                        
                        if (_archivoSeleccionado != null) ...[
                          Text(
                            'Archivo seleccionado:',
                            style: Estilos.cuerpoSecundario,
                          ),
                          Text(
                            _archivoSeleccionado!,
                            style: Estilos.cuerpo.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Text(
                            'Selecciona un archivo ZIP o RAR (opcional)',
                            style: Estilos.cuerpo,
                          ),
                          Text(
                            'Solo se permiten archivos .zip y .rar',
                            style: Estilos.cuerpoSecundario,
                          ),
                        ],
                        
                        const SizedBox(height: 12),
                        BotonPersonalizado(
                          texto: _archivoSeleccionado != null
                              ? 'Cambiar Archivo'
                              : 'Seleccionar Archivo',
                          alPresionar: _seleccionarArchivo,
                          ancho: 200,
                          color: _archivoSeleccionado != null
                              ? Colores.advertencia
                              : Colores.primario,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Informacion importante
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colores.advertencia.withOpacity(0.1),
                  border: Border.all(color: Colores.advertencia),
                  borderRadius: Estilos.bordeRedondeado,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colores.advertencia,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informacion Importante',
                          style: Estilos.cuerpo.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colores.advertencia,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Una vez enviado, tu proyecto quedara en estado "Pendiente de revision"\n'
                      '• El administrador revisara tu proyecto y te notificara el resultado\n'
                      '• Asegurate de que el enlace de GitHub sea publico y accesible\n'
                      '• El archivo ZIP debe contener todo el codigo fuente de tu proyecto',
                      style: Estilos.cuerpoSecundario,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Boton de envio
              BotonPersonalizado(
                texto: 'Enviar Proyecto',
                alPresionar: _enviarProyecto,
                cargando: _cargando,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}