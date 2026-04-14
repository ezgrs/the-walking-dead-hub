import asyncio
from logging.config import fileConfig
import sys

from sqlalchemy.engine import Connection
import sqlalchemy.ext.asyncio

from alembic import context
import sqlmodel

from twd_hub.domain.models.settings import Settings
from twd_hub.infrastructure.db.session import create_engine
from twd_hub.infrastructure.db.models.appearance import *
from twd_hub.infrastructure.db.models.appearance_form import *
from twd_hub.infrastructure.db.models.appearance_form_type import *
from twd_hub.infrastructure.db.models.appearance_form_type_alias import *
from twd_hub.infrastructure.db.models.appearance_type import *
from twd_hub.infrastructure.db.models.appearance_type_alias import *
from twd_hub.infrastructure.db.models.entity import *
from twd_hub.infrastructure.db.models.episode import *

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
# This line sets up loggers basically.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# add your model's MetaData object here
# for 'autogenerate' support
# from myapp import mymodel
# target_metadata = mymodel.Base.metadata
target_metadata = sqlmodel.SQLModel.metadata

# other values from the config, defined by the needs of env.py,
# can be acquired:
# my_important_option = config.get_main_option("my_important_option")
# ... etc.


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    This configures the context with just a URL
    and not an Engine, though an Engine is acceptable
    here as well.  By skipping the Engine creation
    we don't even need a DBAPI to be available.

    Calls to context.execute() here emit the given string to the
    script output.

    """
    settings = Settings() # pyright: ignore[reportCallIssue]
    url = (
        f'{settings.database_driver}://'
        f'{settings.database_username}:{settings.database_password}@'
        f'{settings.database_host}:{settings.database_port}/'
        f'{settings.database_name}'
    )
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={'paramstyle': 'named'},
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()

def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()

async def run_async_migrations() -> None:
    """In this scenario we need to create an Engine
    and associate a connection with the context.
    """
    settings = Settings() # pyright: ignore[reportCallIssue]
    engine: sqlalchemy.ext.asyncio.AsyncEngine
    engine = create_engine(settings)
    async with engine.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await engine.dispose()

def run_migrations_online() -> None:
    """Run migrations in 'online' mode.

    In this scenario we need to create an Engine
    and associate a connection with the context.

    """
    connection = config.attributes.get('connection', None)
    if connection is None:
        if sys.platform == 'win32':
            asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
        asyncio.run(run_async_migrations())
    else:
        do_run_migrations(connection)


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
