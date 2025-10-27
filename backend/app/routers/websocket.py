from fastapi import APIRouter, WebSocket

router = APIRouter(tags=["WebSocket"])


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    await websocket.send_json({"message": "Connected"})
    await websocket.close()
