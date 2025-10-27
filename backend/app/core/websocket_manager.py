from fastapi import WebSocket
from typing import List, Dict
import json


class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        """Aceptar nueva conexión WebSocket"""
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        """Remover conexión WebSocket"""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
    
    async def send_personal_message(self, message: Dict, websocket: WebSocket):
        """Enviar mensaje a un cliente específico"""
        await websocket.send_json(message)
    
    async def broadcast(self, message: Dict):
        """Enviar mensaje a todos los clientes conectados"""
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception:
                disconnected.append(connection)
        
        # Limpiar conexiones fallidas
        for conn in disconnected:
            self.disconnect(conn)
    
    async def notify_upload_start(self, filename: str, total_records: int):
        """Notificar inicio de carga"""
        await self.broadcast({
            "type": "upload_start",
            "data": {
                "filename": filename,
                "total_records": total_records,
                "timestamp": str(datetime.utcnow())
            }
        })
    
    async def notify_upload_progress(self, task_id: str, progress: int, processed: int, total: int):
        """Notificar progreso de carga"""
        await self.broadcast({
            "type": "upload_progress",
            "data": {
                "task_id": task_id,
                "progress": progress,
                "processed": processed,
                "total": total,
                "timestamp": str(datetime.utcnow())
            }
        })
    
    async def notify_upload_complete(
        self, 
        filename: str, 
        exitosos: int, 
        duplicados: int, 
        errores: int,
        detalles_duplicados: List[Dict] = None
    ):
        """Notificar finalización de carga"""
        await self.broadcast({
            "type": "upload_complete",
            "data": {
                "filename": filename,
                "exitosos": exitosos,
                "duplicados": duplicados,
                "errores": errores,
                "detalles_duplicados": detalles_duplicados or [],
                "timestamp": str(datetime.utcnow())
            }
        })
    
    async def notify_upload_error(self, filename: str, error: str):
        """Notificar error en carga"""
        await self.broadcast({
            "type": "upload_error",
            "data": {
                "filename": filename,
                "error": error,
                "timestamp": str(datetime.utcnow())
            }
        })
    
    async def notify_duplicates_detected(self, duplicados: List[Dict]):
        """Notificar duplicados detectados"""
        await self.broadcast({
            "type": "duplicates_detected",
            "data": {
                "duplicados": duplicados,
                "total": len(duplicados),
                "timestamp": str(datetime.utcnow())
            }
        })


from datetime import datetime

# Instancia global del manager
manager = ConnectionManager()