"""Initial migration

Revision ID: 001
Revises: 
Create Date: 2024-10-27 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Crear tabla personas
    op.create_table(
        'personas',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('nombre', sa.String(length=100), nullable=False),
        sa.Column('apellido', sa.String(length=100), nullable=False),
        sa.Column('edad', sa.Integer(), nullable=False),
        sa.Column('correo', sa.String(length=255), nullable=False),
        sa.Column('tipo_sangre', sa.Enum('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', name='tiposangre'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('correo')
    )
    op.create_index(op.f('ix_personas_id'), 'personas', ['id'], unique=False)
    op.create_index(op.f('ix_personas_correo'), 'personas', ['correo'], unique=True)

    # Crear tabla historial_cargas
    op.create_table(
        'historial_cargas',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('nombre_archivo', sa.String(length=255), nullable=False),
        sa.Column('total_registros', sa.Integer(), nullable=False),
        sa.Column('registros_exitosos', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('registros_duplicados', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('registros_error', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('fue_asincrono', sa.Boolean(), nullable=True, server_default='0'),
        sa.Column('task_id', sa.String(length=255), nullable=True),
        sa.Column('estado', sa.String(length=50), nullable=False),
        sa.Column('detalles_duplicados', sa.JSON(), nullable=True),
        sa.Column('detalles_errores', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_historial_cargas_id'), 'historial_cargas', ['id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_historial_cargas_id'), table_name='historial_cargas')
    op.drop_table('historial_cargas')
    op.drop_index(op.f('ix_personas_correo'), table_name='personas')
    op.drop_index(op.f('ix_personas_id'), table_name='personas')
    op.drop_table('personas')
    op.execute("DROP TYPE IF EXISTS tiposangre")