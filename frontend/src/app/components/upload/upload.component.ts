import { Component, OnInit, OnDestroy } from '@angular/core';
import { ApiService } from '../../services/api.service';
import { WebSocketService } from '../../services/websocket.service';
import { NotificationService } from '../../services/notification.service';
import { 
  Persona, 
  PersonaValidacion, 
  ValidacionArchivoResponse,
  TaskStatus 
} from '../../models/models';
import { environment } from '../../../environments/environment';
import { Subscription, interval } from 'rxjs';

@Component({
  selector: 'app-upload',
  templateUrl: './upload.component.html',
  styleUrls: ['./upload.component.scss']
})
export class UploadComponent implements OnInit, OnDestroy {
  // Estado del archivo
  selectedFile: File | null = null;
  fileName: string = '';
  fileSize: number = 0;
  
  // Validación
  validacionResultado: ValidacionArchivoResponse | null = null;
  isValidating: boolean = false;
  isProcessing: boolean = false;
  
  // Datos editables
  personasEditable: PersonaValidacion[] = [];
  personasSeleccionadas: Set<number> = new Set();
  
  // Tarea asíncrona
  taskId: string | null = null;
  taskProgress: number = 0;
  pollingSubscription: Subscription | null = null;
  
  // WebSocket
  wsSubscription: Subscription | null = null;
  
  // Paginación tabla temporal
  currentPage: number = 1;
  pageSize: number = 20;

  constructor(
    private apiService: ApiService,
    private wsService: WebSocketService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.subscribeToWebSocket();
  }

  ngOnDestroy(): void {
    if (this.wsSubscription) {
      this.wsSubscription.unsubscribe();
    }
    if (this.pollingSubscription) {
      this.pollingSubscription.unsubscribe();
    }
  }

  subscribeToWebSocket(): void {
    this.wsSubscription = this.wsService.getMessages().subscribe(
      (notification) => {
        this.handleWebSocketNotification(notification);
      }
    );
  }

  handleWebSocketNotification(notification: any): void {
    switch (notification.type) {
      case 'upload_start':
        this.notificationService.info(
          'Carga Iniciada',
          `Procesando archivo: ${notification.data.filename}`
        );
        break;
      
      case 'upload_progress':
        this.taskProgress = notification.data.progress;
        break;
      
      case 'upload_complete':
        this.notificationService.success(
          'Carga Completada',
          `${notification.data.exitosos} registros cargados exitosamente`
        );
        if (notification.data.duplicados > 0) {
          this.notificationService.warning(
            'Duplicados Detectados',
            `${notification.data.duplicados} registros duplicados fueron omitidos`
          );
        }
        this.resetForm();
        break;
      
      case 'upload_error':
        this.notificationService.error(
          'Error en Carga',
          notification.data.error
        );
        this.isProcessing = false;
        break;
      
      case 'duplicates_detected':
        this.notificationService.warning(
          'Duplicados',
          `Se detectaron ${notification.data.total} registros duplicados`
        );
        break;
    }
  }

  onFileSelected(event: any): void {
    const file: File = event.target.files[0];
    
    if (!file) {
      return;
    }

    // Validar extensión
    const extension = file.name.substring(file.name.lastIndexOf('.')).toLowerCase();
    if (!environment.allowedExtensions.includes(extension)) {
      this.notificationService.error(
        'Archivo Inválido',
        'Solo se permiten archivos .xlsx o .xls'
      );
      return;
    }

    // Validar tamaño
    if (file.size > environment.maxFileSize) {
      this.notificationService.error(
        'Archivo Muy Grande',
        `El archivo excede el tamaño máximo de ${environment.maxFileSize / 1024 / 1024}MB`
      );
      return;
    }

    this.selectedFile = file;
    this.fileName = file.name;
    this.fileSize = file.size;
    
    // Auto-validar
    this.validateFile();
  }

  validateFile(): void {
    if (!this.selectedFile) {
      return;
    }

    this.isValidating = true;
    this.validacionResultado = null;

    this.apiService.validateFile(this.selectedFile).subscribe({
      next: (response) => {
        this.isValidating = false;
        
        if (response.estado && response.datos) {
          this.validacionResultado = response.datos;
          this.personasEditable = [...response.datos.registros];
          
          // Seleccionar solo los registros válidos
          this.personasSeleccionadas.clear();
          response.datos.registros.forEach((reg, idx) => {
            if (reg.valido) {
              this.personasSeleccionadas.add(idx);
            }
          });

          if (response.datos.registros_invalidos > 0) {
            this.notificationService.warning(
              response.titulo,
              response.mensaje
            );
          } else {
            this.notificationService.success(
              response.titulo,
              response.mensaje
            );
          }
        } else {
          this.notificationService.error(
            response.titulo,
            response.mensaje
          );
        }
      },
      error: (error) => {
        this.isValidating = false;
        this.notificationService.error(
          'Error',
          'Ocurrió un error al validar el archivo'
        );
        console.error('Error validando archivo:', error);
      }
    });
  }

