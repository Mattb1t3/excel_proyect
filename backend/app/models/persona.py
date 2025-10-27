from sqlalchemy import Column, Integer, String, DateTime, Enum as SQLEnum
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class TipoSangre(str, enum.Enum):
    A_POSITIVO = "A+"
    A_NEGATIVO = "A-"
    B_POSITIVO = "B+"
    B_NEGATIVO = "B-"
    AB_POSITIVO = "AB+"
    AB_NEGATIVO = "AB-"
    O_POSITIVO = "O+"
    O_NEGATIVO = "O-"


class Persona(Base):
    __tablename__ = "personas"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nombre = Column(String(100), nullable=False)
    apellido = Column(String(100), nullable=False)
    edad = Column(Integer, nullable=False)
    correo = Column(String(255), unique=True, nullable=False, index=True)
    tipo_sangre = Column(SQLEnum(TipoSangre), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
