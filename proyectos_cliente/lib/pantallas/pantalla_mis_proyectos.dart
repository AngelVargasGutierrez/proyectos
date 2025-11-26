import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../modelos/proyecto.dart';
import '../servicios/servicio_autenticacion.dart';
import '../servicios/servicio_concursos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utilidades/estilos.dart';
import '../widgets/widgets_personalizados.dart';

class PantallaMisProyectos extends StatefulWidget {
  const PantallaMisProyectos({super.key});

  @override
  State<PantallaMisProyectos> createState() => _PantallaMisProyectosState();
}

class _PantallaMisProyectosState extends State<PantallaMisProyectos> {
  List<Proyecto> _proyectos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  Future<void> _cargarProyectos() async {
    setState(() {
      _cargando = true;
    });

    try {
      final estudiante = ServicioAutenticacion.instancia.estudianteActual;
      print('DEBUG: Estudiante actual: ${estudiante?.id} - ${estudiante?.correo}');
      
      String uid = estudiante?.id ?? '';
      if (uid.isEmpty) {
        try {
          final authUid = FirebaseAuth.instance.currentUser?.uid;
          print('DEBUG: Firebase Auth UID: $authUid');
          if (authUid != null && authUid.isNotEmpty) uid = authUid;
        } catch (_) {}
      }
      
      print('DEBUG: UID final para buscar proyectos: $uid');
      
      if (uid.isNotEmpty) {
        final proyectos = await ServicioConcursos.instancia
            .obtenerProyectosEstudiante(uid);
        print('DEBUG: Proyectos encontrados: ${proyectos.length}');
        for (var p in proyectos) {
          print('  - ${p.nombre} (${p.estado.name})');
        }
        if (mounted) {
          setState(() {
            _proyectos = proyectos;
            _cargando = false;
          });
        }
      } else {
        print('DEBUG: UID vacio, no se pueden cargar proyectos');
        if (mounted) {
          setState(() {
            _cargando = false;
          });
        }
      }
    } catch (e) {
      print('DEBUG: Error al cargar proyectos: $e');
      if (mounted) {
        setState(() {
          _cargando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar proyectos: $e'),
            backgroundColor: Colores.error,
          ),
        );
      }
    }
  }

  Future<void> _abrirEnlaceGithub(String enlace) async {
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

  void _mostrarDetalleProyecto(Proyecto proyecto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(proyecto.nombre),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _construirFilaDetalle('Estado:', proyecto.estadoTexto),
              if ((proyecto.categoriaNombre ?? '').isNotEmpty)
                _construirFilaDetalle('Categoría:', proyecto.categoriaNombre!),
              _construirFilaDetalle(
                'Fecha de envio:',
                '${proyecto.fechaEnvio.day}/${proyecto.fechaEnvio.month}/${proyecto.fechaEnvio.year}',
              ),
              _construirFilaDetalle('Enlace GitHub:', proyecto.enlaceGithub),
              _construirFilaDetalle('Archivo:', proyecto.archivoZip),
              if ((proyecto.onedriveUrl ?? '').isNotEmpty &&
                  (proyecto.estado == EstadoProyecto.aprobado || proyecto.estado == EstadoProyecto.apto))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InkWell(
                    onTap: () async {
                      final uri = Uri.parse(proyecto.onedriveUrl!.trim());
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_outlined, color: Colores.primario),
                        const SizedBox(width: 8),
                        const Text('Abrir carpeta OneDrive'),
                      ],
                    ),
                  ),
                ),
              
              if (proyecto.comentarioAdmin != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Comentario del Administrador:',
                  style: Estilos.cuerpo.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colores.fondo,
                    borderRadius: Estilos.bordeRedondeado,
                    border: Border.all(color: Colores.grisClaro),
                  ),
                  child: Text(
                    proyecto.comentarioAdmin!,
                    style: Estilos.cuerpo,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (proyecto.enlaceGithub.isNotEmpty)
            TextButton.icon(
              onPressed: () => _abrirEnlaceGithub(proyecto.enlaceGithub),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ver en GitHub'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _construirFilaDetalle(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              etiqueta,
              style: Estilos.cuerpoSecundario,
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: Estilos.cuerpo,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        title: const Text('Mis Proyectos'),
        backgroundColor: Colores.primario,
        foregroundColor: Colores.blanco,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProyectos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarProyectos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Estilos.paddingGeneral,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tus Proyectos Enviados',
                style: Estilos.subtitulo,
              ),
              const SizedBox(height: 16),

              if (_cargando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_proyectos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colores.gris,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes proyectos enviados',
                          style: Estilos.subtitulo,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Participa en un concurso para ver tus proyectos aqui',
                          style: Estilos.cuerpoSecundario,
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
                  itemCount: _proyectos.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final proyecto = _proyectos[index];
                    return _construirTarjetaProyecto(proyecto);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaProyecto(Proyecto proyecto) {
    Color colorEstado;
    IconData iconoEstado;

    switch (proyecto.estado) {
      case EstadoProyecto.aprobado:
        colorEstado = Colores.exito;
        iconoEstado = Icons.check_circle;
        break;
      case EstadoProyecto.rechazado:
        colorEstado = Colores.error;
        iconoEstado = Icons.cancel;
        break;
      case EstadoProyecto.pendiente:
        colorEstado = Colores.advertencia;
        iconoEstado = Icons.schedule;
        break;
      case EstadoProyecto.apto:
        colorEstado = Colores.exito;
        iconoEstado = Icons.verified_user;
        break;
      case EstadoProyecto.finalizado:
        colorEstado = Colores.gris;
        iconoEstado = Icons.flag;
        break;
      case EstadoProyecto.ganador:
        colorEstado = Colors.purple;
        iconoEstado = Icons.emoji_events;
        break;
    }

    return TarjetaPersonalizada(
      alPresionar: () => _mostrarDetalleProyecto(proyecto),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  proyecto.nombre,
                  style: Estilos.subtitulo,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconoEstado,
                      size: 16,
                      color: Colores.blanco,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      proyecto.estadoTexto,
                      style: const TextStyle(
                        color: Colores.blanco,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colores.gris,
              ),
              const SizedBox(width: 4),
              Text(
                'Enviado el ${proyecto.fechaEnvio.day}/${proyecto.fechaEnvio.month}/${proyecto.fechaEnvio.year}',
                style: Estilos.cuerpoSecundario,
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          Row(
            children: [
              Icon(
                Icons.link,
                size: 16,
                color: Colores.gris,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  proyecto.enlaceGithub,
                  style: Estilos.cuerpoSecundario,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 16),
                onPressed: () => _abrirEnlaceGithub(proyecto.enlaceGithub),
                tooltip: 'Abrir en GitHub',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colores.gris,
              ),
              const SizedBox(width: 4),
              Text(
                'Toca para ver mas detalles',
                style: Estilos.cuerpoSecundario.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}