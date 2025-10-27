import { Component, OnInit, ViewChild } from '@angular/core';
import { ApiService } from '../../services/api.service';
import { NotificationService } from '../../services/notification.service';
import { Persona, Estadisticas } from '../../models/models';
import { ChartConfiguration, ChartType } from 'chart.js';
import { BaseChartDirective } from 'ng2-charts';

@Component({
  selector: 'app-personas-list',
  templateUrl: './personas-list.component.html',
  styleUrls: ['./personas-list.component.scss']
})
export class PersonasListComponent implements OnInit {
  @ViewChild(BaseChartDirective) chart?: BaseChartDirective;

  personas: Persona[] = [];
  estadisticas: Estadisticas | null = null;
  isLoading: boolean = false;
  
  // Paginación
  currentPage: number = 1;
  pageSize: number = 50;
  totalPersonas: number = 0;
  
  // Filtros
  searchTerm: string = '';
  filteredPersonas: Persona[] = [];

  // Gráficos - Tipos de sangre
  public barChartType: ChartType = 'bar';
  public barChartData: ChartConfiguration['data'] | null = null;
  public barChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'top',
      },
      title: {
        display: true,
        text: 'Distribución por Tipo de Sangre'
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
  };

  // Gráficos - Edad
  public ageChartType: ChartType = 'bar';
  public ageChartData: ChartConfiguration['data'] | null = null;
  public ageChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'top',
      },
      title: {
        display: true,
        text: 'Distribución por Rango de Edad'
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
  };

  constructor(
    private apiService: ApiService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadPersonas();
    this.loadEstadisticas();
  }

  loadPersonas(): void {
    this.isLoading = true;
    const skip = (this.currentPage - 1) * this.pageSize;

    this.apiService.getPersonas(skip, this.pageSize).subscribe({
      next: (response) => {
        this.isLoading = false;
        if (response.estado && response.datos) {
          this.personas = response.datos.personas;
          this.filteredPersonas = [...this.personas];
          this.totalPersonas = response.datos.total;
        }
      },
      error: (error) => {
        this.isLoading = false;
        this.notificationService.error(
          'Error',
          'No se pudieron cargar las personas'
        );
        console.error('Error cargando personas:', error);
      }
    });
  }

  loadEstadisticas(): void {
    this.apiService.getEstadisticas().subscribe({
      next: (response) => {
        if (response.estado && response.datos) {
          this.estadisticas = response.datos;
          this.updateCharts();
        }
      },
      error: (error) => {
        console.error('Error cargando estadísticas:', error);
      }
    });
  }

  updateCharts(): void {
    if (!this.estadisticas) return;

    // Gráfico de tipos de sangre
    const tiposSangre = Object.keys(this.estadisticas.distribucion_tipo_sangre);
    const valoresSangre = Object.values(this.estadisticas.distribucion_tipo_sangre);

    this.barChartData = {
      labels: tiposSangre,
      datasets: [
        {
          label: 'Cantidad de Personas',
          data: valoresSangre,
          backgroundColor: [
            'rgba(255, 99, 132, 0.6)',
            'rgba(54, 162, 235, 0.6)',
            'rgba(255, 206, 86, 0.6)',
            'rgba(75, 192, 192, 0.6)',
            'rgba(153, 102, 255, 0.6)',
            'rgba(255, 159, 64, 0.6)',
            'rgba(199, 199, 199, 0.6)',
            'rgba(83, 102, 255, 0.6)'
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
        }
      ]
    };

    // Gráfico de rangos de edad
    const rangosEdad = Object.keys(this.estadisticas.distribucion_edad);
    const valoresEdad = Object.values(this.estadisticas.distribucion_edad);

    this.ageChartData = {
      labels: rangosEdad,
      datasets: [
        {
          label: 'Cantidad de Personas',
          data: valoresEdad,
          backgroundColor: 'rgba(52, 152, 219, 0.6)',
          borderColor: 'rgba(52, 152, 219, 1)',
          borderWidth: 2
        }
      ]
    };

    // Actualizar gráficos
    if (this.chart) {
      this.chart.update();
    }
  }

  filterPersonas(): void {
    if (!this.searchTerm.trim()) {
      this.filteredPersonas = [...this.personas];
      return;
    }

    const term = this.searchTerm.toLowerCase();
    this.filteredPersonas = this.personas.filter(persona =>
      persona.nombre.toLowerCase().includes(term) ||
      persona.apellido.toLowerCase().includes(term) ||
      persona.correo.toLowerCase().includes(term) ||
      persona.tipo_sangre.toLowerCase().includes(term)
    );
  }

  deletePersona(persona: Persona): void {
    if (!persona.id) return;

    if (confirm(`¿Estás seguro de eliminar a ${persona.nombre} ${persona.apellido}?`)) {
      this.apiService.deletePersona(persona.id).subscribe({
        next: (response) => {
          if (response.estado) {
            this.notificationService.success(
              'Persona Eliminada',
              'La persona se eliminó correctamente'
            );
            this.loadPersonas();
            this.loadEstadisticas();
          }
        },
        error: (error) => {
          this.notificationService.error(
            'Error',
            'No se pudo eliminar la persona'
          );
          console.error('Error eliminando persona:', error);
        }
      });
    }
  }

  refreshData(): void {
    this.loadPersonas();
    this.loadEstadisticas();
    this.notificationService.info('Actualizado', 'Datos actualizados correctamente');
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
      this.loadPersonas();
    }
  }

  prevPage(): void {
    if (this.currentPage > 1) {
      this.currentPage--;
      this.loadPersonas();
    }
  }

  get totalPages(): number {
    return Math.ceil(this.totalPersonas / this.pageSize);
  }

  exportData(): void {
    // Implementar exportación a CSV/Excel si es necesario
    this.notificationService.info(
      'Exportar',
      'Funcionalidad de exportación en desarrollo'
    );
  }
}