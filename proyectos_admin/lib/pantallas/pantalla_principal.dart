import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../proveedores/proveedor_autenticacion.dart';
import '../proveedores/proveedor_concursos.dart';
import '../modelos/administrador.dart';
import 'pantalla_inicio_sesion.dart';
import 'pantalla_crear_concurso.dart';
import 'pantalla_lista_concursos.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _indiceSeleccionado = 0;

  final List<Widget> _pantallas = [
    const PantallaListaConcursos(),
    const PantallaCrearConcurso(),
  ];

  @override
  void initState() {
    super.initState();
    // Cargar concursos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProveedorConcursos>(context, listen: false).cargarConcursos();
    });
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesion'),
          content: const Text('Estas seguro de que deseas cerrar sesion?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<ProveedorAutenticacion>(context, listen: false).cerrarSesion();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const PantallaInicioSesion()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesion'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final proveedorAuth = Provider.of<ProveedorAutenticacion>(context);
    final esJurado = proveedorAuth.administradorActual?.rol == RolUsuario.jurado;
    return Scaffold(
      appBar: AppBar(
        title: Text(esJurado ? 'Jurados - Concursos' : 'Administrador de Concursos'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          Consumer<ProveedorAutenticacion>(
            builder: (context, proveedor, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'cerrar_sesion') {
                    _cerrarSesion();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proveedor.administradorActual?.nombreCompleto ?? 'Usuario',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          proveedor.administradorActual?.correo ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'cerrar_sesion',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cerrar Sesion'),
                      ],
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.account_circle, size: 32),
                ),
              );
            },
          ),
        ],
      ),
      body: (esJurado
          ? const PantallaListaConcursos()
          : _pantallas[_indiceSeleccionado]),
      // Para jurado no mostramos BottomNavigationBar (evitar assert de >=2 items)
      bottomNavigationBar: esJurado
          ? null
          : BottomNavigationBar(
              currentIndex: _indiceSeleccionado,
              onTap: (index) {
                setState(() {
                  _indiceSeleccionado = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blue[700],
              unselectedItemColor: Colors.grey[600],
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'Concursos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle),
                  label: 'Crear Concurso',
                ),
              ],
            ),
    );
  }
}