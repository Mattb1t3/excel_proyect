#!/bin/bash

echo "================================================"
echo "  Sistema de Carga de Archivos XLSX"
echo "  Inicialización del Proyecto"
echo "================================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Verificar Docker
print_info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado. Por favor instala Docker primero."
    exit 1
fi
print_success "Docker encontrado"

# Verificar Docker Compose
print_info "Verificando Docker Compose..."
if ! docker compose version &> /dev/null 2>&1; then
    print_error "Docker Compose no está instalado. Por favor instala Docker Compose primero."
    exit 1
fi
print_success "Docker Compose encontrado"

# Crear archivos .env si no existen
print_info "Configurando archivos de entorno..."

if [ ! -f "backend/.env" ]; then
    print_warning "Creando backend/.env desde .env.example"
    cp backend/.env.example backend/.env
    print_success "backend/.env creado"
else
    print_success "backend/.env ya existe"
fi

# Crear directorios necesarios
print_info "Creando directorios necesarios..."
mkdir -p backend/temp_uploads
mkdir -p backend/alembic/versions
print_success "Directorios creados"

# Detener servicios existentes
print_info "Deteniendo servicios existentes (si existen)..."
docker compose down 2>/dev/null

# Construir imágenes
print_info "Construyendo imágenes Docker..."
docker compose build

if [ $? -eq 0 ]; then
    print_success "Imágenes construidas exitosamente"
else
    print_error "Error al construir imágenes"
    exit 1
fi

# Iniciar servicios
print_info "Iniciando servicios..."
docker compose up -d

if [ $? -eq 0 ]; then
    print_success "Servicios iniciados"
else
    print_error "Error al iniciar servicios"
    exit 1
fi

# Esperar a que los servicios estén listos
print_info "Esperando a que los servicios estén listos..."
sleep 10

# Verificar MySQL
print_info "Esperando a MySQL..."
for i in {1..30}; do
    if docker compose exec -T mysql mysqladmin ping -h localhost -u root -prootpassword &> /dev/null; then
        print_success "MySQL listo"
        break
    fi
    echo -n "."
    sleep 2
done

# Ejecutar migraciones
print_info "Ejecutando migraciones de base de datos..."
docker compose exec -T backend alembic upgrade head

if [ $? -eq 0 ]; then
    print_success "Migraciones ejecutadas"
else
    print_warning "Error en migraciones (puede ser normal si es la primera vez)"
fi

# Mostrar estado de servicios
echo ""
print_info "Estado de los servicios:"
docker compose ps

# Información final
echo ""
echo "================================================"
print_success "¡Inicialización completada!"
echo "================================================"
echo ""
echo "Accede a los servicios en:"
echo ""
echo "  🌐 Frontend:       ${BLUE}http://localhost:4200${NC}"
echo "  🔧 Backend API:    ${BLUE}http://localhost:8000${NC}"
echo "  📚 API Docs:       ${BLUE}http://localhost:8000/docs${NC}"
echo "  🌺 Flower:         ${BLUE}http://localhost:5555${NC}"
echo ""
echo "Base de datos:"
echo "  📊 MySQL:          ${BLUE}localhost:3306${NC}"
echo "  🔴 Redis:          ${BLUE}localhost:6379${NC}"
echo ""
echo "Comandos útiles:"
echo "  Ver logs:          ${GREEN}docker compose logs -f${NC}"
echo "  Detener:           ${GREEN}docker compose down${NC}"
echo "  Reiniciar:         ${GREEN}docker compose restart${NC}"
echo ""
echo "================================================"