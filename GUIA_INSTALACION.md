# 📖 Guía de Instalación Completa

Esta guía te llevará paso a paso por la instalación y configuración del sistema.

## 📋 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

- **Docker** (versión 20.10 o superior)
- **Docker Compose** (versión 2.0 o superior)
- **Git**

### Verificar Instalación

```bash
# Verificar Docker
docker --version

# Verificar Docker Compose
docker-compose --version

# Verificar Git
git --version
```

## 🚀 Instalación Paso a Paso

### Paso 1: Clonar el Repositorio

```bash
git clone <url-del-repositorio>
cd xlsx-loader-system
```

### Paso 2: Configurar Variables de Entorno

#### Backend

```bash
cd backend
cp .env.example .env
```

Edita `backend/.env` si necesitas cambiar configuraciones:

```env
# Database
DATABASE_URL=mysql+pymysql://user:password@mysql:3306/xlsx_db
DB_HOST=mysql
DB_PORT=3306
DB_USER=user
DB_PASSWORD=password
DB_NAME=xlsx_db

# Redis
REDIS_URL=redis://redis:6379/0

# Celery
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
CELERY_TASK_TIME_LIMIT=3600

# CORS
CORS_ORIGINS=["http://localhost:4200","http://localhost"]

# Upload
MAX_UPLOAD_SIZE=10485760
ASYNC_THRESHOLD=200
```

#### Frontend

```bash
cd ../frontend
```

Las configuraciones están en `src/environments/environment.ts`. Edita si es necesario:

```typescript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8000/api',
  wsUrl: 'ws://localhost:8000/api/ws',
  maxFileSize: 10485760,
  allowedExtensions: ['.xlsx', '.xls'],
  asyncThreshold: 200
};
```

### Paso 3: Usar el Script de Inicialización (Recomendado)

```bash
# Volver al directorio raíz
cd ..

# Dar permisos de ejecución al script
chmod +x init.sh

# Ejecutar el script
./init.sh
```

El script hará:
- ✅ Verificar Docker y Docker Compose
- ✅ Crear archivos .env si no existen
- ✅ Construir las imágenes Docker
- ✅ Iniciar todos los servicios
- ✅ Ejecutar migraciones de base de datos

### Paso 4: Instalación Manual (Alternativa)

Si prefieres hacerlo manualmente:

```bash
# Construir imágenes
docker-compose build

# Iniciar servicios
docker-compose up -d

# Esperar a que MySQL esté listo (30-60 segundos)
sleep 30

# Ejecutar migraciones
docker-compose exec backend alembic upgrade head
```

### Paso 5: Verificar Instalación

```bash
# Ver estado de los servicios
docker-compose ps

# Todos los servicios deben estar "Up"
```

Deberías ver algo como:

```
NAME                    STATUS
xlsx_mysql              Up
xlsx_redis              Up
xlsx_backend            Up
xlsx_celery_worker      Up
xlsx_celery_beat        Up
xlsx_flower             Up
xlsx_frontend           Up
```

### Paso 6: Acceder a la Aplicación

Abre tu navegador y visita:

- **Frontend**: http://localhost:4200
- **API Docs**: http://localhost:8000/docs
- **Flower (Monitor Celery)**: http://localhost:5555

## 🧪 Probar el Sistema

### 1. Crear un Archivo de Prueba

Crea un archivo Excel llamado `test_data.xlsx` con estas columnas:

| nombre | apellido | edad | correo | tipo_sangre |
|--------|----------|------|--------|-------------|
| Juan | Pérez | 30 | juan@email.com | O+ |
| María | González | 25 | maria@email.com | A+ |
| Carlos | Rodríguez | 35 | carlos@email.com | B+ |

### 2. Cargar el Archivo

1. Ve a http://localhost:4200
2. Haz clic en "Cargar Archivo"
3. Selecciona tu archivo `test_data.xlsx`
4. El sistema validará automáticamente
5. Selecciona los registros a cargar
6. Haz clic en "Cargar Registros"

### 3. Ver Resultados

- Ve a la pestaña "Personas" para ver los datos cargados
- Ve a la pestaña "Historial" para ver el registro de la carga
- Observa los gráficos de estadísticas

## 🔧 Comandos Útiles

### Ver Logs

```bash
# Todos los servicios
docker-compose logs -f

# Un servicio específico
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f celery_worker
```

### Reiniciar Servicios

