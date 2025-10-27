from pydantic import BaseModel
from typing import Any, Optional, List
from enum import Enum


class ResponseType(str, Enum):
    SUCCESS = "success"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"


class ApiResponse(BaseModel):
    estado: bool
    tipo: ResponseType
    titulo: str
    mensaje: str
    datos: Optional[Any] = None
    errores: Optional[List[str]] = None


def success_response(titulo: str, mensaje: str, datos: Any = None) -> ApiResponse:
    return ApiResponse(
        estado=True,
        tipo=ResponseType.SUCCESS,
        titulo=titulo,
        mensaje=mensaje,
        datos=datos
    )


def error_response(titulo: str, mensaje: str, errores: List[str] = None) -> ApiResponse:
    return ApiResponse(
        estado=False,
        tipo=ResponseType.ERROR,
        titulo=titulo,
        mensaje=mensaje,
        errores=errores
    )
