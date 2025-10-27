#!/bin/bash

echo "================================================"
echo "  Agregando Funcionalidades Completas"
echo "================================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

# ==================== BACKEND - Modelos Completos ====================

print_info "Agregando modelo de Historial..."
cat << 'PYEOF' > backend/app/models/historial.py
from sqlalchemy import Column, Integer, String, DateTime, Boolean, JSON
from sqlalchemy.sql import func
from app.core.database import Base


class HistorialCarga(Base):
    __tablename__ = "historial_cargas"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nombre_archivo = Column(String(255), nullable=False)
    total_registros = Column(Integer, nullable=False, default=0)
    registros_exitosos = Column(Integer, nullable=False, default=0)
    registros_duplicados = Column(Integer, nullable=False, default=0)
    registros_error = Column(Integer, nullable=False, default=0)
    fue_asincrono = Column(Boolean, default=False)
    task_id = Column(String(255), nullable=True)
    estado = Column(String(50), nullable=False)
    detalles_duplicados = Column(JSON, nullable=True)
    detalles_errores = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)
PYEOF

# ==================== BACKEND - Schemas Completos ====================

print_info "Creando schemas de respuesta..."
cat << 'PYEOF' > backend/app/schemas/response.py
from pydantic import BaseModel
from typing import Any, Optional, List
from enum import Enum


class ResponseType(str, Enum):
    SUCCESS = "success"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"


class ApiResponse(BaseModel):
    estado: bool
    tipo: ResponseType
    titulo: str
    mensaje: str
    datos: Optional[Any] = None
    errores: Optional[List[str]] = None


def success_response(titulo: str, mensaje: str, datos: Any = None) -> ApiResponse:
    return ApiResponse(
        estado=True,
        tipo=ResponseType.SUCCESS,
        titulo=titulo,
        mensaje=mensaje,
        datos=datos
    )


def error_response(titulo: str, mensaje: str, errores: List[str] = None) -> ApiResponse:
    return ApiResponse(
        estado=False,
        tipo=ResponseType.ERROR,
        titulo=titulo,
        mensaje=mensaje,
        errores=errores
    )
PYEOF

print_info "Creando schemas de persona..."
cat << 'PYEOF' > backend/app/schemas/persona.py
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from app.models.persona import TipoSangre


