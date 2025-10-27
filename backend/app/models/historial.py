from sqlalchemy import Column, Integer, String, DateTime, Boolean, JSON
from sqlalchemy.sql import func
from app.core.database import Base


class HistorialCarga(Base):
    __tablename__ = "historial_cargas"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nombre_archivo = Column(String(255), nullable=False)
    total_registros = Column(Integer, nullable=False, default=0)
    registros_exitosos = Column(Integer, nullable=False, default=0)
    registros_duplicados = Column(Integer, nullable=False, default=0)
    registros_error = Column(Integer, nullable=False, default=0)
    fue_asincrono = Column(Boolean, default=False)
    task_id = Column(String(255), nullable=True)
    estado = Column(String(50), nullable=False)
    detalles_duplicados = Column(JSON, nullable=True)
    detalles_errores = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)
