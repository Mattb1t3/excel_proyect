from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.historial import HistorialCarga
from app.schemas.historial import HistorialCargaCreate, HistorialCargaUpdate
from typing import List, Optional
from datetime import datetime


class HistorialService:
    
    @staticmethod
    async def create(db: AsyncSession, historial_data: HistorialCargaCreate) -> HistorialCarga:
        """Crear un nuevo registro de historial"""
        historial = HistorialCarga(**historial_data.model_dump())
        db.add(historial)
        await db.commit()
        await db.refresh(historial)
        return historial
    
    @staticmethod
    async def get_by_id(db: AsyncSession, historial_id: int) -> Optional[HistorialCarga]:
        """Obtener historial por ID"""
        result = await db.execute(
            select(HistorialCarga).where(HistorialCarga.id == historial_id)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def get_by_task_id(db: AsyncSession, task_id: str) -> Optional[HistorialCarga]:
        """Obtener historial por task_id de Celery"""
        result = await db.execute(
            select(HistorialCarga).where(HistorialCarga.task_id == task_id)
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def get_all(
        db: AsyncSession, 
        skip: int = 0, 
        limit: int = 50
    ) -> List[HistorialCarga]:
        """Obtener todo el historial con paginación"""
        result = await db.execute(
            select(HistorialCarga)
            .offset(skip)
            .limit(limit)
            .order_by(HistorialCarga.created_at.desc())
        )
        return result.scalars().all()
    
    @staticmethod
    async def update(
        db: AsyncSession, 
        historial_id: int, 
        historial_data: HistorialCargaUpdate
    ) -> Optional[HistorialCarga]:
        """Actualizar registro de historial"""
        historial = await HistorialService.get_by_id(db, historial_id)
        if historial:
            for key, value in historial_data.model_dump(exclude_unset=True).items():
                setattr(historial, key, value)
            await db.commit()
            await db.refresh(historial)
        return historial
    
    @staticmethod
    async def update_by_task_id(
        db: AsyncSession,
        task_id: str,
        historial_data: HistorialCargaUpdate
    ) -> Optional[HistorialCarga]:
        """Actualizar registro por task_id"""
        historial = await HistorialService.get_by_task_id(db, task_id)
        if historial:
            for key, value in historial_data.model_dump(exclude_unset=True).items():
                setattr(historial, key, value)
            await db.commit()
            await db.refresh(historial)
        return historial
    
    @staticmethod
    async def marcar_completado(
        db: AsyncSession,
        historial_id: int,
        registros_exitosos: int,
        registros_duplicados: int,
        registros_error: int,
        detalles_duplicados: Optional[dict] = None,
        detalles_errores: Optional[dict] = None
    ) -> Optional[HistorialCarga]:
        """Marcar una carga como completada"""
        return await HistorialService.update(
            db,
            historial_id,
            HistorialCargaUpdate(
                estado="completed",
                registros_exitosos=registros_exitosos,
                registros_duplicados=registros_duplicados,
                registros_error=registros_error,
                detalles_duplicados=detalles_duplicados,
                detalles_errores=detalles_errores,
                completed_at=datetime.utcnow()
            )
        )
    
    @staticmethod
    async def marcar_fallido(
        db: AsyncSession,
        historial_id: int,
        detalles_errores: dict
    ) -> Optional[HistorialCarga]:
        """Marcar una carga como fallida"""
        return await HistorialService.update(
            db,
            historial_id,
            HistorialCargaUpdate(
                estado="failed",
                detalles_errores=detalles_errores,
                completed_at=datetime.utcnow()
            )
        )