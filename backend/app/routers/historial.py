from fastapi import APIRouter

router = APIRouter(prefix="/historial", tags=["Historial"])


@router.get("")
async def get_historial():
    return {"message": "Endpoint en desarrollo"}
