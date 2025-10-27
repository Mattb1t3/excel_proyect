# XLSX Loader - Backend API

Backend desarrollado con FastAPI para cargar y validar archivos XLSX con integración de MySQL, Redis y Celery.

## 🚀 Características

- **FastAPI** - Framework web moderno y rápido
- **SQLAlchemy** - ORM asíncrono para MySQL
- **Celery** - Tareas asíncronas para carga masiva
- **Redis** - Cache y broker de mensajes
- **WebSocket** - Notificaciones en tiempo real
- **Alembic** - Migraciones de base de datos
- **Docker** - Contenedorización completa

## 📋 Requisitos

- Docker y Docker Compose
- Python 3.11+ (para desarrollo local)

## 🛠️ Instalación

### Con Docker (Recomendado)

```bash
# Clonar el repositorio
git clone <repo-url>
cd backend

# Copiar archivo de entorno
cp .env.example .env

# Editar .env con tus configuraciones
nano .env

# Levantar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f backend
```

### Sin Docker (Desarrollo Local)

```bash
# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
# o
venv\Scripts\activate  # Windows

# Instalar dependencias
pip install -r requirements.txt

# Configurar variables de entorno
cp .env.example .env

# Ejecutar migraciones
alembic upgrade head

# Iniciar servidor
uvicorn app.main:app --reload --port 8000

# En otra terminal, iniciar Celery worker
celery -A app.core.celery_app worker --loglevel=info

# Opcional: Iniciar Flower (monitor de Celery)
celery -A app.core.celery_app flower --port=5555
```

## 📁 Estructura del Proyecto

```
backend/
├── app/
│   ├── core/
│   │   ├── config.py           # Configuración
│   │   ├── database.py         # Conexión a BD
│   │   ├── celery_app.py       # Configuración Celery
│   │   └── websocket_manager.py # Manager WebSocket
│   ├── models/
│   │   ├── persona.py          # Modelo Persona
│   │   └── historial.py        # Modelo Historial
│   ├── schemas/
│   │   ├── response.py         # Schemas de respuesta
│   │   ├── persona.py          # Schemas de Persona
│   │   └── historial.py        # Schemas de Historial
│   ├── services/
│   │   ├── xlsx_validator.py   # Validador de XLSX
│   │   ├── persona_service.py  # Servicio de Personas
│   │   └── historial_service.py # Servicio de Historial
│   ├── routers/
│   │   ├── upload.py           # Endpoints de carga
│   │   ├── personas.py         # Endpoints de personas
│   │   ├── historial.py        # Endpoints de historial
│   │   ├── tasks.py            # Endpoints de tareas
│   │   └── websocket.py        # WebSocket endpoint
│   ├── tasks/
│   │   └── carga_tasks.py      # Tareas de Celery
│   └── main.py                 # Aplicación principal
├── alembic/
│   ├── versions/               # Migraciones
│   └── env.py                  # Configuración Alembic
├── temp_uploads/               # Archivos temporales
├── Dockerfile
├── requirements.txt
├── alembic.ini
└── .env.example
```

## 🔌 API Endpoints

### Upload
- `POST /api/upload/validate` - Validar archivo XLSX
- `POST /api/upload/process` - Procesar y cargar datos

### Personas
- `GET /api/personas` - Listar personas
- `GET /api/personas/{id}` - Obtener persona
- `POST /api/personas` - Crear persona
- `PUT /api/personas/{id}` - Actualizar persona
- `DELETE /api/personas/{id}` - Eliminar persona
- `GET /api/personas/estadisticas/resumen` - Estadísticas

### Historial
- `GET /api/historial` - Listar historial de cargas
- `GET /api/historial/{id}` - Detalle de carga

### Tasks
- `GET /api/tasks/{task_id}/status` - Estado de tarea Celery

### WebSocket
- `WS /api/ws` - Conexión WebSocket para notificaciones

## 📊 Formato de Respuestas

Todas las respuestas siguen el formato:

```json
{
  "estado": true,
  "tipo": "success",
  "titulo": "Operación Exitosa",
  "mensaje": "Descripción del resultado",
  "datos": {},
  "errores": null
}
```

## 🗃️ Estructura del Archivo XLSX

El archivo debe contener las siguientes columnas:

| Columna | Tipo | Validación |
|---------|------|------------|
| nombre | String | Requerido, no vacío |
| apellido | String | Requerido, no vacío |
| edad | Integer | 0-150 años |
| correo | String | Formato email válido |
| tipo_sangre | String | A+, A-, B+, B-, AB+, AB-, O+, O- |

## 🔄 Migraciones de Base de Datos

```bash
# Crear nueva migración
alembic revision --autogenerate -m "descripcion"

# Aplicar migraciones
alembic upgrade head

# Revertir última migración
alembic downgrade -1

# Ver historial
alembic history
```

## 🧪 Testing

```bash
# Ejecutar tests
pytest

# Con coverage
pytest --cov=app tests/
```

## 🐛 Troubleshooting

### Error de conexión a MySQL
- Verificar que el contenedor de MySQL esté corriendo
- Esperar a que MySQL esté completamente inicializado (puede tardar 30-60 segundos)
- Verificar credenciales en `.env`

### Error de conexión a Redis
- Verificar que Redis esté corriendo: `docker-compose ps redis`
- Reiniciar Redis: `docker-compose restart redis`

### Celery no procesa tareas
- Verificar que el worker esté corriendo: `docker-compose logs celery_worker`
- Revisar conexión a Redis
- Verificar que la cola esté configurada correctamente

### Archivos XLSX no se procesan
- Verificar permisos del directorio `temp_uploads/`
- Verificar tamaño máximo del archivo (10MB por defecto)
- Revisar logs del backend

## 📝 Variables de Entorno

```bash
# Application
APP_NAME=XLSX Loader API
APP_VERSION=1.0.0
DEBUG=True

# Database
DATABASE_URL=mysql+pymysql://user:password@mysql:3306/xlsx_db
DB_HOST=mysql
DB_PORT=3306
DB_USER=user
DB_PASSWORD=password
DB_NAME=xlsx_db

# Redis
REDIS_URL=redis://redis:6379/0
REDIS_HOST=redis
REDIS_PORT=6379

# Celery
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
CELERY_TASK_TIME_LIMIT=3600

# CORS
CORS_ORIGINS=["http://localhost:4200","http://localhost"]

# Upload
MAX_UPLOAD_SIZE=10485760  # 10MB
ASYNC_THRESHOLD=200  # Registros para activar Celery
```

## 🔐 Seguridad

- Las contraseñas deben cambiarse en producción
- Configurar CORS apropiadamente para producción
- Usar HTTPS en producción
- Implementar rate limiting
- Validar y sanitizar todas las entradas

## 📈 Monitoreo

### Flower (Celery Monitor)
Acceder a: http://localhost:5555

### Health Check
```bash
curl http://localhost:8000/health
```

## 🚀 Deployment

### Producción con Docker

```bash
# Build para producción
docker-compose -f docker-compose.prod.yml build

# Deploy
docker-compose -f docker-compose.prod.yml up -d

# Ver logs
docker-compose -f docker-compose.prod.yml logs -f
```

## 📚 Documentación API

Una vez el servidor esté corriendo:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🤝 Contribución

1. Fork el proyecto
2. Crear feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

## 📄 Licencia

Este proyecto está bajo licencia MIT.