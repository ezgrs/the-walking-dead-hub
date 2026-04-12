import abc

from twd_life_tracker.domain.models import EpisodePage
from twd_life_tracker.domain.services.page_loader import PageLoader
from twd_life_tracker.domain.services.tag_parser import TagParser


class ImportRepository(abc.ABC):
    @abc.abstractmethod
    async def import_data(
        self,
        *,
        page_loader: PageLoader,
        tag_parser: TagParser[EpisodePage],
    ) -> None: ...
