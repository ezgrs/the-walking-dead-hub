import dataclasses

# class AppearanceOrder(enum.Enum):
#     FIRST = 1   # First appearance of
#     LAST = 2    # Only appearance of
#     ONLY = 3    # Last appearance of


# class AppearanceType(enum.Enum):
#     ALIVE = 1            # Alive
#     CORPSE = 2           # Corpse
#     ZOMBIFIED = 3        # Zombified
#     VOICE_ONLY = 4       # Voice Only | Voice
#     PHYSICALLY = 5       # Physically
#     VIDEO_TAPE = 6       # Video Tape
#     FLASHBACK = 7        # Flashback
#     PHOTOGRAPH = 8       # Photograph
#     HALLUCINATION = 9    # Hallucination
#     DREAM = 10           # Dream
#     ULTRASOUND = 11      # Ultrasound


@dataclasses.dataclass(kw_only=True, frozen=True)
class EntityAppearance:
    entity_page_href: str
    entity_page_title: str
    entity_name: str

    appearance_type_id: int
    appearance_form_types_ids: list[int]


@dataclasses.dataclass(kw_only=True, frozen=True)
class EpisodePage:
    href: str
    title: str
    season_number: int
    episode_number: int
    entity_appearances: list[EntityAppearance]
    next_page_href: str
