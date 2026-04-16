import pytest
import pytest_mock
from twd_hub.application.services.database_initializer import (
    DatabaseInitializer,
)
from twd_hub.application.services.episode_page_scraper import EpisodePageScraper
from twd_hub.domain.interfaces.appearance_form_repository import (
    AppearanceFormRepository,
)
from twd_hub.domain.interfaces.appearance_repository import AppearanceRepository
from twd_hub.domain.interfaces.episode_repository import EpisodeRepository
from twd_hub.domain.models.episode import EpisodeBase
from twd_hub.domain.models.episode_page import EpisodePage


def episode_page_scraper__scrape__mock(
    mocker: pytest_mock.MockerFixture,
    params: dict[str, EpisodePage],
):
    async def side_effect(
        url: str, wait_until_selector: str | None
    ) -> EpisodePage:
        episode_page = params.get(url)
        if episode_page is None:
            assert False, f"not handled {url}"
        return episode_page

    return mocker.AsyncMock(side_effect=side_effect)


@pytest.mark.asyncio
async def test__import_single_episode_by_load_until_parameter(
    mocker: pytest_mock.MockerFixture,
) -> None:
    episode_page_scraper = mocker.Mock()
    episode_page_scraper.scrape = episode_page_scraper__scrape__mock(
        mocker,
        {
            "https://walkingdead.fandom.com/wiki/Days_Gone_Bye_(TV_Series)": EpisodePage(
                episode=EpisodeBase(
                    name="Days Gone Bye",
                    season_number=1,
                    episode_number=1,
                    wiki_href="/wiki/Days_Gone_Bye_(TV_Series)",
                ),
                entity_appearances=[],
                next_page_href="/wiki/Guts",
            ),
        },
    )

    episode_repository = mocker.Mock()
    episode_repository.update_all = mocker.AsyncMock()

    entity_repository = mocker.Mock()
    entity_repository.update_all = mocker.AsyncMock()

    appearance_repository = mocker.Mock()
    appearance_repository.update_all = mocker.AsyncMock()

    appearance_form_repository = mocker.Mock()
    appearance_form_repository.update_all = mocker.AsyncMock()

    initializer = DatabaseInitializer(
        episode_page_scraper=episode_page_scraper,
        episode_repository=episode_repository,
        entity_repository=entity_repository,
        appearance_repository=appearance_repository,
        appearance_form_repository=appearance_form_repository,
    )
    await initializer.run(
        initial_page_href="/wiki/Days_Gone_Bye_(TV_Series)", load_until=(1, 1)
    )
    episode_page_scraper.scrape.assert_called_once()
    episode_repository.update_all.assert_called_once_with(
        [
            EpisodeBase(
                name="Days Gone Bye",
                season_number=1,
                episode_number=1,
                wiki_href="/wiki/Days_Gone_Bye_(TV_Series)",
            )
        ]
    )
    entity_repository.update_all.assert_called_once_with([])
    appearance_repository.update_all.assert_called_once_with([])
    appearance_form_repository.update_all.assert_called_once_with([])


@pytest.mark.asyncio
async def test__import_single_episode_by_next_page_href_field(
    mocker: pytest_mock.MockerFixture,
) -> None:
    episode_page_scraper = mocker.Mock()
    episode_page_scraper.scrape = episode_page_scraper__scrape__mock(
        mocker,
        {
            "https://walkingdead.fandom.com/wiki/TS-19": EpisodePage(
                episode=EpisodeBase(
                    name="TS-19",
                    season_number=1,
                    episode_number=6,
                    wiki_href="/wiki/TS-19",
                ),
                entity_appearances=[],
                next_page_href=None,
            ),
        },
    )

    episode_repository = mocker.Mock()
    episode_repository.update_all = mocker.AsyncMock()

    entity_repository = mocker.Mock()
    entity_repository.update_all = mocker.AsyncMock()

    appearance_repository = mocker.Mock()
    appearance_repository.update_all = mocker.AsyncMock()

    appearance_form_repository = mocker.Mock()
    appearance_form_repository.update_all = mocker.AsyncMock()

    initializer = DatabaseInitializer(
        episode_page_scraper=episode_page_scraper,
        episode_repository=episode_repository,
        entity_repository=entity_repository,
        appearance_repository=appearance_repository,
        appearance_form_repository=appearance_form_repository,
    )
    await initializer.run(initial_page_href="/wiki/TS-19", load_until=None)
    episode_page_scraper.scrape.assert_called_once()
    episode_repository.update_all.assert_called_once_with(
        [
            EpisodeBase(
                name="TS-19",
                season_number=1,
                episode_number=6,
                wiki_href="/wiki/TS-19",
            )
        ]
    )
    entity_repository.update_all.assert_called_once_with([])
    appearance_repository.update_all.assert_called_once_with([])
    appearance_form_repository.update_all.assert_called_once_with([])