  toggleSelection(index: number): void {
    if (this.personasSeleccionadas.has(index)) {
      this.personasSeleccionadas.delete(index);
    } else {
      this.personasSeleccionadas.add(index);
    }
  }

  toggleAll(): void {
    const validIndices = this.personasEditable
      .map((p, idx) => p.valido ? idx : -1)
      .filter(idx => idx !== -1);

    if (this.personasSeleccionadas.size === validIndices.length) {
      this.personasSeleccionadas.clear();
    } else {
      validIndices.forEach(idx => this.personasSeleccionadas.add(idx));
    }
  }

  updatePersona(index: number, field: string, value: any): void {
    if (this.personasEditable[index].datos) {
      (this.personasEditable[index].datos as any)[field] = value;
    }
  }

  processData(): void {
    if (!this.validacionResultado || this.personasSeleccionadas.size === 0) {
      this.notificationService.warning(
        'Sin Selección',
        'Debe seleccionar al menos un registro válido para cargar'
      );
      return;
    }

    this.isProcessing = true;

    // Obtener solo las personas seleccionadas
    const personasACargar: Persona[] = Array.from(this.personasSeleccionadas)
      .map(idx => this.personasEditable[idx].datos)
      .filter(p => p !== null) as Persona[];

    this.apiService.processFile(personasACargar, this.fileName).subscribe({
      next: (response) => {
        if (response.estado && response.datos) {
          
          // Si es asíncrono, iniciar polling
          if (response.datos.asincrono && response.datos.task_id) {
            this.taskId = response.datos.task_id;
            this.startPollingTask(response.datos.task_id);
            
            this.notificationService.info(
              response.titulo,
              response.mensaje
            );
          } else {
            // Carga síncrona completada
            this.isProcessing = false;
            
            if (response.datos.registros_duplicados > 0) {
              this.notificationService.warning(
                response.titulo,
                response.mensaje
              );
            } else {
              this.notificationService.success(
                response.titulo,
                response.mensaje
              );
            }
            
            this.resetForm();
          }
        } else {
          this.isProcessing = false;
          this.notificationService.error(
            response.titulo,
            response.mensaje
          );
        }
      },
      error: (error) => {
        this.isProcessing = false;
        this.notificationService.error(
          'Error',
          'Ocurrió un error al procesar los datos'
        );
        console.error('Error procesando datos:', error);
      }
    });
  }

  startPollingTask(taskId: string): void {
    this.pollingSubscription = interval(2000).subscribe(() => {
      this.apiService.getTaskStatus(taskId).subscribe({
        next: (response) => {
          if (response.estado && response.datos) {
            const status: TaskStatus = response.datos;
            
            this.taskProgress = status.progreso || 0;
            
            if (status.estado === 'completed') {
              this.isProcessing = false;
              this.taskProgress = 100;
              this.stopPollingTask();
              
              this.notificationService.success(
                'Carga Completada',
                status.mensaje
              );
              
              this.resetForm();
            } else if (status.estado === 'failed') {
              this.isProcessing = false;
              this.stopPollingTask();
              
              this.notificationService.error(
                'Error en Carga',
                status.error || 'La carga falló'
              );
            }
          }
        },
        error: (error) => {
          console.error('Error consultando estado de tarea:', error);
        }
      });
    });
  }

  stopPollingTask(): void {
    if (this.pollingSubscription) {
      this.pollingSubscription.unsubscribe();
      this.pollingSubscription = null;
    }
  }

  resetForm(): void {
    this.selectedFile = null;
    this.fileName = '';
    this.fileSize = 0;
    this.validacionResultado = null;
    this.personasEditable = [];
    this.personasSeleccionadas.clear();
    this.taskId = null;
    this.taskProgress = 0;
    this.stopPollingTask();
  }

  cancelUpload(): void {
    this.resetForm();
    this.isProcessing = false;
    this.isValidating = false;
  }

  get paginatedData(): PersonaValidacion[] {
    const start = (this.currentPage - 1) * this.pageSize;
    const end = start + this.pageSize;
    return this.personasEditable.slice(start, end);
  }

  get totalPages(): number {
    return Math.ceil(this.personasEditable.length / this.pageSize);
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
    }
  }

  prevPage(): void {
    if (this.currentPage > 1) {
      this.currentPage--;
    }
  }

  getFileSizeFormatted(): string {
    const kb = this.fileSize / 1024;
    if (kb < 1024) {
      return `${kb.toFixed(2)} KB`;
    }
    return `${(kb / 1024).toFixed(2)} MB`;
  }
}