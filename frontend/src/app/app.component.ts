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
