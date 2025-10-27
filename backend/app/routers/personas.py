from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.schemas.response import ApiResponse, success_response, error_response
from app.schemas.persona import PersonaResponse
from app.services.persona_service import PersonaService
from typing import List

router = APIRouter(prefix="/personas", tags=["Personas"])


@router.get("", response_model=ApiResponse)
async def get_personas(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: AsyncSession = Depends(get_db)
):
    try:
        personas = await PersonaService.get_all(db, skip=skip, limit=limit)
        personas_response = [PersonaResponse.model_validate(p) for p in personas]
        
        return success_response(
            titulo="Personas Obtenidas",
            mensaje=f"Se encontraron {len(personas_response)} personas",
            datos={
                "personas": [p.model_dump() for p in personas_response],
                "total": len(personas_response)
            }
        )
    except Exception as e:
        return error_response(
            titulo="Error",
            mensaje="Error al obtener personas",
            errores=[str(e)]
        )


@router.get("/estadisticas/resumen", response_model=ApiResponse)
async def get_statistics(db: AsyncSession = Depends(get_db)):
    try:
        stats = await PersonaService.get_statistics(db)
        return success_response(
            titulo="Estadísticas Obtenidas",
            mensaje="Estadísticas calculadas correctamente",
            datos=stats
        )
    except Exception as e:
        return error_response(
            titulo="Error",
            mensaje="Error al obtener estadísticas",
            errores=[str(e)]
        )
