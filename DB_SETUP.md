# EPIS Proyectos – Script de Base de Datos (MySQL)

Este documento contiene el script SQL listo para copiar y pegar que crea la base de datos `epis_proyectos`, sus tablas, llaves foráneas e índices necesarios, el usuario MySQL de aplicación, y el administrador inicial con correo `admin@upt.pe`.

Requisitos:
- MySQL 8.0 o superior
- Motor InnoDB
- Juego de caracteres `utf8mb4`

Notas:
- El usuario de conexión de las apps es `admin` con contraseña `Upt2025`. Puedes cambiarlo si lo deseas, pero recuerda actualizarlo también en el código.
- La contraseña del administrador inicial será `admin` y se guarda como hash SHA-256.
- Los estados válidos de proyectos son: `enviado`, `en_revision`, `aprobado`, `rechazado`, `ganador`.

---

## 1) Crear Base de Datos y Usuario de Aplicación

```sql
-- Ejecutar con un usuario con privilegios (p.ej., root)
CREATE DATABASE IF NOT EXISTS epis_proyectos
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

-- Crear/ajustar el usuario de aplicación
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'Upt2025';
GRANT ALL PRIVILEGES ON epis_proyectos.* TO 'admin'@'%';
FLUSH PRIVILEGES;

USE epis_proyectos;
```

---

## 2) Tablas

```sql
-- Administradores
CREATE TABLE IF NOT EXISTS administradores (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombres VARCHAR(100) NOT NULL,
  apellidos VARCHAR(100) NOT NULL,
  correo VARCHAR(150) NOT NULL UNIQUE,
  numero_telefono VARCHAR(20) NOT NULL,
  contrasena_hash CHAR(64) NOT NULL, -- SHA-256 hex
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Estudiantes
CREATE TABLE IF NOT EXISTS estudiantes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombres VARCHAR(100) NOT NULL,
  apellidos VARCHAR(100) NOT NULL,
  codigo_universitario VARCHAR(20) NOT NULL UNIQUE,
  correo VARCHAR(150) NOT NULL UNIQUE,
  numero_telefono VARCHAR(20) NOT NULL,
  ciclo INT NOT NULL,
  contrasena_hash CHAR(64) NOT NULL, -- SHA-256 hex
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Concursos
CREATE TABLE IF NOT EXISTS concursos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(200) NOT NULL,
  administrador_id INT NOT NULL,
  fecha_limite_inscripcion DATETIME NOT NULL,
  fecha_revision DATETIME NOT NULL,
  fecha_confirmacion_aceptados DATETIME NOT NULL,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_concursos_admin FOREIGN KEY (administrador_id)
    REFERENCES administradores(id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Categorías
CREATE TABLE IF NOT EXISTS categorias (
  id INT AUTO_INCREMENT PRIMARY KEY,
  concurso_id INT NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  rango_ciclos VARCHAR(100) NULL,
  CONSTRAINT fk_categorias_concurso FOREIGN KEY (concurso_id)
    REFERENCES concursos(id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT uq_categoria_por_concurso UNIQUE (concurso_id, nombre)
) ENGINE=InnoDB;

-- Proyectos
CREATE TABLE IF NOT EXISTS proyectos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(200) NOT NULL,
  github_url VARCHAR(255) NULL,
  zip_url VARCHAR(255) NULL,
  estudiante_id INT NOT NULL,
  concurso_id INT NOT NULL,
  categoria_id INT NOT NULL,
  fecha_envio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('enviado','en_revision','aprobado','rechazado','ganador') NOT NULL DEFAULT 'enviado',
  comentarios TEXT NULL,
  puntuacion DECIMAL(5,2) NULL,
  CONSTRAINT fk_proyectos_estudiante FOREIGN KEY (estudiante_id)
    REFERENCES estudiantes(id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_proyectos_concurso FOREIGN KEY (concurso_id)
    REFERENCES concursos(id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_proyectos_categoria FOREIGN KEY (categoria_id)
    REFERENCES categorias(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;
```

---

## 3) Índices útiles

```sql
-- Nota: MySQL no soporta IF NOT EXISTS en CREATE INDEX.
-- Ejecuta estas sentencias una sola vez.

-- Concursos
CREATE INDEX idx_concursos_admin ON concursos (administrador_id);

-- Categorías
CREATE INDEX idx_categorias_concurso ON categorias (concurso_id);

-- Proyectos
CREATE INDEX idx_proyectos_concurso ON proyectos (concurso_id);
CREATE INDEX idx_proyectos_categoria ON proyectos (categoria_id);
CREATE INDEX idx_proyectos_estudiante ON proyectos (estudiante_id);
CREATE INDEX idx_proyectos_estado ON proyectos (estado);
```

---

## 4) Administrador inicial (admin@upt.pe)

```sql
-- Insertar administrador inicial
INSERT INTO administradores (nombres, apellidos, correo, numero_telefono, contrasena_hash)
VALUES ('Admin', 'Principal', 'admin@upt.pe', '999999999', SHA2('admin', 256));
```

Puedes cambiar el número de teléfono o la contraseña (`'admin'`) a lo que desees. Si cambias la contraseña, recuerda que las apps hacen hash SHA-256 del texto plano antes de comparar.

