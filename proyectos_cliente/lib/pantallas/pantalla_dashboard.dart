import 'package:flutter/material.dart';
import '../modelos/concurso.dart';
import '../servicios/servicio_autenticacion.dart';
import '../servicios/servicio_concursos.dart';
import '../utilidades/estilos.dart';
import '../widgets/widgets_personalizados.dart';
import 'pantalla_detalle_concurso.dart';
import 'pantalla_mis_proyectos.dart';
import 'pantalla_inicio_sesion.dart';

class PantallaDashboard extends StatefulWidget {
  const PantallaDashboard({super.key});

  @override
  State<PantallaDashboard> createState() => _PantallaDashboardState();
}

class _PantallaDashboardState extends State<PantallaDashboard> {
  List<Concurso> _concursos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarConcursos();
  }

  Future<void> _cargarConcursos() async {
    setState(() {
      _cargando = true;
    });

    try {
      final concursos = await ServicioConcursos.instancia.obtenerConcursosDisponibles();
      if (mounted) {
        setState(() {
          _concursos = concursos;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar concursos'),
            backgroundColor: Colores.error,
          ),
        );
      }
    }
  }

  Future<void> _cerrarSesion() async {
    await ServicioAutenticacion.instancia.cerrarSesion();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PantallaInicioSesion(),
        ),
      );
    }
  }

  void _verMisProyectos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PantallaMisProyectos(),
      ),
    );
  }

  void _verDetalleConcurso(Concurso concurso) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PantallaDetalleConcurso(concurso: concurso),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estudiante = ServicioAutenticacion.instancia.estudianteActual;

    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colores.primario,
        foregroundColor: Colores.blanco,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            onPressed: _verMisProyectos,
            tooltip: 'Mis Proyectos',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar Sesion',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarConcursos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Estilos.paddingGeneral,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bienvenida
              TarjetaPersonalizada(
                hijo: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido, ${estudiante?.nombres ?? 'Estudiante'}',
                      style: Estilos.titulo,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Codigo: ${estudiante?.codigoUniversitario ?? ''}',
                      style: Estilos.cuerpoSecundario,
                    ),
                    Text(
                      'Ciclo: ${estudiante?.ciclo ?? 0}',
                      style: Estilos.cuerpoSecundario,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Titulo de concursos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Concursos Disponibles',
                    style: Estilos.subtitulo,
                  ),
                  TextButton.icon(
                    onPressed: _cargarConcursos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lista de concursos
              if (_cargando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_concursos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colores.gris,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay concursos disponibles',
                          style: Estilos.subtitulo,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Vuelve mas tarde para ver nuevos concursos',
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
                  itemCount: _concursos.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final concurso = _concursos[index];
                    return _construirTarjetaConcurso(concurso);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaConcurso(Concurso concurso) {
    return TarjetaPersonalizada(
      alPresionar: () => _verDetalleConcurso(concurso),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  concurso.nombre,
                  style: Estilos.subtitulo,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: concurso.estaVigente ? Colores.exito : Colores.gris,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  concurso.estaVigente ? 'Activo' : 'Inactivo',
                  style: const TextStyle(
                    color: Colores.blanco,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Text(
            concurso.descripcion,
            style: Estilos.cuerpo,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 16,
                color: Colores.gris,
              ),
              const SizedBox(width: 4),
              Text(
                '${concurso.categorias.length} categorias',
                style: Estilos.cuerpoSecundario,
              ),
              const Spacer(),
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colores.gris,
              ),
              const SizedBox(width: 4),
              Text(
                'Hasta ${concurso.fechaFin.day}/${concurso.fechaFin.month}/${concurso.fechaFin.year}',
                style: Estilos.cuerpoSecundario,
              ),
            ],
          ),
        ],
      ),
    );
  }
}