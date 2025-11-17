import '../modelos/proyecto.dart';

abstract class OneDriveApi {
  Future<void> inicializar({required String clientId, String authority, String redirectUri});
  Future<bool> sincronizarProyectoOneDrive(Proyecto p, {String? localZipPath});
}

class OneDriveApiImpl implements OneDriveApi {
  @override
  Future<void> inicializar({required String clientId, String authority = 'https://login.microsoftonline.com/common', String redirectUri = ''}) async {}

  @override
  Future<bool> sincronizarProyectoOneDrive(Proyecto p, {String? localZipPath}) async {
    return false;
  }
}