@pytest.mark.asyncio
async def test__import_multiple_episodes_by_load_until_parameter(
    mocker: pytest_mock.MockerFixture,
) -> None:
    episode_page_scraper = mocker.Mock()
    episode_page_scraper.scrape = episode_page_scraper__scrape__mock(
        mocker,
        {
            "https://walkingdead.fandom.com/wiki/Days_Gone_Bye_(TV_Series)": EpisodePage(
                episode=EpisodeBase(
                    name="Days Gone Bye",
                    season_number=1,
                    episode_number=1,
                    wiki_href="/wiki/Days_Gone_Bye_(TV_Series)",
                ),
                entity_appearances=[],
                next_page_href="/wiki/Guts",
            ),
            "https://walkingdead.fandom.com/wiki/Guts": EpisodePage(
                episode=EpisodeBase(
                    name="Guts",
                    season_number=1,
                    episode_number=2,
                    wiki_href="/wiki/Guts",
                ),
                entity_appearances=[],
                next_page_href="/wiki/Tell_It_to_the_Frogs",
            ),
            "https://walkingdead.fandom.com/wiki/Tell_It_to_the_Frogs": EpisodePage(
                episode=EpisodeBase(
                    name="Tell It to the Frogs",
                    season_number=1,
                    episode_number=3,
                    wiki_href="/wiki/Tell_It_to_the_Frogs",
                ),
                entity_appearances=[],
                next_page_href="/wiki/Vatos",
            ),
        },
    )

    episode_repository = mocker.Mock()
    episode_repository.update_all = mocker.AsyncMock()

    entity_repository = mocker.Mock()
    entity_repository.update_all = mocker.AsyncMock()

    appearance_repository = mocker.Mock()
    appearance_repository.update_all = mocker.AsyncMock()

    appearance_form_repository = mocker.Mock()
    appearance_form_repository.update_all = mocker.AsyncMock()

    initializer = DatabaseInitializer(
        episode_page_scraper=episode_page_scraper,
        episode_repository=episode_repository,
        entity_repository=entity_repository,
        appearance_repository=appearance_repository,
        appearance_form_repository=appearance_form_repository,
    )
    await initializer.run(
        initial_page_href="/wiki/Days_Gone_Bye_(TV_Series)", load_until=(1, 3)
    )
    assert episode_page_scraper.scrape.call_count == 3
    episode_repository.update_all.assert_called_once_with(
        [
            EpisodeBase(
                name="Days Gone Bye",
                season_number=1,
                episode_number=1,
                wiki_href="/wiki/Days_Gone_Bye_(TV_Series)",
            ),
            EpisodeBase(
                name="Guts",
                season_number=1,
                episode_number=2,
                wiki_href="/wiki/Guts",
            ),
            EpisodeBase(
                name="Tell It to the Frogs",
                season_number=1,
                episode_number=3,
                wiki_href="/wiki/Tell_It_to_the_Frogs",
            ),
        ]
    )
    entity_repository.update_all.assert_called_once_with([])
    appearance_repository.update_all.assert_called_once_with([])
    appearance_form_repository.update_all.assert_called_once_with([])


@pytest.mark.asyncio
async def test__import_multiple_episodes_by_next_page_href_field(
    mocker: pytest_mock.MockerFixture,
) -> None:
    episode_page_scraper = mocker.Mock()
    episode_page_scraper.scrape = episode_page_scraper__scrape__mock(
        mocker,
        {
            "https://walkingdead.fandom.com/wiki/Vatos": EpisodePage(
                episode=EpisodeBase(
                    name="Vatos",
                    season_number=1,
                    episode_number=4,
                    wiki_href="/wiki/Vatos",
                ),
                entity_appearances=[],
                next_page_href="/wiki/Wildfire",
            ),
            "https://walkingdead.fandom.com/wiki/Wildfire": EpisodePage(
                episode=EpisodeBase(
                    name="Wildfire",
                    season_number=1,
                    episode_number=5,
                    wiki_href="/wiki/Wildfire",
                ),
                entity_appearances=[],
                next_page_href="/wiki/TS-19",
            ),
            "https://walkingdead.fandom.com/wiki/TS-19": EpisodePage(
                episode=EpisodeBase(
                    name="TS-19",
                    season_number=1,
                    episode_number=6,
                    wiki_href="/wiki/TS-19",
                ),
                entity_appearances=[],
                next_page_href=None,
            ),
        },
    )

    episode_repository = mocker.Mock()
    episode_repository.update_all = mocker.AsyncMock()

    entity_repository = mocker.Mock()
    entity_repository.update_all = mocker.AsyncMock()

    appearance_repository = mocker.Mock()
    appearance_repository.update_all = mocker.AsyncMock()

    appearance_form_repository = mocker.Mock()
    appearance_form_repository.update_all = mocker.AsyncMock()

    initializer = DatabaseInitializer(
        episode_page_scraper=episode_page_scraper,
        episode_repository=episode_repository,
        entity_repository=entity_repository,
        appearance_repository=appearance_repository,
        appearance_form_repository=appearance_form_repository,
    )
    await initializer.run(initial_page_href="/wiki/Vatos", load_until=None)
    assert episode_page_scraper.scrape.call_count == 3
    episode_repository.update_all.assert_called_once_with(
        [
            EpisodeBase(
                name="Vatos",
                season_number=1,
                episode_number=4,
                wiki_href="/wiki/Vatos",
            ),
            EpisodeBase(
                name="Wildfire",
                season_number=1,
                episode_number=5,
                wiki_href="/wiki/Wildfire",
            ),
            EpisodeBase(
                name="TS-19",
                season_number=1,
                episode_number=6,
                wiki_href="/wiki/TS-19",
            ),
        ]
    )
    entity_repository.update_all.assert_called_once_with([])
    appearance_repository.update_all.assert_called_once_with([])
    appearance_form_repository.update_all.assert_called_once_with([])
