import pytest
import pytest_mock
from twd_hub.application.services.database_initializer import (
    DatabaseInitializer,
)
from twd_hub.domain.models.episode import EpisodeBase
from twd_hub.domain.models.episode_page import EpisodePage

import unittest.mock


@pytest.fixture(name="episode_page_scraper")
def create_episode_page_scraper_mock(
    mocker: pytest_mock.MockerFixture,
    request: pytest.FixtureRequest,
) -> unittest.mock.Mock:
    return_values: dict[str, EpisodePage] = request.param

    async def side_effect(
        url: str, wait_until_selector: str | None
    ) -> EpisodePage:
        episode_page = return_values.get(url)
        if episode_page is None:
            assert False, f"not handled {url}"
        return episode_page

    mock = mocker.Mock()
    mock.scrape = mocker.AsyncMock(side_effect=side_effect)
    return mock


class MockedDatabaseInitializer(DatabaseInitializer):
    episode_page_scraper: unittest.mock.Mock  # pyright: ignore[reportIncompatibleVariableOverride]
    episode_repository: unittest.mock.Mock  # pyright: ignore[reportIncompatibleVariableOverride]
    entity_repository: unittest.mock.Mock  # pyright: ignore[reportIncompatibleVariableOverride]
    appearance_repository: unittest.mock.Mock  # pyright: ignore[reportIncompatibleVariableOverride]
    appearance_form_repository: unittest.mock.Mock  # pyright: ignore[reportIncompatibleVariableOverride]


@pytest.fixture(name="db_initializer")
def create_database_initializer(
    mocker: pytest_mock.MockerFixture,
    episode_page_scraper: unittest.mock.Mock,
) -> MockedDatabaseInitializer:
    episode_repository = mocker.Mock()
    episode_repository.update_all = mocker.AsyncMock()

    entity_repository = mocker.Mock()
    entity_repository.update_all = mocker.AsyncMock()

    appearance_repository = mocker.Mock()
    appearance_repository.update_all = mocker.AsyncMock()

    appearance_form_repository = mocker.Mock()
    appearance_form_repository.update_all = mocker.AsyncMock()

    return MockedDatabaseInitializer(
        episode_page_scraper=episode_page_scraper,
        episode_repository=episode_repository,
        entity_repository=entity_repository,
        appearance_repository=appearance_repository,
        appearance_form_repository=appearance_form_repository,
    )


@pytest.mark.parametrize(
    "episode_page_scraper",
    [
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
        }
    ],
    indirect=True,
)
@pytest.mark.asyncio
async def test__import_single_episode_by_load_until_parameter(
    db_initializer: MockedDatabaseInitializer,
) -> None:
    await db_initializer.run(
        initial_page_href="/wiki/Days_Gone_Bye_(TV_Series)", load_until=(1, 1)
    )
    db_initializer.episode_page_scraper.scrape.assert_called_once()
    db_initializer.episode_repository.update_all.assert_called_once_with(
        [
            EpisodeBase(
                name="Days Gone Bye",
                season_number=1,
                episode_number=1,
                wiki_href="/wiki/Days_Gone_Bye_(TV_Series)",
            )
        ]
    )
    db_initializer.entity_repository.update_all.assert_called_once_with([])
    db_initializer.appearance_repository.update_all.assert_called_once_with([])
    db_initializer.appearance_form_repository.update_all.assert_called_once_with(
        []
    )


@pytest.mark.parametrize(
    "episode_page_scraper",
    [
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
        }
    ],
    indirect=True,
)
@pytest.mark.asyncio
async def test__import_single_episode_by_next_page_href_field(
    db_initializer: MockedDatabaseInitializer,
) -> None:
    await db_initializer.run(initial_page_href="/wiki/TS-19", load_until=None)
    db_initializer.episode_page_scraper.scrape.assert_called_once()
    db_initializer.episode_repository.update_all.assert_called_once_with(
        [
            EpisodeBase(
                name="TS-19",
                season_number=1,
                episode_number=6,
                wiki_href="/wiki/TS-19",
            )
        ]
    )
    db_initializer.entity_repository.update_all.assert_called_once_with([])
    db_initializer.appearance_repository.update_all.assert_called_once_with([])
    db_initializer.appearance_form_repository.update_all.assert_called_once_with(
        []
    )


@pytest.mark.parametrize(
    "episode_page_scraper",
    [
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
        }
    ],
    indirect=True,
)
@pytest.mark.asyncio
async def test__import_multiple_episodes_by_load_until_parameter(
    db_initializer: MockedDatabaseInitializer,
) -> None:
    await db_initializer.run(
        initial_page_href="/wiki/Days_Gone_Bye_(TV_Series)", load_until=(1, 3)
    )
    assert db_initializer.episode_page_scraper.scrape.call_count == 3
    db_initializer.episode_repository.update_all.assert_called_once_with(
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
    db_initializer.entity_repository.update_all.assert_called_once_with([])
    db_initializer.appearance_repository.update_all.assert_called_once_with([])
    db_initializer.appearance_form_repository.update_all.assert_called_once_with(
        []
    )


@pytest.mark.parametrize(
    "episode_page_scraper",
    [
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
        }
    ],
    indirect=True,
)
@pytest.mark.asyncio
async def test__import_multiple_episodes_by_next_page_href_field(
    db_initializer: MockedDatabaseInitializer,
) -> None:
    await db_initializer.run(initial_page_href="/wiki/Vatos", load_until=None)
    assert db_initializer.episode_page_scraper.scrape.call_count == 3
    db_initializer.episode_repository.update_all.assert_called_once_with(
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
    db_initializer.entity_repository.update_all.assert_called_once_with([])
    db_initializer.appearance_repository.update_all.assert_called_once_with([])
    db_initializer.appearance_form_repository.update_all.assert_called_once_with(
        []
    )
