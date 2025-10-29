#!/bin/bash

echo "================================================"
echo "  Agregando Gráficos con Chart.js"
echo "================================================"

# 1. Actualizar el servicio para incluir distribución de edad
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
        # Total de personas
        total_result = await db.execute(select(func.count(Persona.id)))
        total = total_result.scalar()
        
        # Distribución por tipo de sangre
        tipo_sangre_result = await db.execute(
            select(Persona.tipo_sangre, func.count(Persona.id))
            .group_by(Persona.tipo_sangre)
        )
        distribucion_sangre = {
            str(tipo): count for tipo, count in tipo_sangre_result.all()
        }
        
        # Edad promedio
        edad_promedio_result = await db.execute(select(func.avg(Persona.edad)))
        edad_promedio = edad_promedio_result.scalar() or 0
        
        # Distribución por rangos de edad
        personas = await PersonaService.get_all(db, limit=10000)
        edad_rangos = {
            "0-18": 0,
            "19-30": 0,
            "31-45": 0,
            "46-60": 0,
            "61+": 0
        }
        
        for persona in personas:
            if persona.edad <= 18:
                edad_rangos["0-18"] += 1
            elif persona.edad <= 30:
                edad_rangos["19-30"] += 1
            elif persona.edad <= 45:
                edad_rangos["31-45"] += 1
            elif persona.edad <= 60:
                edad_rangos["46-60"] += 1
            else:
                edad_rangos["61+"] += 1
        
        return {
            "total_personas": total,
            "distribucion_tipo_sangre": distribucion_sangre,
            "edad_promedio": round(edad_promedio, 2),
            "distribucion_edad": edad_rangos
        }
PYEOF

# 2. Actualizar el componente con gráficos
cat << 'TSEOF' > frontend/src/app/app.component.ts
import { Component, OnInit, ViewChild } from '@angular/core';
import { ApiService } from './services/api.service';
import { Chart, ChartConfiguration, ChartType, registerables } from 'chart.js';

Chart.register(...registerables);

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
  uploading = false;

  // Gráficos
  bloodTypeChart: Chart | null = null;
  ageChart: Chart | null = null;

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
          this.createCharts();
        }
      },
      error: (error) => console.error('Error:', error)
    });
  }

  createCharts() {
    if (!this.estadisticas) return;

    // Destruir gráficos anteriores si existen
    if (this.bloodTypeChart) {
      this.bloodTypeChart.destroy();
    }
    if (this.ageChart) {
      this.ageChart.destroy();
    }

    // Gráfico de Tipos de Sangre
    const bloodCanvas = document.getElementById('bloodTypeChart') as HTMLCanvasElement;
    if (bloodCanvas) {
      const bloodTypes = Object.keys(this.estadisticas.distribucion_tipo_sangre);
      const bloodCounts = Object.values(this.estadisticas.distribucion_tipo_sangre);

      this.bloodTypeChart = new Chart(bloodCanvas, {
        type: 'bar',
        data: {
          labels: bloodTypes,
          datasets: [{
            label: 'Cantidad de Personas',
            data: bloodCounts as number[],
            backgroundColor: [
              'rgba(255, 99, 132, 0.7)',
              'rgba(54, 162, 235, 0.7)',
              'rgba(255, 206, 86, 0.7)',
              'rgba(75, 192, 192, 0.7)',
              'rgba(153, 102, 255, 0.7)',
              'rgba(255, 159, 64, 0.7)',
              'rgba(199, 199, 199, 0.7)',
              'rgba(83, 102, 255, 0.7)'
            ],
            borderColor: [
              'rgba(255, 99, 132, 1)',
              'rgba(54, 162, 235, 1)',
              'rgba(255, 206, 86, 1)',
              'rgba(75, 192, 192, 1)',
              'rgba(153, 102, 255, 1)',
              'rgba(255, 159, 64, 1)',
              'rgba(199, 199, 199, 1)',
              'rgba(83, 102, 255, 1)'
            ],
            borderWidth: 2
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: false
            },
            title: {
              display: true,
              text: 'Distribución por Tipo de Sangre',
              font: {
                size: 16,
                weight: 'bold'
              }
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              ticks: {
                stepSize: 1
              }
            }
          }
        }
      });
    }

    // Gráfico de Rangos de Edad
    const ageCanvas = document.getElementById('ageChart') as HTMLCanvasElement;
    if (ageCanvas && this.estadisticas.distribucion_edad) {
      const ageRanges = Object.keys(this.estadisticas.distribucion_edad);
      const ageCounts = Object.values(this.estadisticas.distribucion_edad);

      this.ageChart = new Chart(ageCanvas, {
        type: 'bar',
        data: {
          labels: ageRanges,
          datasets: [{
            label: 'Cantidad de Personas',
            data: ageCounts as number[],
            backgroundColor: 'rgba(52, 152, 219, 0.7)',
            borderColor: 'rgba(52, 152, 219, 1)',
            borderWidth: 2
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: false
            },
            title: {
              display: true,
              text: 'Distribución por Rango de Edad',
              font: {
                size: 16,
                weight: 'bold'
              }
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              ticks: {
                stepSize: 1
              }
            }
          }
        }
      });
    }
  }

  onFileSelected(event: any) {
    const file: File = event.target.files[0];
    if (!file) return;

    if (!file.name.endsWith('.xlsx') && !file.name.endsWith('.xls')) {
      alert('Solo se permiten archivos Excel (.xlsx, .xls)');
      return;
    }

    this.uploading = true;
    
    const formData = new FormData();
    formData.append('file', file);

    this.apiService.uploadAndProcess(formData).subscribe({
      next: (response) => {
        this.uploading = false;
        
        if (response.estado) {
          let mensaje = `✓ ${response.titulo}\n${response.mensaje}`;
          
          if (response.datos?.detalles_duplicados) {
            const dups = response.datos.detalles_duplicados;
            mensaje += `\n\nDuplicados omitidos:\n${dups.map((d: any) => `- ${d.correo}`).join('\n')}`;
          }
          
          alert(mensaje);
          this.loadData();
          event.target.value = '';
        } else {
          alert(`✗ ${response.titulo}\n${response.mensaje}\n${response.errores?.join('\n')}`);
        }
      },
      error: (error) => {
        this.uploading = false;
        console.error('Error:', error);
        alert('Error al cargar el archivo: ' + (error.error?.mensaje || error.message));
      }
    });
  }
}
TSEOF

