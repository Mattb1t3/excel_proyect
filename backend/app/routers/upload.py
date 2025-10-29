from fastapi import APIRouter, UploadFile, File, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.schemas.response import ApiResponse, success_response, error_response
from app.schemas.persona import PersonaCreate
from app.services.persona_service import PersonaService
from typing import List
import openpyxl
from io import BytesIO

router = APIRouter(prefix="/upload", tags=["Upload"])


@router.post("/validate-and-process")
async def validate_and_process_file(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db)
):
    """Valida y procesa el archivo XLSX completo en el backend"""
    
    # Validar extensión
    if not file.filename.endswith(('.xlsx', '.xls')):
        return error_response(
            titulo="Archivo Inválido",
            mensaje="Solo se permiten archivos Excel (.xlsx, .xls)",
            errores=["Extensión no válida"]
        )
    
    try:
        # Leer el archivo
        contents = await file.read()
        workbook = openpyxl.load_workbook(BytesIO(contents))
        sheet = workbook.active
        
        # Leer datos
        personas = []
        errores = []
        
        # Obtener headers (primera fila)
        headers = [cell.value for cell in sheet[1]]
        
        # Validar que las columnas requeridas existan
        required = ['nombre', 'apellido', 'edad', 'correo', 'tipo_sangre']
        headers_lower = [str(h).lower().strip() if h else '' for h in headers]
        
        for req in required:
            if req not in headers_lower:
                return error_response(
                    titulo="Estructura Inválida",
                    mensaje=f"Falta la columna requerida: {req}",
                    errores=[f"Columnas encontradas: {', '.join(headers_lower)}"]
                )
        
        # Crear mapeo de índices
        indices = {col: headers_lower.index(col) for col in required}
        
        # Procesar filas (desde la fila 2)
        for i, row in enumerate(sheet.iter_rows(min_row=2, values_only=True), start=2):
            if all(cell is None for cell in row):
                continue  # Fila vacía
            
            try:
                persona = PersonaCreate(
                    nombre=str(row[indices['nombre']]).strip(),
                    apellido=str(row[indices['apellido']]).strip(),
                    edad=int(row[indices['edad']]),
                    correo=str(row[indices['correo']]).strip().lower(),
                    tipo_sangre=str(row[indices['tipo_sangre']]).strip().upper()
                )
                personas.append(persona)
            except Exception as e:
                errores.append(f"Fila {i}: {str(e)}")
        
        if not personas:
            return error_response(
                titulo="Sin Datos",
                mensaje="No se encontraron datos válidos en el archivo",
                errores=errores
            )
        
        # Procesar personas
        personas_creadas, duplicados = await PersonaService.bulk_create(db, personas)
        
        resultado = {
            "total_procesados": len(personas),
            "registros_exitosos": len(personas_creadas),
            "registros_duplicados": len(duplicados),
            "errores": errores
        }
        
        if duplicados:
            resultado["detalles_duplicados"] = duplicados
        
        if errores:
            return success_response(
                titulo="Carga con Advertencias",
                mensaje=f"Se cargaron {len(personas_creadas)} registros. {len(duplicados)} duplicados. {len(errores)} errores.",
                datos=resultado
            )
        
        if duplicados:
            return success_response(
                titulo="Carga con Duplicados",
                mensaje=f"Se cargaron {len(personas_creadas)} registros. {len(duplicados)} duplicados omitidos.",
                datos=resultado
            )
        
        return success_response(
            titulo="Carga Exitosa",
            mensaje=f"Se cargaron {len(personas_creadas)} registros correctamente",
            datos=resultado
        )
        
    except Exception as e:
        return error_response(
            titulo="Error",
            mensaje="Error al procesar el archivo",
            errores=[str(e)]
        )


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
        mensaje="Archivo validado correctamente",
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
