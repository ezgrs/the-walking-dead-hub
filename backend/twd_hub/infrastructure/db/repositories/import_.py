import typing

import sqlmodel
import sqlmodel.ext.asyncio.session


from twd_hub.domain.services.episode_page_loader import EpisodeLoader
from twd_hub.domain.interfaces.import_repository import (
    ImportRepository as BaseImportRepository,
)

from twd_hub.domain.models import EpisodePage
from twd_hub.infrastructure.db.models.episode import EpisodeModel
from twd_hub.infrastructure.db.models.entity import EntityModel
from twd_hub.infrastructure.db.models.appearance import AppearanceModel
from twd_hub.infrastructure.db.models.appearance_form import (
    AppearanceFormModel,
)


class Upsert[
    Model: sqlmodel.SQLModel,
    Id: object,
    Key,
]:
    @staticmethod
    async def of[
        M: sqlmodel.SQLModel,
        I: object,
        K,
    ](
        session: sqlmodel.ext.asyncio.session.AsyncSession,
        model: type[M],
        *,
        on_id: typing.Callable[[M], I | None],
        on_key: typing.Callable[[M], K],
    ) -> "Upsert[M, I, K]":
        return Upsert(
            session=session,
            model=model,
            mapping={
                on_key(model): model
                for model in await session.exec(sqlmodel.select(model))
            },
            on_id=on_id,
            on_key=on_key,
        )

    session: sqlmodel.ext.asyncio.session.AsyncSession
    model: type[Model]
    on_id: typing.Callable[[Model], Id | None]
    on_key: typing.Callable[[Model], Key]
    mapping: dict[Key, Model]

    def __init__(
        self,
        *,
        session: sqlmodel.ext.asyncio.session.AsyncSession,
        model: type[Model],
        mapping: dict[Key, Model],
        on_id: typing.Callable[[Model], Id | None],
        on_key: typing.Callable[[Model], Key],
    ) -> None:
        self.session = session
        self.model = model
        self.mapping = mapping
        self.on_id = on_id
        self.on_key = on_key

    async def get_or_insert(
        self,
        key: Key,
        *,
        on_insert: typing.Callable[[], Model],
    ) -> tuple[Id, Model]:
        model = self.mapping.get(key)
        if model is None:
            model = on_insert()
            self.session.add(model)
            await self.session.flush()
            self.mapping[key] = model

        model_id = self.on_id(model)
        assert model_id is not None
        return model_id, model


class ImportRepository(BaseImportRepository):
    session: sqlmodel.ext.asyncio.session.AsyncSession

    def __init__(
        self, session: sqlmodel.ext.asyncio.session.AsyncSession
    ) -> None:
        self.session = session

    @typing.override
    async def import_data(
        self,
        *,
        loader: EpisodeLoader,
    ) -> None:
        episode_upsert = await Upsert.of(
            self.session,
            EpisodeModel,
            on_id=lambda episode: episode.id,
            on_key=lambda episode: episode.wiki_href,
        )
        entity_upsert = await Upsert.of(
            self.session,
            EntityModel,
            on_id=lambda entity: entity.id,
            on_key=lambda entity: entity.wiki_href,
        )
        appearance_upsert = await Upsert.of(
            self.session,
            AppearanceModel,
            on_id=lambda appearance: appearance.id,
            on_key=lambda appearance: (
                appearance.entity_id,
                appearance.episode_id,
            ),
        )
        appearance_form_upsert = await Upsert.of(
            self.session,
            AppearanceFormModel,
            on_id=lambda appearance_form: appearance_form.id,
            on_key=lambda appearance_form: appearance_form.appearance_id,
        )

        current_episode: EpisodePage | None = None
        while current_episode is None or (
            current_episode.season_number,
            current_episode.episode_number,
        ) < (7, 16):
            href: str
            if current_episode is None:
                href = "/wiki/Days_Gone_Bye_(TV_Series)"
            else:
                href = current_episode.next_page_href

            episode_page = await loader.load(href)
            episode_model_id, _ = await episode_upsert.get_or_insert(
                href,
                on_insert=lambda: EpisodeModel(
                    id=None,
                    name=episode_page.title,
                    wiki_href=episode_page.href,
                    season_number=episode_page.season_number,
                    episode_number=episode_page.episode_number,
                ),
            )

            for entity_appearance in episode_page.entity_appearances:
                entity_page_href = entity_appearance.entity_page_href
                entity_model_id, _ = await entity_upsert.get_or_insert(
                    entity_page_href,
                    on_insert=lambda: EntityModel(
                        id=None,
                        name=entity_appearance.entity_name,
                        wiki_href=entity_page_href,
                    ),
                )

                appearance_model_id, _ = await appearance_upsert.get_or_insert(
                    (entity_model_id, episode_model_id),
                    on_insert=lambda: AppearanceModel(
                        id=None,
                        episode_id=episode_model_id,
                        entity_id=entity_model_id,
                        type_id=entity_appearance.appearance_type_id,
                    ),
                )

                for (
                    appearance_form_type_id
                ) in entity_appearance.appearance_form_types_ids:
                    await appearance_form_upsert.get_or_insert(
                        appearance_model_id,
                        on_insert=lambda: AppearanceFormModel(
                            id=None,
                            appearance_id=appearance_model_id,
                            type_id=appearance_form_type_id,
                        ),
                    )

            current_episode = episode_page
        await self.session.commit()
