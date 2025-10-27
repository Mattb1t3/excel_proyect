import openpyxl
import pandas as pd
from typing import List, Dict, Tuple
from app.schemas.persona import PersonaBase, PersonaValidacion, ValidacionArchivoResponse
from app.models.persona import TipoSangre
from pydantic import ValidationError
import re


class XLSXValidator:
    COLUMNAS_ESPERADAS = ["nombre", "apellido", "edad", "correo", "tipo_sangre"]
    TIPOS_SANGRE_VALIDOS = [ts.value for ts in TipoSangre]
    
    def __init__(self, file_path: str):
        self.file_path = file_path
        self.errores_estructura = []
    
    def validar_estructura(self) -> Tuple[bool, List[str]]:
        """Valida que el archivo tenga la estructura correcta"""
        try:
            # Leer archivo con openpyxl
            workbook = openpyxl.load_workbook(self.file_path, read_only=True)
            sheet = workbook.active
            
            # Obtener encabezados (primera fila)
            headers = [cell.value for cell in sheet[1]]
            
            # Limpiar headers (quitar espacios y convertir a minúsculas)
            headers_limpios = [
                str(h).strip().lower().replace(" ", "_") 
                for h in headers if h is not None
            ]
            
            # Validar que todas las columnas esperadas estén presentes
            columnas_faltantes = set(self.COLUMNAS_ESPERADAS) - set(headers_limpios)
            
            if columnas_faltantes:
                self.errores_estructura.append(
                    f"Columnas faltantes: {', '.join(columnas_faltantes)}"
                )
                return False, headers_limpios
            
            return True, headers_limpios
            
        except Exception as e:
            self.errores_estructura.append(f"Error al leer el archivo: {str(e)}")
            return False, []
    
    def validar_email(self, email: str) -> bool:
        """Valida formato de email"""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None
    
    def validar_tipo_sangre(self, tipo: str) -> bool:
        """Valida que el tipo de sangre sea válido"""
        return tipo.upper() in self.TIPOS_SANGRE_VALIDOS
    
    def validar_registros(self) -> ValidacionArchivoResponse:
        """Valida todos los registros del archivo"""
        # Primero validar estructura
        estructura_valida, headers_encontrados = self.validar_estructura()
        
        if not estructura_valida:
            return ValidacionArchivoResponse(
                archivo_valido=False,
                total_registros=0,
                registros_validos=0,
                registros_invalidos=0,
                columnas_esperadas=self.COLUMNAS_ESPERADAS,
                columnas_encontradas=headers_encontrados,
                registros=[],
                errores_estructura=self.errores_estructura
            )
        
        # Leer datos con pandas
        df = pd.read_excel(self.file_path)
        
        # Limpiar nombres de columnas
        df.columns = [
            str(col).strip().lower().replace(" ", "_") 
            for col in df.columns
        ]
        
        # Validar cada registro
        registros_validados = []
        registros_validos = 0
        registros_invalidos = 0
        
        for index, row in df.iterrows():
            fila_num = index + 2  # +2 porque Excel empieza en 1 y hay header
            errores_fila = []
            
            try:
                # Preparar datos
                datos = {
                    "nombre": str(row.get("nombre", "")).strip(),
                    "apellido": str(row.get("apellido", "")).strip(),
                    "edad": int(row.get("edad", 0)) if pd.notna(row.get("edad")) else 0,
                    "correo": str(row.get("correo", "")).strip().lower(),
                    "tipo_sangre": str(row.get("tipo_sangre", "")).strip().upper()
                }
                
                # Validaciones específicas
                if not datos["nombre"]:
                    errores_fila.append("El nombre no puede estar vacío")
                
                if not datos["apellido"]:
                    errores_fila.append("El apellido no puede estar vacío")
                
                if datos["edad"] < 0 or datos["edad"] > 150:
                    errores_fila.append("La edad debe estar entre 0 y 150 años")
                
                if not self.validar_email(datos["correo"]):
                    errores_fila.append("El formato del correo no es válido")
                
                if not self.validar_tipo_sangre(datos["tipo_sangre"]):
                    errores_fila.append(
                        f"Tipo de sangre inválido. Valores permitidos: {', '.join(self.TIPOS_SANGRE_VALIDOS)}"
                    )
                
                # Intentar crear el objeto Pydantic
                if not errores_fila:
                    try:
                        persona = PersonaBase(**datos)
                        registros_validados.append(
                            PersonaValidacion(
                                fila=fila_num,
                                datos=persona,
                                valido=True,
                                errores=None
                            )
                        )
                        registros_validos += 1
                    except ValidationError as ve:
                        errores_fila.extend([err["msg"] for err in ve.errors()])
                        registros_validados.append(
                            PersonaValidacion(
                                fila=fila_num,
                                datos=PersonaBase(**datos) if not errores_fila else None,
                                valido=False,
                                errores=errores_fila
                            )
                        )
                        registros_invalidos += 1
                else:
                    registros_validados.append(
                        PersonaValidacion(
                            fila=fila_num,
                            datos=None,
                            valido=False,
                            errores=errores_fila
                        )
                    )
                    registros_invalidos += 1
                    
            except Exception as e:
                errores_fila.append(f"Error al procesar la fila: {str(e)}")
                registros_validados.append(
                    PersonaValidacion(
                        fila=fila_num,
                        datos=None,
                        valido=False,
                        errores=errores_fila
                    )
                )
                registros_invalidos += 1
        
        return ValidacionArchivoResponse(
            archivo_valido=True,
            total_registros=len(df),
            registros_validos=registros_validos,
            registros_invalidos=registros_invalidos,
            columnas_esperadas=self.COLUMNAS_ESPERADAS,
            columnas_encontradas=headers_encontrados,
            registros=registros_validados,
            errores_estructura=None
        )