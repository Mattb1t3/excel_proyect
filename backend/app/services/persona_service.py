from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models.persona import Persona
from app.schemas.persona import PersonaCreate
from typing import List, Dict, Tuple, Optional


class PersonaService:
    
    @staticmethod
    async def create(db: AsyncSession, persona_data: PersonaCreate) -> Persona:
        persona = Persona(**persona_data.model_dump())
        db.add(persona)
        await db.commit()
        await db.refresh(persona)
        return persona
    
    @staticmethod
    async def get_by_email(db: AsyncSession, correo: str) -> Optional[Persona]:
        result = await db.execute(
            select(Persona).where(Persona.correo == correo.lower())
        )
        return result.scalar_one_or_none()
    
    @staticmethod
    async def get_all(db: AsyncSession, skip: int = 0, limit: int = 100) -> List[Persona]:
        result = await db.execute(
            select(Persona)
            .offset(skip)
            .limit(limit)
            .order_by(Persona.created_at.desc())
        )
        return result.scalars().all()
    
    @staticmethod
    async def bulk_create(db: AsyncSession, personas_data: List[PersonaCreate]) -> Tuple[List[Persona], List[Dict]]:
        personas_creadas = []
        duplicados = []
        
        for idx, persona_data in enumerate(personas_data):
            existing = await PersonaService.get_by_email(db, persona_data.correo)
            
            if existing:
                duplicados.append({
                    "indice": idx,
                    "correo": persona_data.correo,
                    "nombre_completo": f"{persona_data.nombre} {persona_data.apellido}",
                    "mensaje": "Correo ya registrado en la base de datos"
                })
            else:
                persona = Persona(**persona_data.model_dump())
                db.add(persona)
                personas_creadas.append(persona)
        
        if personas_creadas:
            await db.commit()
            for persona in personas_creadas:
                await db.refresh(persona)
        
        return personas_creadas, duplicados
    
    @staticmethod
    async def get_statistics(db: AsyncSession) -> Dict:
        total_result = await db.execute(select(func.count(Persona.id)))
        total = total_result.scalar()
        
        tipo_sangre_result = await db.execute(
            select(Persona.tipo_sangre, func.count(Persona.id))
            .group_by(Persona.tipo_sangre)
        )
        distribucion_sangre = {
            str(tipo): count for tipo, count in tipo_sangre_result.all()
        }
        
        edad_promedio_result = await db.execute(select(func.avg(Persona.edad)))
        edad_promedio = edad_promedio_result.scalar() or 0
        
        return {
            "total_personas": total,
            "distribucion_tipo_sangre": distribucion_sangre,
            "edad_promedio": round(edad_promedio, 2)
        }