# 3. Actualizar el HTML con los canvas para los gráficos
cat << 'HTMLEOF' > frontend/src/app/app.component.html
<div class="app-container">
  <header>
    <h1>{{ title }}</h1>
    <p>Sistema de Carga de Archivos XLSX</p>
  </header>

  <main>
    <section class="upload-section">
      <h2>Cargar Archivo</h2>
      <div class="upload-wrapper">
        <input type="file" (change)="onFileSelected($event)" accept=".xlsx,.xls" [disabled]="uploading">
        <span *ngIf="uploading" class="loading">⏳ Procesando archivo...</span>
      </div>
      <div class="info-box">
        <p><strong>Columnas requeridas:</strong></p>
        <ul>
          <li>nombre</li>
          <li>apellido</li>
          <li>edad</li>
          <li>correo</li>
          <li>tipo_sangre (A+, A-, B+, B-, AB+, AB-, O+, O-)</li>
        </ul>
      </div>
    </section>

    <section class="stats-section" *ngIf="estadisticas">
      <h2>Estadísticas Generales</h2>
      <div class="stats-grid">
        <div class="stat-card card-1">
          <div class="stat-icon">👥</div>
          <h3>{{ estadisticas.total_personas }}</h3>
          <p>Total Personas</p>
        </div>
        <div class="stat-card card-2">
          <div class="stat-icon">📊</div>
          <h3>{{ estadisticas.edad_promedio }}</h3>
          <p>Edad Promedio</p>
        </div>
        <div class="stat-card card-3">
          <div class="stat-icon">🩸</div>
          <h3>{{ Object.keys(estadisticas.distribucion_tipo_sangre || {}).length }}</h3>
          <p>Tipos de Sangre</p>
        </div>
      </div>
    </section>

    <section class="charts-section" *ngIf="estadisticas">
      <h2>Gráficos Estadísticos</h2>
      <div class="charts-grid">
        <div class="chart-container">
          <canvas id="bloodTypeChart"></canvas>
        </div>
        <div class="chart-container">
          <canvas id="ageChart"></canvas>
        </div>
      </div>
    </section>

    <section class="personas-section">
      <h2>Personas Registradas ({{ personas.length }})</h2>
      <button *ngIf="!loading" (click)="loadData()" class="refresh-btn">🔄 Actualizar</button>
      <div *ngIf="loading" class="loading">⏳ Cargando...</div>
      <div class="table-wrapper" *ngIf="!loading">
        <table *ngIf="personas.length > 0">
          <thead>
            <tr>
              <th>ID</th>
              <th>Nombre</th>
              <th>Apellido</th>
              <th>Edad</th>
              <th>Correo</th>
              <th>Tipo Sangre</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let persona of personas">
              <td>{{ persona.id }}</td>
              <td>{{ persona.nombre }}</td>
              <td>{{ persona.apellido }}</td>
              <td>{{ persona.edad }}</td>
              <td>{{ persona.correo }}</td>
              <td><span class="blood-badge">{{ persona.tipo_sangre }}</span></td>
            </tr>
          </tbody>
        </table>
        <p *ngIf="personas.length === 0" class="empty-message">
          📋 No hay personas registradas. Carga un archivo Excel para comenzar.
        </p>
      </div>
    </section>
  </main>
</div>
HTMLEOF

