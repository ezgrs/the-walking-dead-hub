import typing

import sqlmodel
import sqlmodel.ext.asyncio.session


from twd_life_tracker.domain.interfaces.import_repository import (
    ImportRepository as BaseImportRepository,
)

from twd_life_tracker.domain.models import EpisodePage
from twd_life_tracker.domain.services.page_loader import PageLoader
from twd_life_tracker.domain.services.tag_parser import TagParser
from twd_life_tracker.infrastructure.db.models.episode import EpisodeModel
from twd_life_tracker.infrastructure.db.models.entity import EntityModel
from twd_life_tracker.infrastructure.db.models.appearance import AppearanceModel
from twd_life_tracker.infrastructure.db.models.appearance_form import (
    AppearanceFormModel,
)


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
        page_loader: PageLoader,
        tag_parser: TagParser[EpisodePage],
    ) -> None:
        entities_mapping: dict[str, EntityModel] = {}
        async with page_loader:
            episode: EpisodePage | None = None
            while episode is None or (
                episode.season_number,
                episode.episode_number,
            ) < (7, 16):
                href: str
                if episode is None:
                    href = "/wiki/Days_Gone_Bye_(TV_Series)"
                else:
                    href = episode.next_page_href

                episode_page_tag = await page_loader.load(href)
                episode = await tag_parser.parse(episode_page_tag)
                episode_model = EpisodeModel(
                    id=None,
                    name=episode.title,
                    wiki_href=episode.href,
                    season_number=episode.season_number,
                    episode_number=episode.episode_number,
                )
                self.session.add(episode_model)
                await self.session.flush()

                episode_model_id = episode_model.id
                assert episode_model_id is not None

                for entity_appearance in episode.entity_appearances:
                    entity_page_href = entity_appearance.entity_page_href
                    entity_model = entities_mapping.get(entity_page_href)
                    if entity_model is None:
                        entity_model = EntityModel(
                            id=None,
                            name=entity_appearance.entity_name,
                            wiki_href=entity_page_href,
                        )
                        self.session.add(entity_model)
                        await self.session.flush()

                    entity_model_id = entity_model.id
                    assert entity_model_id is not None

                    appearance_model = AppearanceModel(
                        id=None,
                        episode_id=episode_model_id,
                        entity_id=entity_model_id,
                        type_id=entity_appearance.appearance_type_id,
                    )
                    self.session.add(appearance_model)
                    await self.session.flush()

                    appearance_model_id = appearance_model.id
                    assert appearance_model_id is not None

                    for (
                        appearance_form_type_id
                    ) in entity_appearance.appearance_form_types_ids:
                        self.session.add(
                            AppearanceFormModel(
                                id=None,
                                appearance_id=appearance_model_id,
                                type_id=appearance_form_type_id,
                            )
                        )
        await self.session.commit()
