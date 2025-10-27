import { Component, OnInit } from '@angular/core';
import { ApiService } from '../../services/api.service';
import { NotificationService } from '../../services/notification.service';
import { HistorialCarga } from '../../models/models';

@Component({
  selector: 'app-historial',
  templateUrl: './historial.component.html',
  styleUrls: ['./historial.component.scss']
})
export class HistorialComponent implements OnInit {
  historial: HistorialCarga[] = [];
  isLoading: boolean = false;
  selectedHistorial: HistorialCarga | null = null;
  showDetails: boolean = false;

  // Paginación
  currentPage: number = 1;
  pageSize: number = 20;
  totalItems: number = 0;

  constructor(
    private apiService: ApiService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadHistorial();
  }

  loadHistorial(): void {
    this.isLoading = true;
    const skip = (this.currentPage - 1) * this.pageSize;

    this.apiService.getHistorial(skip, this.pageSize).subscribe({
      next: (response) => {
        this.isLoading = false;
        if (response.estado && response.datos) {
          this.historial = response.datos.historial;
          this.totalItems = response.datos.total;
        }
      },
      error: (error) => {
        this.isLoading = false;
        this.notificationService.error(
          'Error',
          'No se pudo cargar el historial'
        );
        console.error('Error cargando historial:', error);
      }
    });
  }

  viewDetails(item: HistorialCarga): void {
    this.selectedHistorial = item;
    this.showDetails = true;
  }

  closeDetails(): void {
    this.showDetails = false;
    this.selectedHistorial = null;
  }

  getStatusClass(estado: string): string {
    const statusClasses: { [key: string]: string } = {
      'completed': 'success',
      'processing': 'warning',
      'pending': 'info',
      'failed': 'error'
    };
    return statusClasses[estado] || 'default';
  }

  getStatusLabel(estado: string): string {
    const statusLabels: { [key: string]: string } = {
      'completed': 'Completado',
      'processing': 'Procesando',
      'pending': 'Pendiente',
      'failed': 'Fallido'
    };
    return statusLabels[estado] || estado;
  }

  getStatusIcon(estado: string): string {
    const icons: { [key: string]: string } = {
      'completed': '✓',
      'processing': '⟳',
      'pending': '⏱',
      'failed': '✗'
    };
    return icons[estado] || '•';
  }

  refreshData(): void {
    this.loadHistorial();
    this.notificationService.info('Actualizado', 'Historial actualizado');
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
      this.loadHistorial();
    }
  }

  prevPage(): void {
    if (this.currentPage > 1) {
      this.currentPage--;
      this.loadHistorial();
    }
  }

  get totalPages(): number {
    return Math.ceil(this.totalItems / this.pageSize);
  }

  formatDate(date: string | null): string {
    if (!date) return 'N/A';
    return new Date(date).toLocaleString('es-ES');
  }

  calculateDuration(start: string, end: string | null): string {
    if (!end) return 'En proceso';
    
    const startTime = new Date(start).getTime();
    const endTime = new Date(end).getTime();
    const diff = endTime - startTime;
    
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    
    if (hours > 0) return `${hours}h ${minutes % 60}m`;
    if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
    return `${seconds}s`;
  }
}