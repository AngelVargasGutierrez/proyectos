# Configuración de OneDrive (.env)

Para que el backend suba automáticamente el ZIP del proyecto a OneDrive al momento de enviar, define estas variables en `api/.env`:

- `ONEDRIVE_TENANT_ID`: ID del tenant de Azure AD (para cuentas organizacionales/OneDrive for Business).
- `ONEDRIVE_CLIENT_ID`: ID de la aplicación registrada en Azure.
- `ONEDRIVE_CLIENT_SECRET`: Secreto de la aplicación.
- `ONEDRIVE_REFRESH_TOKEN`: Refresh token obtenido tras autorizar la app con permisos delegados a Microsoft Graph.
- `ONEDRIVE_BASE_FOLDER` (opcional): Carpeta raíz donde se almacenarán los envíos. Por defecto `PROYECTOS`.
- `ONEDRIVE_SHARE_TYPE` (opcional): Tipo de enlace generado (`view` o `edit`). Por defecto `view`.
- `ONEDRIVE_SHARE_SCOPE` (opcional): Alcance del enlace (`anonymous` para público, `organization` para tu tenant). Por defecto `anonymous`.

Estructura de carpetas generada automáticamente:

```
<BASE_FOLDER>/concurso_<id>/categoria_<id>/estudiante_<id>/
```

Nombre del archivo: `<titulo>.zip` (espacios reemplazados por `_`).

## Cómo obtener el refresh token (resumen)

1. Registra una app en Azure AD (Portal Azure → Azure Active Directory → App registrations).
2. Habilita permisos Delegados a Microsoft Graph: `Files.ReadWrite.All`, `offline_access` y consiente para tu usuario.
3. Implementa el flujo OAuth en local (authorization code) para tu usuario y captura el `refresh_token` emitido.
4. Guarda el `refresh_token` en `.env`. El backend lo reutiliza para obtener nuevos `access_token` automáticamente.

Nota: si usas OneDrive personal, el flujo es similar pero el `TENANT_ID` puede ser `consumers`. Para OneDrive for Business, usa el tenant de tu organización y asegúrate de tener permisos y consentimiento adecuados.

## Endpoint de subida

- `POST /proyectos/upload` (multipart/form-data)
  - Campos `Form`: `titulo`, `github_url`, `estudiante_id`, `concurso_id`, `categoria_id`
  - Campo `File`: `zip_file` (archivo `.zip`)
  - Respuesta: `{ "id": <proyecto_id> }`

Este endpoint sube el ZIP a OneDrive, genera un enlace compartido y lo guarda en `zip_url` en la base de datos.