```bash
# Reiniciar todo
docker-compose restart

# Reiniciar un servicio específico
docker-compose restart backend
```

### Detener el Sistema

```bash
# Detener servicios (mantiene datos)
docker-compose down

# Detener y eliminar volúmenes (elimina datos)
docker-compose down -v
```

### Acceder a la Base de Datos

```bash
# MySQL
docker-compose exec mysql mysql -u user -ppassword xlsx_db

# Ver tablas
SHOW TABLES;

# Ver personas
SELECT * FROM personas;
```

### Acceder a Redis

```bash
# Redis CLI
docker-compose exec redis redis-cli

# Ver todas las claves
KEYS *
```

### Ejecutar Comandos en el Backend

```bash
# Shell interactivo
docker-compose exec backend bash

# Ejecutar migraciones
docker-compose exec backend alembic upgrade head

# Crear nueva migración
docker-compose exec backend alembic revision --autogenerate -m "descripcion"
```

## 🐛 Solución de Problemas Comunes

### Error: "port is already allocated"

**Problema**: Otro servicio está usando el puerto.

**Solución**:
```bash
# Ver qué está usando el puerto
sudo lsof -i :8000  # o el puerto que falla

# Cambiar el puerto en docker-compose.yml
# Por ejemplo, para el backend:
ports:
  - "8001:8000"  # Cambiar el primer número
```

### Error: "MySQL connection refused"

**Problema**: MySQL no está listo aún.

**Solución**:
```bash
# Esperar más tiempo
docker-compose logs mysql

# Cuando veas "ready for connections", intenta de nuevo
docker-compose restart backend
```

### Error: "Cannot connect to WebSocket"

**Problema**: Backend no está corriendo o configuración incorrecta.

**Solución**:
```bash
# Verificar backend
docker-compose logs backend

# Verificar configuración en frontend/src/environments/environment.ts
wsUrl: 'ws://localhost:8000/api/ws'
```

### Error: "Module not found" en Frontend

**Problema**: Dependencias no instaladas correctamente.

**Solución**:
```bash
# Reconstruir el frontend
docker-compose build frontend
docker-compose up -d frontend
```

### Error: Celery no procesa tareas

**Problema**: Redis no conecta o worker no corriendo.

**Solución**:
```bash
# Verificar Redis
docker-compose exec redis redis-cli ping
# Debe responder: PONG

# Reiniciar worker
docker-compose restart celery_worker

# Ver logs
docker-compose logs celery_worker
```

## 🔒 Configuración para Producción

### 1. Cambiar Credenciales

Edita `backend/.env`:

```env
DB_PASSWORD=<contraseña-segura>
MYSQL_ROOT_PASSWORD=<contraseña-root-segura>
```

### 2. Configurar CORS

```env
CORS_ORIGINS=["https://tu-dominio.com"]
```

### 3. Usar HTTPS

Configura un reverse proxy (Nginx) con SSL:

```nginx
server {
    listen 443 ssl;
    server_name tu-dominio.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:4200;
    }
    
    location /api {
        proxy_pass http://localhost:8000;
    }
}
```

### 4. Optimizar Frontend

```bash
cd frontend
ng build --configuration production
```

## 📊 Verificar que Todo Funciona

Ejecuta este checklist:

- [ ] Docker y Docker Compose instalados
- [ ] Todos los servicios corriendo (`docker-compose ps`)
- [ ] Frontend accesible en http://localhost:4200
- [ ] Backend API Docs en http://localhost:8000/docs
- [ ] Flower en http://localhost:5555
- [ ] Archivo de prueba carga correctamente
- [ ] WebSocket conecta (ver consola del navegador)
- [ ] Gráficos se muestran en pestaña "Personas"
- [ ] Historial registra las cargas

## 🎉 ¡Listo!

Si llegaste hasta aquí, tu sistema está completamente instalado y funcionando.

### Próximos Pasos

1. Carga archivos XLSX de prueba
2. Explora las estadísticas y gráficos
3. Revisa el historial de cargas
4. Prueba con archivos grandes (>200 registros) para ver Celery en acción

### Recursos Adicionales

- [README Principal](README.md)
- [Backend README](backend/README.md)
- [Frontend README](frontend/README.md)
- [API Documentation](http://localhost:8000/docs)

---

**¿Problemas?** Abre un issue con:
- Salida de `docker-compose ps`
- Logs relevantes
- Descripción del problema