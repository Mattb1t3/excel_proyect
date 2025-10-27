// Tipos de sangre
export enum TipoSangre {
  A_POSITIVO = 'A+',
  A_NEGATIVO = 'A-',
  B_POSITIVO = 'B+',
  B_NEGATIVO = 'B-',
  AB_POSITIVO = 'AB+',
  AB_NEGATIVO = 'AB-',
  O_POSITIVO = 'O+',
  O_NEGATIVO = 'O-'
}

// Persona
export interface Persona {
  id?: number;
  nombre: string;
  apellido: string;
  edad: number;
  correo: string;
  tipo_sangre: TipoSangre;
  created_at?: string;
  updated_at?: string;
}

// Validación de persona
export interface PersonaValidacion {
  fila: number;
  datos: Persona | null;
  valido: boolean;
  errores: string[] | null;
}

// Respuesta de validación de archivo
export interface ValidacionArchivoResponse {
  archivo_valido: boolean;
  total_registros: number;
  registros_validos: number;
  registros_invalidos: number;
  columnas_esperadas: string[];
  columnas_encontradas: string[];
  registros: PersonaValidacion[];
  errores_estructura: string[] | null;
}

// Historial de carga
export interface HistorialCarga {
  id: number;
  nombre_archivo: string;
  total_registros: number;
  registros_exitosos: number;
  registros_duplicados: number;
  registros_error: number;
  fue_asincrono: boolean;
  task_id: string | null;
  estado: string;
  detalles_duplicados: any;
  detalles_errores: any;
  created_at: string;
  completed_at: string | null;
}

// Respuesta API
export enum ResponseType {
  SUCCESS = 'success',
  ERROR = 'error',
  WARNING = 'warning',
  INFO = 'info'
}

export interface ApiResponse<T = any> {
  estado: boolean;
  tipo: ResponseType;
  titulo: string;
  mensaje: string;
  datos?: T;
  errores?: string[];
}

// Estado de tarea Celery
export interface TaskStatus {
  estado: string;
  progreso?: number;
  procesados?: number;
  total?: number;
  exitosos?: number;
  duplicados?: number;
  mensaje: string;
  resultado?: any;
  error?: string;
}

// Estadísticas
export interface Estadisticas {
  total_personas: number;
  distribucion_tipo_sangre: { [key: string]: number };
  edad_promedio: number;
  distribucion_edad: { [key: string]: number };
}

// Notificación WebSocket
export interface WebSocketNotification {
  type: string;
  data: any;
}