# 4. Actualizar estilos para los gráficos
cat << 'SCSSEOF' > frontend/src/app/app.component.scss
.app-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 2rem;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: #f5f7fa;

  header {
    text-align: center;
    margin-bottom: 3rem;
    
    h1 {
      color: #2c3e50;
      margin-bottom: 0.5rem;
      font-size: 2.5rem;
      font-weight: 700;
    }
    
    p {
      color: #7f8c8d;
      font-size: 1.1rem;
    }
  }

  main {
    section {
      background: white;
      padding: 2rem;
      margin-bottom: 2rem;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);

      h2 {
        color: #2c3e50;
        margin-bottom: 1.5rem;
        font-size: 1.5rem;
        font-weight: 600;
      }
    }

    .upload-section {
      .upload-wrapper {
        margin-bottom: 1.5rem;

        input[type="file"] {
          padding: 1rem;
          border: 2px dashed #3498db;
          border-radius: 8px;
          cursor: pointer;
          background: #ecf8ff;
          width: 100%;
          transition: all 0.3s;
          
          &:hover {
            border-color: #2980b9;
            background: #d6f1ff;
          }
          
          &:disabled {
            opacity: 0.5;
            cursor: not-allowed;
          }
        }

        .loading {
          display: inline-block;
          margin-top: 1rem;
          color: #3498db;
          font-weight: 600;
        }
      }

      .info-box {
        background: #e8f4f8;
        padding: 1.5rem;
        border-radius: 8px;
        border-left: 4px solid #3498db;

        p {
          margin: 0 0 0.8rem 0;
          color: #2c3e50;
          font-weight: 600;
        }

        ul {
          margin: 0;
          padding-left: 1.5rem;

          li {
            color: #34495e;
            padding: 0.3rem 0;
          }
        }
      }
    }

    .stats-section {
      .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 1.5rem;

        .stat-card {
          padding: 2rem;
          border-radius: 12px;
          text-align: center;
          color: white;
          box-shadow: 0 4px 12px rgba(0,0,0,0.15);
          transition: transform 0.3s;

          &:hover {
            transform: translateY(-5px);
          }

          .stat-icon {
            font-size: 3rem;
            margin-bottom: 1rem;
          }

          h3 {
            font-size: 2.8rem;
            margin: 0;
            font-weight: 700;
          }

          p {
            margin: 0.8rem 0 0 0;
            font-size: 1.1rem;
            opacity: 0.95;
          }

          &.card-1 {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          }

          &.card-2 {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
          }

          &.card-3 {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
          }
        }
      }
    }

    .charts-section {
      .charts-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(450px, 1fr));
        gap: 2rem;

        .chart-container {
          background: #f8f9fa;
          padding: 1.5rem;
          border-radius: 8px;
          height: 400px;
          box-shadow: 0 2px 6px rgba(0,0,0,0.05);

          canvas {
            max-height: 100%;
          }
        }
      }
    }

    .personas-section {
      .refresh-btn {
        background: #3498db;
        color: white;
        border: none;
        padding: 0.8rem 1.5rem;
        border-radius: 8px;
        cursor: pointer;
        font-size: 1rem;
        margin-bottom: 1.5rem;
        font-weight: 600;
        transition: all 0.3s;

        &:hover {
          background: #2980b9;
          transform: translateY(-2px);
          box-shadow: 0 4px 8px rgba(52, 152, 219, 0.3);
        }
      }

      .loading {
        text-align: center;
        padding: 2rem;
        color: #7f8c8d;
        font-size: 1.1rem;
      }

      .table-wrapper {
        overflow-x: auto;
        border-radius: 8px;
        border: 1px solid #ecf0f1;

        table {
          width: 100%;
          border-collapse: collapse;

          thead {
            background: #34495e;
            color: white;

            th {
              padding: 1.2rem;
              text-align: left;
              font-weight: 600;
              font-size: 0.95rem;
              text-transform: uppercase;
              letter-spacing: 0.5px;
            }
          }

          tbody {
            tr {
              border-bottom: 1px solid #ecf0f1;
              transition: background 0.2s;

              &:hover {
                background: #f8f9fa;
              }

              &:last-child {
                border-bottom: none;
              }

              td {
                padding: 1rem 1.2rem;

                .blood-badge {
                  background: #e74c3c;
                  color: white;
                  padding: 0.4rem 1rem;
                  border-radius: 16px;
                  font-weight: 700;
                  font-size: 0.9rem;
                  display: inline-block;
                }
              }
            }
          }
        }

        .empty-message {
          text-align: center;
          padding: 3rem;
          color: #7f8c8d;
          font-size: 1.2rem;
        }
      }
    }
  }
}

@media (max-width: 768px) {
  .app-container {
    padding: 1rem;

    main {
      .charts-section .charts-grid {
        grid-template-columns: 1fr;
      }

      .stats-section .stats-grid {
        grid-template-columns: 1fr;
      }
    }
  }
}
SCSSEOF

echo "✓ Gráficos agregados. Reiniciando servicios..."

docker compose restart backend frontend

echo ""
echo "================================================"
echo "✓ ¡Gráficos implementados!"
echo "================================================"
echo ""
echo "Espera 30 segundos y recarga:"
echo "  http://localhost:4200"
echo ""
echo "Verás 2 gráficos:"
echo "  1. Distribución por Tipo de Sangre (barras multicolor)"
echo "  2. Distribución por Rango de Edad (barras azules)"
echo ""

