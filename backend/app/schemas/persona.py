from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from app.models.persona import TipoSangre


class PersonaBase(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    apellido: str = Field(..., min_length=1, max_length=100)
    edad: int = Field(..., ge=0, le=150)
    correo: EmailStr
    tipo_sangre: TipoSangre


class PersonaCreate(PersonaBase):
    pass


class PersonaResponse(PersonaBase):
    id: int
    created_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True
