import { Prisma, PrismaClient } from '../generated/prisma/client.js'
import { Alias } from '../models/alias.js'
import { CharacterMilestone } from '../models/character-milestone.js'
import { EpisodePage } from '../models/episode-page.js'
import { Database } from '../ports/database.js'

type Args = {
    prisma: PrismaClient
}

// Finds the longest candidate whose normalized form appears in the normalized
// base string. Normalization is case-insensitive and ignores all characters
// except A-Z. Returns the matching candidate with each word's first letter
// capitalized, or undefined if none match.
function bestAlias(base: string, candidates: string[]) {
    const b = base.replace(/[^a-z]/gi, '').toLowerCase()
    return candidates
        .filter((c) => b.includes(c.replace(/[^a-z]/gi, '').toLowerCase()))
        .sort((a, z) => z.length - a.length)[0]
        ?.replace(/\b\w/g, (c) => c.toUpperCase())
}

function summarizeCharacters(
    milestones: CharacterMilestone[],
): Map<string, string> {
    const charactersAliases: Map<string, Set<string>> = new Map()

    for (const milestone of milestones) {
        const href = milestone.characterHref
        const alias = milestone.characterName

        // Given a canonical HREF of a character,
        // tracks how many aliases do they have
        const _aliases = charactersAliases.get(href)
        let aliases: Set<string>
        if (_aliases == null) {
            aliases = new Set()
        } else {
            aliases = new Set(_aliases)
        }

        // Includes the current alias in that
        aliases.add(alias)

        charactersAliases.set(href, aliases)
    }

    const characters: Map<string, string> = new Map()
    for (const [key, value] of charactersAliases.entries()) {
        const aliases = Array.from(value)
        if (aliases.length > 1) {
            // This was the best way possible to address some characters having
            // multiple aliases by multiple reasons, such as married names
            // (Maggie Greene/Maggie Rhee, Michonne Hawthorne/Michonne Grimes,
            // Maxxine Mercer/Maxxine Porter), naming inconsistency (Saviors/
            // the Saviors, Henry/Henry Sutton, Heaps/the Heaps, Reapers/the
            // Reapers, the Warden/The Warden) or even typos (Terminus/Termimus).
            // So we compare them against the canonical HREF of the character.
            const mainAlias = bestAlias(key, aliases)
            if (mainAlias == null) {
                throw new Error(`can't decide main alias for ${aliases}`)
            }
            characters.set(key, mainAlias)
        } else {
            characters.set(key, aliases[0])
        }
    }
    return characters
}

export class PrismaDatabase implements Database {
    private readonly prisma: PrismaClient

    constructor(args: Args) {
        this.prisma = args.prisma
    }

    async dispose(): Promise<void> {
        await this.prisma.$disconnect()
    }

    async getCurrentVersion(): Promise<number | null> {
        const result = await this.prisma.bootstrapRun.aggregate({
            _max: { version: true },
        })
        return result._max.version
    }

    async setCurrentVersion(version: number): Promise<void> {
        await this.prisma.bootstrapRun.create({
            data: { version: version },
        })
    }

    async getAppearanceTypeAliases(): Promise<Alias[]> {
        return await this.prisma.appearanceTypeAlias.findMany()
    }

    async getAppearanceFormTypeAliases(): Promise<Alias[]> {
        return await this.prisma.appearanceFormTypeAlias.findMany()
    }

    async update(pages: EpisodePage[]): Promise<void> {
        const episodes = pages.map((page) => page.info)
        const characters = summarizeCharacters(
            pages.flatMap((page) => page.milestones),
        )

        await this.prisma.$transaction(async (tx) => {
            // Upsert episodes
            for (const episode of episodes) {
                await tx.episode.upsert({
                    where: {
                        wikiHref: episode.wikiHref,
                    },
                    update: {
                        name: episode.name,
                        seasonNumber: episode.season,
                        episodeNumber: episode.episode,
                    },
                    create: {
                        wikiHref: episode.wikiHref,
                        name: episode.name,
                        seasonNumber: episode.season,
                        episodeNumber: episode.episode,
                    },
                })
            }

            // Upsert entities
            for (const [characterHref, characterName] of characters.entries()) {
                await tx.entity.upsert({
                    where: {
                        wikiHref: characterHref,
                    },
                    update: {
                        name: characterName,
                    },
                    create: {
                        wikiHref: characterHref,
                        name: characterName,
                    },
                })
            }

            // Upsert appearances and appearances forms
            await this.updateAppearances(
                tx,
                pages.flatMap((page) =>
                    page.milestones.map((milestone) => ({
                        episodeHref: page.info.wikiHref,
                        entityHref: milestone.characterHref,
                        appearanceTypeId: milestone.appearanceTypeId,
                        appearanceFormsTypeIds: milestone.appearanceFormTypeIds,
                    })),
                ),
            )
        })
    }

