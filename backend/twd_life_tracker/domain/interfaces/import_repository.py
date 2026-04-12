import abc

from twd_life_tracker.domain.services.episode_page_loader import EpisodeLoader


class ImportRepository(abc.ABC):
    @abc.abstractmethod
    async def import_data(
        self,
        *,
        loader: EpisodeLoader,
    ) -> None: ...
