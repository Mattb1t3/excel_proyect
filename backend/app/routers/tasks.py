from fastapi import APIRouter

router = APIRouter(prefix="/tasks", tags=["Tasks"])


@router.get("/{task_id}/status")
async def get_task_status(task_id: str):
    return {"message": "Endpoint en desarrollo"}
