# XLSX Loader - Frontend

Frontend desarrollado con Angular 16 para la gestión y carga de archivos XLSX.

## 🚀 Características

- **Angular 16** - Framework moderno y robusto
- **Chart.js** - Visualización de datos con gráficos interactivos
- **WebSocket** - Notificaciones en tiempo real
- **SASS** - Estilos modulares y mantenibles
- **Responsive Design** - Compatible con dispositivos móviles

## 📋 Requisitos

- Node.js 18+
- npm o yarn
- Docker (opcional)

## 🛠️ Instalación

### Con Docker (Recomendado)

```bash
# Desde el directorio raíz del proyecto
docker-compose up -d frontend
```

### Sin Docker (Desarrollo Local)

```bash
# Navegar al directorio frontend
cd frontend

# Instalar dependencias
npm install

# Iniciar servidor de desarrollo
npm start
```

La aplicación estará disponible en: http://localhost:4200

## 📁 Estructura del Proyecto

```
frontend/
├── src/
│   ├── app/
│   │   ├── components/
│   │   │   ├── upload/              # Componente de carga
│   │   │   ├── personas-list/       # Lista y estadísticas
│   │   │   ├── historial/           # Historial de cargas
│   │   │   └── notification/        # Sistema de notificaciones
│   │   ├── models/
│   │   │   └── models.ts            # Interfaces y tipos
│   │   ├── services/
│   │   │   ├── api.service.ts       # Servicio API
│   │   │   ├── websocket.service.ts # Cliente WebSocket
│   │   │   └── notification.service.ts # Notificaciones
│   │   ├── app.component.ts
│   │   ├── app.module.ts
│   │   └── app-routing.module.ts
│   ├── environments/
│   │   ├── environment.ts           # Desarrollo
│   │   └── environment.prod.ts      # Producción
│   ├── assets/
│   ├── styles.scss                  # Estilos globales
│   └── index.html
├── angular.json
├── package.json
├── tsconfig.json
└── Dockerfile
```

## 🎯 Funcionalidades

### 1. Carga de Archivos
- Validación de archivos XLSX
- Previsualización de datos
- Edición de registros
- Selección de registros a cargar

### 2. Gestión de Personas
- Lista completa de personas
- Búsqueda y filtros
- Estadísticas visuales con Chart.js
- Gráficos de distribución

### 3. Historial
- Registro de todas las cargas
- Detalles de duplicados y errores
- Estado de tareas asíncronas
- Métricas de rendimiento

### 4. Notificaciones
- Notificaciones en tiempo real vía WebSocket
- Alertas de progreso
- Notificaciones de duplicados y errores

## 🔧 Configuración

### Variables de Entorno

Editar `src/environments/environment.ts`:

```typescript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8000/api',
  wsUrl: 'ws://localhost:8000/api/ws',
  maxFileSize: 10485760, // 10MB
  allowedExtensions: ['.xlsx', '.xls'],
  asyncThreshold: 200
};
```

## 📊 Gráficos

Los gráficos implementados incluyen:

- **Distribución por Tipo de Sangre**: Gráfico de barras
- **Distribución por Rango de Edad**: Gráfico de barras
- Colores diferenciados para mejor visualización
- Interactividad con hover

## 🌐 API Endpoints Consumidos

- `POST /api/upload/validate` - Validar archivo
- `POST /api/upload/process` - Procesar carga
- `GET /api/personas` - Listar personas
- `GET /api/personas/estadisticas/resumen` - Estadísticas
- `GET /api/historial` - Historial de cargas
- `GET /api/tasks/{task_id}/status` - Estado de tarea
- `WS /api/ws` - WebSocket para notificaciones

## 🎨 Estilos

El proyecto utiliza SASS con:
- Variables globales
- Mixins reutilizables
- Diseño responsive
- Animaciones suaves
- Paleta de colores consistente

### Paleta de Colores

```scss
$primary: #3498db    // Azul
$success: #27ae60    // Verde
$warning: #f39c12    // Naranja
$danger: #e74c3c     // Rojo
$dark: #2c3e50       // Gris oscuro
$light: #ecf0f1      // Gris claro
```

## 🔄 WebSocket

La aplicación se conecta automáticamente al WebSocket del backend para recibir:

- Inicio de carga
- Progreso de procesamiento
- Finalización exitosa
- Errores
- Duplicados detectados

## 🧪 Testing

```bash
# Ejecutar tests
npm test

# Ejecutar tests con coverage
npm run test:coverage
```

## 📦 Build

```bash
# Build para producción
npm run build

# Build con optimizaciones
ng build --configuration production
```

Los archivos compilados estarán en `dist/xlsx-loader-frontend/`

## 🚀 Deployment

### Docker
```bash
docker build -t xlsx-frontend .
docker run -p 4200:4200 xlsx-frontend
```

### Nginx (Producción)
```bash
ng build --configuration production
# Copiar archivos de dist/ a servidor Nginx
```

## 🐛 Troubleshooting

### Error de conexión al backend
- Verificar que el backend esté corriendo en `http://localhost:8000`
- Revisar configuración de CORS en el backend
- Verificar `apiUrl` en `environment.ts`

### WebSocket no conecta
- Verificar `wsUrl` en `environment.ts`
- Verificar que el backend tenga el endpoint WebSocket activo
- Revisar consola del navegador para errores

### Gráficos no se muestran
- Verificar que `ng2-charts` esté instalado correctamente
- Revisar que los datos de estadísticas estén llegando
- Verificar importación de `NgChartsModule` en `app.module.ts`

## 📚 Recursos

- [Angular Documentation](https://angular.io/docs)
- [Chart.js Documentation](https://www.chartjs.org/docs/)
- [SASS Documentation](https://sass-lang.com/documentation)

## 🤝 Contribución

1. Fork el proyecto
2. Crear feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

## 📄 Licencia

Este proyecto está bajo licencia MIT.

## 👥 Equipo

Desarrollado para el sistema de carga y gestión de archivos XLSX.

---

**Nota**: Asegúrate de que el backend esté corriendo antes de iniciar el frontend.