    private async updateAppearances(
        tx: Prisma.TransactionClient,
        datum: {
            episodeHref: string
            entityHref: string
            appearanceTypeId: number
            appearanceFormsTypeIds: number[]
        }[],
    ) {
        // Create a temporary table with the raw input data
        await tx.$executeRaw`
            CREATE TEMP TABLE tmp_appearancesraw (
                episodewikihref VARCHAR(127) NOT NULL,
                entitywikihref VARCHAR(127) NOT NULL,
                appearancetypeid INTEGER NOT NULL,
                appearanceformtypeids INTEGER[] NOT NULL
            ) ON COMMIT DROP
        `
        // Populate the temporary table
        await tx.$executeRaw`
            INSERT INTO tmp_appearancesraw (
                episodewikihref,
                entitywikihref,
                appearancetypeid,
                appearanceformtypeids
            ) VALUES ${Prisma.join(
                datum.map(
                    (data) =>
                        `(` +
                        `${data.episodeHref}, ` +
                        `${data.entityHref}, ` +
                        `${data.appearanceTypeId}, ` +
                        `${data.appearanceFormsTypeIds}` +
                        `)`,
                ),
            )}
        `
        // Create another temporary table with normalized
        // data such that episodewikihref -> episode.id
        // and entitywikihref -> entity.id
        await tx.$executeRaw`
            CREATE TEMP TABLE tmp_appearances 
            ON COMMIT DROP AS 
            SELECT
                episodes.id as episodeid,
                entities.id as entityid,
                tmp_appearancesraw.appearancetypeid,
                tmp_appearancesraw.appearanceformtypeids
            FROM tmp_appearancesraw
            JOIN episodes ON episodes.wikihref = tmp_appearancesraw.episodewikihref
            JOIN entities ON entities.wikihref = tmp_appearancesraw.entitywikihref
        `
        // Upsert all new values into `appearances`
        await tx.$executeRaw`
            INSERT INTO appearances (
                episodeid,
                entityid,
                appearancetypeid,
            )
            SELECT 
                episodeid,
                entityid,
                appearancetypeid
            FROM tmp_appearances
            ON CONFLICT (episodeid, entityid)
            DO UPDATE SET appearancetypeid = EXCLUDED.appearancetypeid
        `
        // Delete outdated values from `appearances`
        await tx.$executeRaw`
            DELETE FROM appearances
            WHERE NOT EXISTS (
                SELECT 1 FROM tmp_appearances
                WHERE tmp_appearances.episodeid = appearances.episodeid
                AND tmp_appearances.entityid = appearances.entityid
            )
        `

        // Create another temporary table with normalized
        // data such that (episodeid, entityid) -> appearances.id
        await tx.$executeRaw`
            CREATE TEMP TABLE tmp_appearanceforms 
            ON COMMIT DROP AS
            SELECT
                appearances.id,
                tmp_appearances.appearanceformtypeids
            FROM tmp_appearances
            JOIN appearances
                ON appearances.episodeid = tmp_appearances.episodeid
                AND appearances.entityid = tmp_appearances.entityid
        `
        // Upsert all new values into `appearanceforms`
        await tx.$executeRaw`
            INSERT INTO appearanceforms (
                appearanceid,
                appearanceformtypeid
            )
            SELECT
                tmp_appearanceforms.id,
                t.id
            FROM tmp_appearanceforms
            CROSS JOIN LATERAL UNNEST(tmp_appearanceforms.appearanceformtypeids) AS t(id)
            ON CONFLICT (appearanceid, appearanceformtypeid)
            DO NOTHING
        `
        // Delete outdated values from `appearanceforms`
        await tx.$executeRaw`
            DELETE FROM appearanceforms
            WHERE NOT EXISTS (
                SELECT 1 FROM tmp_appearanceforms
                WHERE tmp_appearanceforms.appearanceid = appearanceforms.appearanceid
                AND appearanceforms.appearanceformtypeid = ANY(tmp_appearanceforms.appearanceformtypeids)
            )
        `
    }
}
