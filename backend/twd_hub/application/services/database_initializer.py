import typing
from twd_hub.application.services.episode_page_scraper import (
    EpisodePageScraper,
)
from twd_hub.domain.interfaces.appearance_form_repository import (
    AppearanceFormRepository,
)
from twd_hub.domain.interfaces.appearance_repository import AppearanceRepository
from twd_hub.domain.interfaces.entity_repository import EntityRepository
from twd_hub.domain.interfaces.episode_repository import EpisodeRepository
from twd_hub.domain.models.entity import EntityBase
from twd_hub.domain.models.entity_appearance import EntityAppearance
from twd_hub.domain.models.episode import EpisodeBase
from twd_hub.domain.models.episode_page import EpisodePage


class DatabaseInitializer:
    episode_page_scraper: EpisodePageScraper
    episode_repository: EpisodeRepository
    entity_repository: EntityRepository
    appearance_repository: AppearanceRepository
    appearance_form_repository: AppearanceFormRepository

    def __init__(
        self,
        *,
        episode_page_scraper: EpisodePageScraper,
        episode_repository: EpisodeRepository,
        entity_repository: EntityRepository,
        appearance_repository: AppearanceRepository,
        appearance_form_repository: AppearanceFormRepository,
    ) -> None:
        self.episode_page_scraper = episode_page_scraper
        self.episode_repository = episode_repository
        self.entity_repository = entity_repository
        self.appearance_repository = appearance_repository
        self.appearance_form_repository = appearance_form_repository

    async def run(
        self,
        *,
        initial_page_href: str,
        load_until: typing.Optional[tuple[int, int]],
    ) -> None:
        episodes_mapping: dict[str, list[EpisodeBase]] = {}
        entities_mapping: dict[str, dict[str, list[EntityAppearance]]] = {}

        analyzed_page: EpisodePage | None = None
        while True:
            href: str
            if analyzed_page is None:
                href = initial_page_href
            else:
                if load_until is not None and (
                    (analyzed_page.episode.season_number,
                    analyzed_page.episode.episode_number)
                    >= load_until
                ):
                    break

                next_page_href = analyzed_page.next_page_href 
                if next_page_href is None:
                    break
                href = next_page_href

            current_page = await self.episode_page_scraper.scrape(
                f"https://walkingdead.fandom.com{href}",
                wait_until_selector="#Trivia",
            )
            episodes_mapping.setdefault(
                current_page.episode.wiki_href, []
            ).append(current_page.episode)

            for entity_appearance in current_page.entity_appearances:
                entities_mapping.setdefault(
                    entity_appearance.entity_page_href,
                    {},
                ).setdefault(entity_appearance.entity_name, []).append(
                    EntityAppearance(
                        episode_page_href=href,
                        entity_page_href=entity_appearance.entity_page_href,
                        entity_page_title=entity_appearance.entity_page_title,
                        entity_name=entity_appearance.entity_name,
                        appearance_type_id=entity_appearance.appearance_type_id,
                        appearance_form_types_ids=entity_appearance.appearance_form_types_ids,
                    )
                )

            analyzed_page = current_page

        # Update all episodes
        episodes: list[EpisodeBase] = []
        for episode_wiki_href, episodes_ in episodes_mapping.items():
            if len(episodes_) != 1:
                raise RuntimeError(
                    f"the following episodes have the same HREF ({episode_wiki_href}): {episodes_}"
                )
            (episode,) = episodes_
            episodes.append(episode)

        # Update all entities
        entities: list[EntityBase] = []
        appearances: list[EntityAppearance] = []
        for entity_wiki_href, entities_data_mapping in entities_mapping.items():
            entities_data_items = entities_data_mapping.items()
            if len(entities_data_items) != 1:
                raise RuntimeError(
                    f"the following entities have the same HREF ({entity_wiki_href}): "
                    + ", ".join(
                        entity_name for entity_name, _ in entities_data_items
                    )
                )
            ((entity_name, entity_appearances),) = entities_data_items
            entities.append(
                EntityBase(
                    name=entity_name,
                    wiki_href=entity_wiki_href,
                )
            )
            appearances.extend(entity_appearances)

        await self.episode_repository.update_all(episodes)
        await self.entity_repository.update_all(entities)
        await self.appearance_repository.update_all(appearances)
        await self.appearance_form_repository.update_all(appearances)
