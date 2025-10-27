from fastapi import APIRouter, UploadFile, File, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.schemas.response import ApiResponse, success_response, error_response
from app.schemas.persona import PersonaCreate
from app.services.persona_service import PersonaService
from typing import List

router = APIRouter(prefix="/upload", tags=["Upload"])


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
        mensaje="Archivo validado correctamente (validación completa pendiente)",
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
