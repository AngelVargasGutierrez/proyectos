// Eliminado: ServicioBD ya no se usa directamente en Flutter.
// Esta clase se mantiene vacía para evitar romper imports existentes temporalmente.
// Se recomienda eliminar referencias y este archivo una vez completada la migración.

class ServicioBD {
  ServicioBD._();
  static final ServicioBD instancia = ServicioBD._();

  // Configuracion de conexion
  final ConnectionSettings _settings = ConnectionSettings(
    host: '161.132.55.248',
    port: 3306,
    user: 'admin',
    password: 'Upt2025',
    db: 'epis_proyectos',
    timeout: const Duration(seconds: 5),
  );

  Future<MySqlConnection> _conectar() async {
    return await MySqlConnection.connect(_settings);
  }

  Future<List<ResultRow>> consultar(String sql, [List<dynamic> params = const []]) async {
    final conn = await _conectar();
    try {
      final Results results = await conn.query(sql, params);
      return results.toList();
    } finally {
      await conn.close();
    }
  }

  Future<int> ejecutar(String sql, [List<dynamic> params = const []]) async {
    final conn = await _conectar();
    try {
      final Results results = await conn.query(sql, params);
      return results.affectedRows ?? 0;
    } finally {
      await conn.close();
    }
  }

  Future<int> insertar(String sql, [List<dynamic> params = const []]) async {
    final conn = await _conectar();
    try {
      final Results results = await conn.query(sql, params);
      return results.insertId ?? 0;
    } finally {
      await conn.close();
    }
  }
}