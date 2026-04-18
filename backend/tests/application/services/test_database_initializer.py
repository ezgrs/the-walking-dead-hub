import pytest
import pytest_mock
from twd_hub.application.services.database_initializer import (
    DatabaseInitializer,
)
from twd_hub.domain.models.entity import EntityBase
from twd_hub.domain.models.entity_appearance import (
    EntityAppearance,
    EntityAppearanceBase,
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


class _Mock(unittest.mock.Mock):
    def __getattribute__(self, name: str) -> unittest.mock.AsyncMock:
        return super().__getattribute__(name)


class MockedDatabaseInitializer(DatabaseInitializer):
    episode_page_scraper: _Mock  # pyright: ignore[reportIncompatibleVariableOverride]
    episode_repository: _Mock  # pyright: ignore[reportIncompatibleVariableOverride]
    entity_repository: _Mock  # pyright: ignore[reportIncompatibleVariableOverride]
    appearance_repository: _Mock  # pyright: ignore[reportIncompatibleVariableOverride]
    appearance_form_repository: _Mock  # pyright: ignore[reportIncompatibleVariableOverride]


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
    db_initializer.episode_page_scraper.scrape.assert_has_calls(
        [
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Days_Gone_Bye_(TV_Series)",
                wait_until_selector="#Trivia",
            ),
        ]
    )
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
    db_initializer.episode_page_scraper.scrape.assert_has_calls(
        [
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/TS-19",
                wait_until_selector="#Trivia",
            ),
        ]
    )
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
    db_initializer.episode_page_scraper.scrape.assert_has_calls(
        [
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Days_Gone_Bye_(TV_Series)",
                wait_until_selector="#Trivia",
            ),
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Guts",
                wait_until_selector="#Trivia",
            ),
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Tell_It_to_the_Frogs",
                wait_until_selector="#Trivia",
            ),
        ]
    )
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
    db_initializer.episode_page_scraper.scrape.assert_has_calls(
        [
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Vatos",
                wait_until_selector="#Trivia",
            ),
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Wildfire",
                wait_until_selector="#Trivia",
            ),
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/TS-19",
                wait_until_selector="#Trivia",
            ),
        ]
    )
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
                next_page_href="/wiki/TS-20",
            ),
            "https://walkingdead.fandom.com/wiki/TS-20": EpisodePage(
                episode=EpisodeBase(
                    name="TS-20",
                    season_number=1,
                    episode_number=7,
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
async def test__import_same_episode__with_conflict(
    db_initializer: MockedDatabaseInitializer,
) -> None:
    with pytest.raises(
        RuntimeError,
        match="the following episodes have the same HREF \\(/wiki/TS-19\\): TS-19, TS-20",
    ):
        await db_initializer.run(
            initial_page_href="/wiki/TS-19", load_until=None
        )
    db_initializer.episode_page_scraper.scrape.assert_has_calls(
        [
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/TS-19",
                wait_until_selector="#Trivia",
            ),
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/TS-20",
                wait_until_selector="#Trivia",
            ),
        ]
    )
    db_initializer.episode_repository.update_all.assert_not_called()
    db_initializer.entity_repository.update_all.assert_not_called()
    db_initializer.appearance_repository.update_all.assert_not_called()
    db_initializer.appearance_form_repository.update_all.assert_not_called()


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
                entity_appearances=[
                    EntityAppearanceBase(
                        entity_name="Rick Grimes",
                        entity_page_href="/wiki/Rick_Grimes_(TV_Universe)",
                        entity_page_title="Rick Grimes (TV Universe)",
                        appearance_type_id=0,
                        appearance_form_types_ids=[1],
                    ),
                ],
                next_page_href=None,
            ),
        }
    ],
    indirect=True,
)
@pytest.mark.asyncio
async def test__import_one_entity_by_one_episode(
    db_initializer: MockedDatabaseInitializer,
) -> None:
    await db_initializer.run(
        initial_page_href="/wiki/Days_Gone_Bye_(TV_Series)", load_until=None
    )
    db_initializer.episode_page_scraper.scrape.assert_has_calls(
        [
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Days_Gone_Bye_(TV_Series)",
                wait_until_selector="#Trivia",
            ),
        ]
    )
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
    db_initializer.entity_repository.update_all.assert_called_once_with(
        [
            EntityBase(
                name="Rick Grimes",
                wiki_href="/wiki/Rick_Grimes_(TV_Universe)",
            ),
        ]
    )
    db_initializer.appearance_repository.update_all.assert_called_once_with(
        [
            EntityAppearance(
                episode_page_href="/wiki/Days_Gone_Bye_(TV_Series)",
                entity_name="Rick Grimes",
                entity_page_href="/wiki/Rick_Grimes_(TV_Universe)",
                entity_page_title="Rick Grimes (TV Universe)",
                appearance_type_id=0,
                appearance_form_types_ids=[1],
            )
        ]
    )
    db_initializer.appearance_form_repository.update_all.assert_called_once_with(
        [
            EntityAppearance(
                episode_page_href="/wiki/Days_Gone_Bye_(TV_Series)",
                entity_name="Rick Grimes",
                entity_page_href="/wiki/Rick_Grimes_(TV_Universe)",
                entity_page_title="Rick Grimes (TV Universe)",
                appearance_type_id=0,
                appearance_form_types_ids=[1],
            )
        ]
    )


