## Domain models

This section defines the core business entities of the system, which represent the structure and meaning of data within the domain.

If a model name includes a `Base` suffix, it indicates a version of the model that does not include persistence-related identifiers. 
The corresponding non-`Base` model represents the full entity and includes the primary identifier (ID) used to uniquely reference it within the system.


### 📄 Settings

It defines configuration required to connect to external systems.

It currently contains database and Redis connection parameters.


### 📄 Entity

It represents a fictional character or location in the TV series universe.

It currently contains the name of the entity and the hypertext reference relative to the Fandom website.

For example,

```python
EntityBase(
  name="Rick Grimes",
  wiki_href="/wiki/Rick_Grimes_(TV_Universe)",
)
EntityBase(
  name="Greene Family Farm",
  wiki_ref="/wiki/Greene_Family_Farm_(TV_Series)",
)
```

Note that `name` does not always match the title of the corresponding Fandom page. This is because some 
characters or locations share the same name as their comic counterparts, and Fandom disambiguates them by 
adding a parenthetical label. In this model, `name` always stores the normalized version of the title, with
any parenthetical disambiguation removed.

### 📄 Episode

It represents a episode of the TV series.

It currently contains the name of the episode, the hypertext reference relative to the Fandom website,
the season number and its number inside the season.

For example,

```python
EpisodeBase(
  name="Days Gone Bye",
  wiki_href="/wiki/Days_Gone_Bye_(TV_Series)",
  season_number=1,
  episode_number=1,
)
```

Note that `name` does not always match the title of the corresponding Fandom page. This is because some episodes
share the same title as comic issues, and Fandom disambiguates them by adding a parenthetical label. In this model,
`name` always stores the normalized version of the title, with any parenthetical disambiguation removed.

### 📄 Appearance

It represents the occurrence of an entity in a specific episode of the TV series.

It contains references to the episode, the entity, and the type of appearance.

For example:

```python
AppearanceBase(
  episode_id=0,
  entity_id=1,
  type_id=0,
)
```

The type of appearance can be:

- **first**: indicates the entity's first appearance in the series, starting with the given episode.
- **only**: indicates that the entity appears exclusively in that episode across the entire series.
- **last**: indicates the entity’s final appearance in the series.

An entity may have multiple first and last appearances across the series. This is because different forms
of the same entity can be treated as distinct appearance types. For example, a character may appear in a 
voice-only form in one episode and physically in another (as in the case of Glenn on S01E01 and S01E02),
resulting in multiple "first" appearances depending on the form considered. Similarly, a character may
appear as a corpse in one episode and later as a reanimated zombie in another, which can lead to separate
"last" appearances for each distinct state.

### 📄 Appearance form

It represents the specific form in which an entity appears within a given appearance.

It contains references to the corresponding appearance and to the type of form in which that appearance occurs.

For example:

```python
AppearanceFormBase(
  appearance_id=2,
  type_id=1
)
```

The type of appearance form can be alive, corpse, zombified, voice only, phisically, video tape, flashback, photograph, 
hallucination, dream or ultrasound. An appearance can have multiple appearance forms, such as hallucination and zombified.

### 📄 Entity appearance

It represents the occurrence of an entity within an episode, along with metadata describing 
how and in what form the entity appears.

It contains

- the relative URL to the entity’s page on the source website (`entity_page_href`)
- the raw title of the entity page as provided by the source, including any disambiguation labels (`entity_page_title`)
- the normalized name of the entity, with any disambiguation removed (`entity_name`)
- an identifier representing the type of appearance, such as first, only or last (`appearance_type_id`)
-  list of identifiers representing the different forms in which the entity appears within the episode, such as alive, corpse or flashback (`appearance_form_types_ids`)

For example:

```python
EntityAppearance(
  entity_page_href="/wiki/Glenn_Rhee",
  entity_page_title="Glenn Rhee (TV Series)",
  entity_name="Glenn Rhee",
  appearance_type_id=0,
  appearance_form_types_ids=[1, 3]
)
```

### 📄 Episode page

It represents a episode entry on the Fandom website.

It contains:

- the episode metadata (`episode`)
- all entities that appear in the episode, along with their associated metadata (`entity_appearances`)
- the relative URL to the next episode in sequence, used for navigation across episodes in the source (`next_page_href`)

For example:

```python
EpisodePage(
  episode=EpisodeBase(
    name="Days Gone Bye",
    wiki_href="/wiki/Days_Gone_Bye_(TV_Series)",
    season_number=1,
    episode_number=1,
  ),
  entity_appearances=[...],
  next_page_href="/wiki/Guts"
)
```