---

## 5) Datos de ejemplo opcionales

```sql
-- Crear un concurso de prueba (usa el administrador con id=1)
INSERT INTO concursos (nombre, administrador_id, fecha_limite_inscripcion, fecha_revision, fecha_confirmacion_aceptados, fecha_creacion)
VALUES (
  'Concurso de Proyectos EPIS',
  1,
  DATE_ADD(NOW(), INTERVAL 30 DAY),
  DATE_ADD(NOW(), INTERVAL 45 DAY),
  DATE_ADD(NOW(), INTERVAL 60 DAY),
  NOW()
);

-- Categorías para el concurso recién creado
SET @id_concurso := LAST_INSERT_ID();
INSERT INTO categorias (concurso_id, nombre, rango_ciclos) VALUES
(@id_concurso, 'Categoria Junior', 'I a III ciclo'),
(@id_concurso, 'Categoria Intermedio', 'IV a VI ciclo'),
(@id_concurso, 'Categoria Senior', 'VII a X ciclo');
```

---

## 6) Verificaciones rápidas

```sql
-- Debe listar 1 administrador
SELECT id, nombres, apellidos, correo FROM administradores;

-- Debe listar al menos 1 concurso y sus categorías
SELECT c.id, c.nombre, c.administrador_id FROM concursos c;
SELECT ca.id, ca.concurso_id, ca.nombre FROM categorias ca WHERE ca.concurso_id = @id_concurso;
```

---

## 7) Observaciones de seguridad

- Exponer MySQL directamente a apps móviles implica riesgos. Considera, a mediano plazo, mover a una API intermedia.
- Usa credenciales de conexión diferentes a administración del servidor.
- Restringe el acceso del usuario `'admin'@'%'` si puedes (p.ej., a IPs específicas) y/o cambia la contraseña periódicamente.

---

## 8) Proyectos de ejemplo con enlaces GitHub

```sql
-- Asegúrate de haber ejecutado la sección 5) para crear @id_concurso
USE epis_proyectos;

-- Estudiantes de ejemplo (se ignoran si ya existen por restricciones únicas)
INSERT IGNORE INTO estudiantes (nombres, apellidos, codigo_universitario, correo, numero_telefono, ciclo, contrasena_hash) VALUES
('Juan Carlos','Pérez','20200001','juan.perez@estudiante.edu.pe','999111111',7,SHA2('123456',256)),
('María Elena','García','20200002','maria.garcia@estudiante.edu.pe','999222222',5,SHA2('123456',256)),
('Carlos Alberto','Ruiz','20200003','carlos.ruiz@estudiante.edu.pe','999333333',9,SHA2('123456',256)),
('Ana Sofía','López','20200004','ana.lopez@estudiante.edu.pe','999444444',2,SHA2('123456',256));

-- Obtener IDs de estudiantes
SELECT id INTO @est_juan   FROM estudiantes WHERE correo='juan.perez@estudiante.edu.pe'   LIMIT 1;
SELECT id INTO @est_maria  FROM estudiantes WHERE correo='maria.garcia@estudiante.edu.pe' LIMIT 1;
SELECT id INTO @est_carlos FROM estudiantes WHERE correo='carlos.ruiz@estudiante.edu.pe' LIMIT 1;
SELECT id INTO @est_ana    FROM estudiantes WHERE correo='ana.lopez@estudiante.edu.pe'   LIMIT 1;

-- Obtener IDs de categorías del concurso de prueba
SELECT id INTO @cat_junior      FROM categorias WHERE concurso_id=@id_concurso AND nombre='Categoria Junior'      LIMIT 1;
SELECT id INTO @cat_intermedio  FROM categorias WHERE concurso_id=@id_concurso AND nombre='Categoria Intermedio'  LIMIT 1;
SELECT id INTO @cat_senior      FROM categorias WHERE concurso_id=@id_concurso AND nombre='Categoria Senior'      LIMIT 1;

-- Insertar proyectos con enlaces GitHub y ZIP
INSERT INTO proyectos (titulo, github_url, zip_url, estudiante_id, concurso_id, categoria_id, fecha_envio, estado) VALUES
('Sistema de Gestión Académica','https://github.com/estudiante1/sistema-academico','sistema-academico.zip', @est_juan,  @id_concurso, @cat_senior,     NOW(), 'enviado'),
('App de Reservas Móvil','https://github.com/estudiante2/app-reservas','app-reservas.zip',                 @est_maria, @id_concurso, @cat_intermedio, NOW(), 'en_revision'),
('Plataforma de E-learning','https://github.com/estudiante3/e-learning','e-learning-platform.zip',         @est_carlos,@id_concurso, @cat_senior,     NOW(), 'aprobado'),
('Sistema de Inventario','https://github.com/estudiante4/inventario','sistema-inventario.zip',             @est_ana,   @id_concurso, @cat_junior,     NOW(), 'ganador');

-- Verificar
SELECT id, titulo, github_url, zip_url, estudiante_id, categoria_id, estado FROM proyectos WHERE concurso_id=@id_concurso ORDER BY id DESC;
```