@pytest.mark.parametrize(
    "episode_page_scraper",
    [
        {
            "https://walkingdead.fandom.com/wiki/Guts": EpisodePage(
                episode=EpisodeBase(
                    name="Guts",
                    season_number=1,
                    episode_number=2,
                    wiki_href="/wiki/Guts",
                ),
                entity_appearances=[
                    EntityAppearanceBase(
                        entity_name="Andrea Harrison",
                        entity_page_href="/wiki/Andrea_Harrison_(TV_Series)",
                        entity_page_title="Andrea Harrison (TV Series)",
                        appearance_type_id=1,
                        appearance_form_types_ids=[0],
                    ),
                    EntityAppearanceBase(
                        entity_name="Wayne Dunlap",
                        entity_page_href="/wiki/Wayne_Dunlap_(TV_Series)",
                        entity_page_title="Wayne Dunlap (TV Series)",
                        appearance_type_id=2,
                        appearance_form_types_ids=[3],
                    ),
                ],
                next_page_href=None,
            ),
        }
    ],
    indirect=True,
)
@pytest.mark.asyncio
async def test__import_multiple_entities_by_one_episode(
    db_initializer: MockedDatabaseInitializer,
) -> None:
    await db_initializer.run(initial_page_href="/wiki/Guts", load_until=None)
    db_initializer.episode_page_scraper.scrape.assert_has_calls(
        [
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Guts",
                wait_until_selector="#Trivia",
            ),
        ]
    )
    db_initializer.episode_repository.update_all.assert_called_once_with(
        [
            EpisodeBase(
                name="Guts",
                season_number=1,
                episode_number=2,
                wiki_href="/wiki/Guts",
            )
        ]
    )
    db_initializer.entity_repository.update_all.assert_called_once_with(
        [
            EntityBase(
                name="Andrea Harrison",
                wiki_href="/wiki/Andrea_Harrison_(TV_Series)",
            ),
            EntityBase(
                name="Wayne Dunlap",
                wiki_href="/wiki/Wayne_Dunlap_(TV_Series)",
            ),
        ]
    )
    db_initializer.appearance_repository.update_all.assert_called_once_with(
        [
            EntityAppearance(
                episode_page_href="/wiki/Guts",
                entity_name="Andrea Harrison",
                entity_page_href="/wiki/Andrea_Harrison_(TV_Series)",
                entity_page_title="Andrea Harrison (TV Series)",
                appearance_type_id=1,
                appearance_form_types_ids=[0],
            ),
            EntityAppearance(
                episode_page_href="/wiki/Guts",
                entity_name="Wayne Dunlap",
                entity_page_href="/wiki/Wayne_Dunlap_(TV_Series)",
                entity_page_title="Wayne Dunlap (TV Series)",
                appearance_type_id=2,
                appearance_form_types_ids=[3],
            ),
        ]
    )
    db_initializer.appearance_form_repository.update_all.assert_called_once_with(
        [
            EntityAppearance(
                episode_page_href="/wiki/Guts",
                entity_name="Andrea Harrison",
                entity_page_href="/wiki/Andrea_Harrison_(TV_Series)",
                entity_page_title="Andrea Harrison (TV Series)",
                appearance_type_id=1,
                appearance_form_types_ids=[0],
            ),
            EntityAppearance(
                episode_page_href="/wiki/Guts",
                entity_name="Wayne Dunlap",
                entity_page_href="/wiki/Wayne_Dunlap_(TV_Series)",
                entity_page_title="Wayne Dunlap (TV Series)",
                appearance_type_id=2,
                appearance_form_types_ids=[3],
            ),
        ]
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
                entity_appearances=[
                    EntityAppearanceBase(
                        entity_name="Gleen Rhee",
                        entity_page_href="/wiki/Gleen_Rhee_(TV_Series)",
                        entity_page_title="Gleen Rhee (TV Series)",
                        appearance_type_id=0,
                        appearance_form_types_ids=[4],
                    ),
                ],
                next_page_href="/wiki/Guts",
            ),
            "https://walkingdead.fandom.com/wiki/Guts": EpisodePage(
                episode=EpisodeBase(
                    name="Guts",
                    season_number=1,
                    episode_number=2,
                    wiki_href="/wiki/Guts",
                ),
                entity_appearances=[
                    EntityAppearanceBase(
                        entity_name="Gleen Rhee",
                        entity_page_href="/wiki/Gleen_Rhee_(TV_Series)",
                        entity_page_title="Gleen Rhee (TV Series)",
                        appearance_type_id=0,
                        appearance_form_types_ids=[1],
                    ),
                ],
                next_page_href=None,
            ),
        }
    ],
    indirect=True,
)
@pytest.mark.asyncio
async def test__import_one_entity_by_multiple_episodes(
    db_initializer: MockedDatabaseInitializer,
) -> None:
    await db_initializer.run(
        initial_page_href="/wiki/Days_Gone_Bye_(TV_Series)", load_until=None
    )
    db_initializer.episode_page_scraper.scrape.assert_has_calls(
        [
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Days_Gone_Bye_(TV_Series)",
                wait_until_selector="#Trivia",
            ),
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Guts",
                wait_until_selector="#Trivia",
            ),
        ]
    )
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
        ]
    )
    db_initializer.entity_repository.update_all.assert_called_once_with(
        [
            EntityBase(
                name="Gleen Rhee",
                wiki_href="/wiki/Gleen_Rhee_(TV_Series)",
            ),
        ]
    )
    db_initializer.appearance_repository.update_all.assert_called_once_with(
        [
            EntityAppearance(
                episode_page_href="/wiki/Days_Gone_Bye_(TV_Series)",
                entity_name="Gleen Rhee",
                entity_page_href="/wiki/Gleen_Rhee_(TV_Series)",
                entity_page_title="Gleen Rhee (TV Series)",
                appearance_type_id=0,
                appearance_form_types_ids=[4],
            ),
            EntityAppearance(
                episode_page_href="/wiki/Guts",
                entity_name="Gleen Rhee",
                entity_page_href="/wiki/Gleen_Rhee_(TV_Series)",
                entity_page_title="Gleen Rhee (TV Series)",
                appearance_type_id=0,
                appearance_form_types_ids=[1],
            ),
        ]
    )
    db_initializer.appearance_form_repository.update_all.assert_called_once_with(
        [
            EntityAppearance(
                episode_page_href="/wiki/Days_Gone_Bye_(TV_Series)",
                entity_name="Gleen Rhee",
                entity_page_href="/wiki/Gleen_Rhee_(TV_Series)",
                entity_page_title="Gleen Rhee (TV Series)",
                appearance_type_id=0,
                appearance_form_types_ids=[4],
            ),
            EntityAppearance(
                episode_page_href="/wiki/Guts",
                entity_name="Gleen Rhee",
                entity_page_href="/wiki/Gleen_Rhee_(TV_Series)",
                entity_page_title="Gleen Rhee (TV Series)",
                appearance_type_id=0,
                appearance_form_types_ids=[1],
            ),
        ]
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
                entity_appearances=[
                    EntityAppearanceBase(
                        entity_name="Gleen Rhee",
                        entity_page_href="/wiki/Gleen_Rhee_(TV_Series)",
                        entity_page_title="Gleen Rhee (TV Series)",
                        appearance_type_id=0,
                        appearance_form_types_ids=[4],
                    ),
                ],
                next_page_href="/wiki/Guts",
            ),
            "https://walkingdead.fandom.com/wiki/Guts": EpisodePage(
                episode=EpisodeBase(
                    name="Guts",
                    season_number=1,
                    episode_number=2,
                    wiki_href="/wiki/Guts",
                ),
                entity_appearances=[
                    EntityAppearanceBase(
                        entity_name="Gleen",
                        entity_page_href="/wiki/Gleen_Rhee_(TV_Series)",
                        entity_page_title="Gleen Rhee (TV Series)",
                        appearance_type_id=0,
                        appearance_form_types_ids=[1],
                    ),
                ],
                next_page_href=None,
            ),
        }
    ],
    indirect=True,
)
@pytest.mark.asyncio
async def test__import_one_entity_by_multiple_episodes__with_conflict(
    db_initializer: MockedDatabaseInitializer,
) -> None:
    with pytest.raises(
        RuntimeError,
        match="the following entities have the same HREF \\(/wiki/Gleen_Rhee_\\(TV_Series\\)\\): Gleen Rhee, Gleen",
    ):
        await db_initializer.run(
            initial_page_href="/wiki/Days_Gone_Bye_(TV_Series)", load_until=None
        )
    db_initializer.episode_page_scraper.scrape.assert_has_calls(
        [
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Days_Gone_Bye_(TV_Series)",
                wait_until_selector="#Trivia",
            ),
            unittest.mock.call(
                "https://walkingdead.fandom.com/wiki/Guts",
                wait_until_selector="#Trivia",
            ),
        ]
    )
    unittest.mock.AsyncMock().assert_not_called()
    db_initializer.episode_repository.update_all.assert_not_called()
    db_initializer.entity_repository.update_all.assert_not_called()
    db_initializer.appearance_repository.update_all.assert_not_called()
    db_initializer.appearance_form_repository.update_all.assert_not_called()