class PersonaBase(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    apellido: str = Field(..., min_length=1, max_length=100)
    edad: int = Field(..., ge=0, le=150)
    correo: EmailStr
    tipo_sangre: TipoSangre


class PersonaCreate(PersonaBase):
    pass


class PersonaResponse(PersonaBase):
    id: int
    created_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True
PYEOF

# ==================== BACKEND - Servicios ====================

print_info "Creando servicio de personas..."
cat << 'PYEOF' > backend/app/services/persona_service.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models.persona import Persona
from app.schemas.persona import PersonaCreate
from typing import List, Dict, Tuple, Optional


class PersonaService:
    
    @staticmethod
    async def create(db: AsyncSession, persona_data: PersonaCreate) -> Persona:
        persona = Persona(**persona_data.model_dump())
        db.add(persona)
        await db.commit()
        await db.refresh(persona)
        return persona
    
    @staticmethod
    async def get_by_email(db: AsyncSession, correo: str) -> Optional[Persona]:
        result = await db.execute(
            select(Persona).where(Persona.correo == correo.lower())
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def get_all(db: AsyncSession, skip: int = 0, limit: int = 100) -> List[Persona]:
        result = await db.execute(
            select(Persona)
            .offset(skip)
            .limit(limit)
            .order_by(Persona.created_at.desc())
        )
        return result.scalars().all()
    
    @staticmethod
    async def bulk_create(db: AsyncSession, personas_data: List[PersonaCreate]) -> Tuple[List[Persona], List[Dict]]:
        personas_creadas = []
        duplicados = []
        
        for idx, persona_data in enumerate(personas_data):
            existing = await PersonaService.get_by_email(db, persona_data.correo)
            
            if existing:
                duplicados.append({
                    "indice": idx,
                    "correo": persona_data.correo,
                    "nombre_completo": f"{persona_data.nombre} {persona_data.apellido}",
                    "mensaje": "Correo ya registrado en la base de datos"
                })
            else:
                persona = Persona(**persona_data.model_dump())
                db.add(persona)
                personas_creadas.append(persona)
        
        if personas_creadas:
            await db.commit()
            for persona in personas_creadas:
                await db.refresh(persona)
        
        return personas_creadas, duplicados
    
    @staticmethod
    async def get_statistics(db: AsyncSession) -> Dict:
        total_result = await db.execute(select(func.count(Persona.id)))
        total = total_result.scalar()
        
        tipo_sangre_result = await db.execute(
            select(Persona.tipo_sangre, func.count(Persona.id))
            .group_by(Persona.tipo_sangre)
        )
        distribucion_sangre = {
            str(tipo): count for tipo, count in tipo_sangre_result.all()
        }
        
        edad_promedio_result = await db.execute(select(func.avg(Persona.edad)))
        edad_promedio = edad_promedio_result.scalar() or 0
        
        return {
            "total_personas": total,
            "distribucion_tipo_sangre": distribucion_sangre,
            "edad_promedio": round(edad_promedio, 2)
        }
PYEOF

# ==================== BACKEND - Router de Personas Completo ====================

print_info "Actualizando router de personas..."
cat << 'PYEOF' > backend/app/routers/personas.py
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.schemas.response import ApiResponse, success_response, error_response
from app.schemas.persona import PersonaResponse
from app.services.persona_service import PersonaService
from typing import List

router = APIRouter(prefix="/personas", tags=["Personas"])


@router.get("", response_model=ApiResponse)
async def get_personas(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: AsyncSession = Depends(get_db)
):
    try:
        personas = await PersonaService.get_all(db, skip=skip, limit=limit)
        personas_response = [PersonaResponse.model_validate(p) for p in personas]
        
        return success_response(
            titulo="Personas Obtenidas",
            mensaje=f"Se encontraron {len(personas_response)} personas",
            datos={
                "personas": [p.model_dump() for p in personas_response],
                "total": len(personas_response)
            }
        )
    except Exception as e:
        return error_response(
            titulo="Error",
            mensaje="Error al obtener personas",
            errores=[str(e)]
        )


@router.get("/estadisticas/resumen", response_model=ApiResponse)
async def get_statistics(db: AsyncSession = Depends(get_db)):
    try:
        stats = await PersonaService.get_statistics(db)
        return success_response(
            titulo="Estadísticas Obtenidas",
            mensaje="Estadísticas calculadas correctamente",
            datos=stats
        )
    except Exception as e:
        return error_response(
            titulo="Error",
            mensaje="Error al obtener estadísticas",
            errores=[str(e)]
        )
PYEOF

# ==================== BACKEND - Router de Upload Mejorado ====================

print_info "Actualizando router de upload..."
cat << 'PYEOF' > backend/app/routers/upload.py
from fastapi import APIRouter, UploadFile, File, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.schemas.response import ApiResponse, success_response, error_response
from app.schemas.persona import PersonaCreate
from app.services.persona_service import PersonaService
from typing import List

router = APIRouter(prefix="/upload", tags=["Upload"])


@router.post("/validate")
async def validate_file(file: UploadFile = File(...)):
    if not file.filename.endswith(('.xlsx', '.xls')):
        return error_response(
            titulo="Archivo Inválido",
            mensaje="Solo se permiten archivos Excel (.xlsx, .xls)",
            errores=["Extensión no válida"]
        )
    
    return success_response(
        titulo="Validación Exitosa",
        mensaje="Archivo validado correctamente (validación completa pendiente)",
        datos={"filename": file.filename}
    )


@router.post("/process")
async def process_file(
    personas: List[PersonaCreate],
    db: AsyncSession = Depends(get_db)
):
    try:
        personas_creadas, duplicados = await PersonaService.bulk_create(db, personas)
        
        if duplicados:
            return success_response(
                titulo="Carga Completada con Duplicados",
                mensaje=f"Se cargaron {len(personas_creadas)} registros. {len(duplicados)} duplicados omitidos",
                datos={
                    "registros_exitosos": len(personas_creadas),
                    "registros_duplicados": len(duplicados),
                    "detalles_duplicados": duplicados
                }
            )
        
        return success_response(
            titulo="Carga Exitosa",
            mensaje=f"Se cargaron {len(personas_creadas)} registros correctamente",
            datos={
                "registros_exitosos": len(personas_creadas),
                "registros_duplicados": 0
            }
        )
    except Exception as e:
        return error_response(
            titulo="Error en Carga",
            mensaje="Error al procesar datos",
            errores=[str(e)]
        )
PYEOF

print_success "Backend actualizado con funcionalidades"

# ==================== FRONTEND - Servicios ====================

print_info "Creando servicio API en frontend..."
mkdir -p frontend/src/app/services

cat << 'TSEOF' > frontend/src/app/services/api.service.ts
import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface ApiResponse<T = any> {
  estado: boolean;
  tipo: string;
  titulo: string;
  mensaje: string;
  datos?: T;
  errores?: string[];
}

export interface Persona {
  id?: number;
  nombre: string;
  apellido: string;
  edad: number;
  correo: string;
  tipo_sangre: string;
}

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private apiUrl = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getPersonas(skip: number = 0, limit: number = 100): Observable<ApiResponse> {
    const params = new HttpParams()
      .set('skip', skip.toString())
      .set('limit', limit.toString());
    return this.http.get<ApiResponse>(`${this.apiUrl}/personas`, { params });
  }

  getEstadisticas(): Observable<ApiResponse> {
    return this.http.get<ApiResponse>(`${this.apiUrl}/personas/estadisticas/resumen`);
  }

  uploadFile(file: File): Observable<ApiResponse> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post<ApiResponse>(`${this.apiUrl}/upload/validate`, formData);
  }

  processData(personas: Persona[]): Observable<ApiResponse> {
    return this.http.post<ApiResponse>(`${this.apiUrl}/upload/process`, personas);
  }
}
TSEOF

