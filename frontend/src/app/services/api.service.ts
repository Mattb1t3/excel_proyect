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

  uploadAndProcess(formData: FormData): Observable<ApiResponse> {
    return this.http.post<ApiResponse>(`${this.apiUrl}/upload/validate-and-process`, formData);
  }

  processData(personas: Persona[]): Observable<ApiResponse> {
    return this.http.post<ApiResponse>(`${this.apiUrl}/upload/process`, personas);
  }
}
