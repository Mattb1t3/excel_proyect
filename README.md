# 📊 Sistema de Carga de Archivos XLSX

Sistema completo para la carga, validación y visualización de datos desde archivos XLSX, desarrollado con FastAPI, Angular 16, MySQL, Redis y Celery.

## 🎯 Características Principales

### Backend (FastAPI)
- ✅ Validación completa de archivos XLSX
- ✅ Carga síncrona y asíncrona (Celery)
- ✅ Detección de duplicados
- ✅ WebSocket para notificaciones en tiempo real
- ✅ API RESTful con respuestas estandarizadas
- ✅ Migraciones con Alembic
- ✅ Health checks
- ✅ Dockerizado

### Frontend (Angular 16)
- ✅ Interfaz moderna y responsive
- ✅ Carga y edición de datos
- ✅ Gráficos estadísticos con Chart.js
- ✅ Historial de cargas
- ✅ Notificaciones en tiempo real
- ✅ Búsqueda y filtros
- ✅ Dockerizado

## 🏗️ Arquitectura

```
┌─────────────────┐
│   Angular 16    │ ← Frontend
│   (Port 4200)   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│    FastAPI      │ ← Backend API
│   (Port 8000)   │
└────────┬────────┘
         │
    ┌────┴────┬──────────────┬──────────┐
    ↓         ↓              ↓          ↓
┌───────┐ ┌───────┐  ┌──────────┐ ┌──────────┐
│ MySQL │ │ Redis │  │  Celery  │ │WebSocket │
│ :3306 │ │ :6379 │  │  Worker  │ │   Real   │
└───────┘ └───────┘  └──────────┘ │   Time   │
                                   └──────────┘
```

## 🚀 Inicio Rápido

### Prerequisitos
- Docker y Docker Compose instalados
- Git

### Instalación Completa

```bash
# Clonar el repositorio
git clone <repo-url>
cd xlsx-loader-system

# Iniciar todos los servicios
docker-compose up -d

# Ver logs
docker-compose logs -f

# Verificar estado
docker-compose ps
```

### Acceder a los Servicios

- **Frontend**: http://localhost:4200
- **Backend API**: http://localhost:8000
- **API Docs (Swagger)**: http://localhost:8000/docs
- **Flower (Monitor Celery)**: http://localhost:5555
- **MySQL**: localhost:3306
- **Redis**: localhost:6379

## 📋 Estructura del Archivo XLSX

El archivo debe contener las siguientes columnas:

| Columna | Tipo | Validación |
|---------|------|------------|
| nombre | String | Requerido, no vacío |
| apellido | String | Requerido, no vacío |
| edad | Integer | 0-150 |
| correo | String | Formato email válido, único |
| tipo_sangre | String | A+, A-, B+, B-, AB+, AB-, O+, O- |

### Ejemplo de Archivo

```
nombre,apellido,edad,correo,tipo_sangre
Juan,Pérez,30,juan.perez@email.com,O+
María,González,25,maria.gonzalez@email.com,A+
Carlos,Rodríguez,35,carlos.rodriguez@email.com,B+
```

## 🔧 Configuración

### Variables de Entorno Backend

Copiar `.env.example` a `.env` en el directorio `backend/`:

```bash
# Database
DATABASE_URL=mysql+pymysql://user:password@mysql:3306/xlsx_db

# Redis
REDIS_URL=redis://redis:6379/0

# Celery
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_TASK_TIME_LIMIT=3600

# Upload
MAX_UPLOAD_SIZE=10485760
ASYNC_THRESHOLD=200
```

### Variables de Entorno Frontend

Editar `frontend/src/environments/environment.ts`:

```typescript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8000/api',
  wsUrl: 'ws://localhost:8000/api/ws'
};
```

## 📊 Flujo de Trabajo

### 1. Carga de Archivo
```mermaid
graph LR
    A[Usuario selecciona archivo] --> B[Frontend valida extensión y tamaño]
    B --> C[Backend valida estructura]
    C --> D{Estructura válida?}
    D -->|Sí| E[Muestra tabla editable]
    D -->|No| F[Error de estructura]
    E --> G[Usuario selecciona registros]
    G --> H{Más de 200 registros?}
    H -->|Sí| I[Carga asíncrona con Celery]
    H -->|No| J[Carga síncrona]
    I --> K[WebSocket notifica progreso]
    J --> L[Respuesta inmediata]
    K --> M[Completado]
    L --> M
```

