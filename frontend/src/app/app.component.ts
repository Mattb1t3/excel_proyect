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
