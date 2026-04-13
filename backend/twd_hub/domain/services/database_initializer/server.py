import typing
from twd_hub.domain.interfaces import Upsert
from twd_hub.domain.interfaces.appearance_form_repository import (
    AppearanceFormRepository,
)
from twd_hub.domain.interfaces.appearance_repository import AppearanceRepository
from twd_hub.domain.interfaces.entity_repository import EntityRepository
from twd_hub.domain.interfaces.episode_repository import EpisodeRepository
from twd_hub.domain.models import EpisodePage
from twd_hub.domain.models.appearance import AppearanceBase
from twd_hub.domain.models.appearance_form import AppearanceFormBase
from twd_hub.domain.models.entity import EntityBase
from twd_hub.domain.models.episode import EpisodeBase
from twd_hub.domain.services.database_initializer import (
    DatabaseInitializer as BaseDatabaseInitializer,
)
from twd_hub.domain.services.episode_page_loader import EpisodeLoader


class DatabaseInitializer(BaseDatabaseInitializer):
    loader: EpisodeLoader
    episode_repository: EpisodeRepository
    entity_repository: EntityRepository
    appearance_repository: AppearanceRepository
    appearance_form_repository: AppearanceFormRepository

    def __init__(
        self,
        *,
        loader: EpisodeLoader,
        episode_repository: EpisodeRepository,
        entity_repository: EntityRepository,
        appearance_repository: AppearanceRepository,
        appearance_form_repository: AppearanceFormRepository,
    ) -> None:
        self.loader = loader
        self.episode_repository = episode_repository
        self.entity_repository = entity_repository
        self.appearance_repository = appearance_repository
        self.appearance_form_repository = appearance_form_repository

    @typing.override
    async def run(
        self, initial_page_href: str, *, until: typing.Optional[tuple[int, int]]
    ) -> None:
        episode_upsert = await Upsert.of(
            self.episode_repository,
            on_id=lambda episode: episode.id,
            on_key=lambda episode: episode.wiki_href,
        )
        entity_upsert = await Upsert.of(
            self.entity_repository,
            on_id=lambda entity: entity.id,
            on_key=lambda entity: entity.wiki_href,
        )
        appearance_upsert = await Upsert.of(
            self.appearance_repository,
            on_id=lambda appearance: appearance.id,
            on_key=lambda appearance: (
                appearance.entity_id,
                appearance.episode_id,
            ),
        )
        appearance_form_upsert = await Upsert.of(
            self.appearance_form_repository,
            on_id=lambda appearance_form: appearance_form.id,
            on_key=lambda appearance_form: appearance_form.appearance_id,
        )

        current_episode: EpisodePage | None = None
        while current_episode is None or (
            until is not None
            and (current_episode.season_number, current_episode.episode_number)
            < until
        ):
            href: str
            if current_episode is None:
                href = initial_page_href
            else:
                href = current_episode.next_page_href

            episode_page = await self.loader.load(href)
            episode_model_id, _ = await episode_upsert.get_or_insert(
                href,
                on_insert=lambda: EpisodeBase(
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
                    on_insert=lambda: EntityBase(
                        name=entity_appearance.entity_name,
                        wiki_href=entity_page_href,
                    ),
                )

                appearance_model_id, _ = await appearance_upsert.get_or_insert(
                    (entity_model_id, episode_model_id),
                    on_insert=lambda: AppearanceBase(
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
                        on_insert=lambda: AppearanceFormBase(
                            appearance_id=appearance_model_id,
                            type_id=appearance_form_type_id,
                        ),
                    )

            current_episode = episode_page
