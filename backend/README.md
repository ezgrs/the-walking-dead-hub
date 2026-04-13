# User guide

This guide walks you through setting up the backend from scratch.

## Prerequisites

Make sure you have the following:

- The repository cloned to your machine
- PostgreSQL running locally or accessible remotely
- Redis running locally or accessible remotely
- Poetry in your PATH for dependency management

You should also be inside the *backend/* directory:

```bash
cd the-walking-dead-hub/backend
````

## Tutorial

1. Create a *.env* file with the following entries:

```env
database_host=
database_port=
database_username=
database_password=
database_name=

redis_host=
redis_port=
redis_db=
redis_password=
```

Example:

```env
database_host=localhost
database_port=5432
database_username=postgres
database_password=postgres
database_name=twd_character_stats

redis_host=localhost
redis_port=6379
redis_username=default
redis_password=
redis_name=0
```

2. Install project's dependencies:

```bash
poetry install
```

3. Install the scraper's required browser:

```bash
poetry run playwright install chromium
```

4. Run database migrations to create all tables and populate some base data (e.g. enums and reference tables):

```bash
poetry run alembic upgrade head
```

5. Populate the remaining data via scraping:

```bash
poetry run python -m twd_life_tracker.scripts.initialize_db
```

This step will:

* Fetch data from external sources
* Populate characters, episodes, and appearances
* Complete the database


Optionally, to speed up future runs, you can cache downloaded HTML pages.

Add the following entry to your `.env` before running the scraper:

```env
cache_dir_path=/path/to/cache/folder
```

Example:

```env
cache_dir_path=./cache
```

This will save scraped HTML locally to avoid re-downloading data and make subsequent runs much faster.

6. Once the database is fully populated, you can run queries like:

```sql
select 
	ep.season,
	ep.number,
	ep.name as "episode",
	en.name as "who",
	apt.name as type,
	apft.name as form
from appearances ap
join episodes ep on ep.id = ap.episodeid
join entities en on en.id = ap.entityid
join appearancetypes apt on apt.id = ap.appearancetypeid 
left join appearanceforms apf on apf.appearanceid = ap.id
left join appearanceformtypes apft on apft.id = apf.appearanceformtypeid;
```

This query shows episode info (season, number, name), character involved, type of appearance and form of appearance (if applicable).