# ==================== FRONTEND - Componente de Test ====================

print_info "Actualizando componente principal..."
cat << 'TSEOF' > frontend/src/app/app.component.ts
import { Component, OnInit } from '@angular/core';
import { ApiService } from './services/api.service';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  title = 'XLSX Loader';
  personas: any[] = [];
  estadisticas: any = null;
  loading = false;

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.loadData();
  }

  loadData() {
    this.loading = true;
    
    this.apiService.getPersonas().subscribe({
      next: (response) => {
        if (response.estado && response.datos) {
          this.personas = response.datos.personas || [];
        }
        this.loading = false;
      },
      error: (error) => {
        console.error('Error:', error);
        this.loading = false;
      }
    });

    this.apiService.getEstadisticas().subscribe({
      next: (response) => {
        if (response.estado && response.datos) {
          this.estadisticas = response.datos;
        }
      },
      error: (error) => console.error('Error:', error)
    });
  }

  onFileSelected(event: any) {
    const file: File = event.target.files[0];
    if (file) {
      this.apiService.uploadFile(file).subscribe({
        next: (response) => {
          alert(response.mensaje);
        },
        error: (error) => {
          console.error('Error:', error);
          alert('Error al subir archivo');
        }
      });
    }
  }
}
TSEOF

cat << 'HTMLEOF' > frontend/src/app/app.component.html
<div class="app-container">
  <header>
    <h1>{{ title }}</h1>
    <p>Sistema de Carga de Archivos XLSX</p>
  </header>

  <main>
    <section class="upload-section">
      <h2>Cargar Archivo</h2>
      <input type="file" (change)="onFileSelected($event)" accept=".xlsx,.xls">
    </section>

    <section class="stats-section" *ngIf="estadisticas">
      <h2>Estadísticas</h2>
      <div class="stats-grid">
        <div class="stat-card">
          <h3>{{ estadisticas.total_personas }}</h3>
          <p>Total Personas</p>
        </div>
        <div class="stat-card">
          <h3>{{ estadisticas.edad_promedio }}</h3>
          <p>Edad Promedio</p>
        </div>
      </div>
    </section>

    <section class="personas-section">
      <h2>Personas ({{ personas.length }})</h2>
      <div *ngIf="loading">Cargando...</div>
      <table *ngIf="personas.length > 0">
        <thead>
          <tr>
            <th>Nombre</th>
            <th>Apellido</th>
            <th>Edad</th>
            <th>Correo</th>
            <th>Tipo Sangre</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let persona of personas">
            <td>{{ persona.nombre }}</td>
            <td>{{ persona.apellido }}</td>
            <td>{{ persona.edad }}</td>
            <td>{{ persona.correo }}</td>
            <td>{{ persona.tipo_sangre }}</td>
          </tr>
        </tbody>
      </table>
      <p *ngIf="personas.length === 0 && !loading">No hay personas registradas</p>
    </section>
  </main>
</div>
HTMLEOF

cat << 'SCSSEOF' > frontend/src/app/app.component.scss
.app-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;

  header {
    text-align: center;
    margin-bottom: 2rem;
    
    h1 {
      color: #2c3e50;
      margin-bottom: 0.5rem;
    }
    
    p {
      color: #7f8c8d;
    }
  }

  main {
    section {
      background: white;
      padding: 2rem;
      margin-bottom: 2rem;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);

      h2 {
        color: #2c3e50;
        margin-bottom: 1rem;
      }
    }

    .upload-section {
      input[type="file"] {
        padding: 0.5rem;
        border: 2px solid #3498db;
        border-radius: 4px;
        cursor: pointer;
      }
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;

      .stat-card {
        background: #ecf0f1;
        padding: 1.5rem;
        border-radius: 6px;
        text-align: center;

        h3 {
          font-size: 2rem;
          color: #3498db;
          margin: 0;
        }

        p {
          margin: 0.5rem 0 0 0;
          color: #7f8c8d;
        }
      }
    }

    table {
      width: 100%;
      border-collapse: collapse;

      thead {
        background: #34495e;
        color: white;

        th {
          padding: 1rem;
          text-align: left;
        }
      }

      tbody {
        tr {
          border-bottom: 1px solid #ecf0f1;

          &:hover {
            background: #f8f9fa;
          }

          td {
            padding: 0.8rem;
          }
        }
      }
    }
  }
}
SCSSEOF

print_success "Frontend actualizado con funcionalidades"

echo ""
echo "================================================"
print_success "¡Funcionalidades agregadas!"
echo "================================================"
echo ""
echo "Reinicia el backend para aplicar cambios:"
echo "  ${BLUE}docker compose restart backend${NC}"
echo ""
echo "Accede a:"
echo "  Frontend: ${BLUE}http://localhost:4200${NC}"
echo "  API Docs: ${BLUE}http://localhost:8000/docs${NC}"
echo ""