### 2. Detección de Duplicados
- Se verifica el correo electrónico
- Los duplicados se omiten automáticamente
- Se notifica al usuario con detalles
- Se registra en el historial

### 3. Notificaciones en Tiempo Real
- Inicio de carga
- Progreso (% completado)
- Duplicados detectados
- Finalización exitosa
- Errores específicos

## 📈 Estadísticas y Visualización

El sistema genera automáticamente:

- **Total de personas registradas**
- **Distribución por tipo de sangre** (gráfico de barras)
- **Distribución por rango de edad** (gráfico de barras)
- **Edad promedio**
- **Historial completo de cargas**

## 🔄 API Endpoints

### Upload
- `POST /api/upload/validate` - Validar archivo XLSX
- `POST /api/upload/process` - Procesar y cargar datos

### Personas
- `GET /api/personas` - Listar personas (paginado)
- `GET /api/personas/{id}` - Obtener persona
- `POST /api/personas` - Crear persona
- `PUT /api/personas/{id}` - Actualizar persona
- `DELETE /api/personas/{id}` - Eliminar persona
- `GET /api/personas/estadisticas/resumen` - Estadísticas

### Historial
- `GET /api/historial` - Historial de cargas (paginado)
- `GET /api/historial/{id}` - Detalle de carga

### Tasks
- `GET /api/tasks/{task_id}/status` - Estado de tarea Celery

### WebSocket
- `WS /api/ws` - Conexión para notificaciones

## 🧪 Testing

### Backend
```bash
cd backend
pytest
pytest --cov=app tests/
```

### Frontend
```bash
cd frontend
npm test
npm run test:coverage
```

## 📦 Comandos Útiles

```bash
# Iniciar servicios
docker-compose up -d

# Detener servicios
docker-compose down

# Ver logs
docker-compose logs -f [servicio]

# Reiniciar un servicio
docker-compose restart [servicio]

# Reconstruir imágenes
docker-compose build

# Limpiar volúmenes
docker-compose down -v

# Ejecutar migraciones
docker-compose exec backend alembic upgrade head

# Acceder a la base de datos
docker-compose exec mysql mysql -u user -ppassword xlsx_db

# Acceder a Redis CLI
docker-compose exec redis redis-cli
```

## 🐛 Troubleshooting

### El backend no inicia
```bash
# Verificar logs
docker-compose logs backend

# Verificar que MySQL esté listo
docker-compose logs mysql

# Reiniciar
docker-compose restart backend
```

### Celery no procesa tareas
```bash
# Verificar worker
docker-compose logs celery_worker

# Verificar Redis
docker-compose exec redis redis-cli ping

# Reiniciar worker
docker-compose restart celery_worker
```

### Frontend no conecta al backend
- Verificar que el backend esté corriendo
- Revisar CORS en `backend/.env`
- Verificar `apiUrl` en `frontend/src/environments/environment.ts`

## 📚 Documentación Adicional

- [Backend README](backend/README.md)
- [Frontend README](frontend/README.md)
- [API Documentation](http://localhost:8000/docs)

## 🔐 Seguridad

- Cambiar credenciales en producción
- Configurar CORS apropiadamente
- Usar HTTPS en producción
- Implementar autenticación si es necesario
- Validar y sanitizar todas las entradas

## 🚀 Deployment a Producción

1. Actualizar variables de entorno
2. Cambiar credenciales de BD
3. Configurar HTTPS
4. Usar `docker-compose.prod.yml`
5. Configurar backup de base de datos
6. Implementar monitoreo

## 📊 Métricas de Rendimiento

- Carga síncrona: <200 registros → ~2-5 segundos
- Carga asíncrona: >200 registros → Background con progreso
- Tiempo máximo de tarea Celery: 1 hora
- Tamaño máximo de archivo: 10MB

## 🤝 Contribución

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crear feature branch
3. Commit cambios
4. Push al branch
5. Abrir Pull Request

## 📄 Licencia

Este proyecto está bajo licencia MIT.

## 👨‍💻 Desarrollo

**Stack Tecnológico:**
- Backend: FastAPI, SQLAlchemy, Celery, Redis
- Frontend: Angular 16, Chart.js, SASS
- Base de Datos: MySQL
- Containerización: Docker, Docker Compose

---

**¿Preguntas?** Abre un issue en el repositorio.