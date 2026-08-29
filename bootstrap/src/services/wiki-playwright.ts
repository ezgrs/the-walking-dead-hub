import { Browser, Locator, Page } from 'playwright'
import { EpisodePage } from '../models/episode-page.js'
import { Alias } from '../models/alias.js'
import { CharacterMilestone } from '../models/character-milestone.js'
import { Wiki } from '../ports/wiki.js'
import pLimit from 'p-limit'
import { using } from '../utils.js'

type ParseTriviaLocatorArgs = {
    locator: Locator
    appearanceTypeAliases: Alias[]
    appearanceFormTypeAliases: Alias[]
}
async function parseTriviaLocator(
    args: ParseTriviaLocatorArgs,
): Promise<CharacterMilestone | null> {
    // First appearance of Rick Grimes.
    const text = (await args.locator.innerText()).trim()
    let appearanceTypeId: number | null = null
    for (const alias of args.appearanceTypeAliases) {
        if (text.startsWith(alias.label)) {
            appearanceTypeId = alias.referenceId
            break
        }
    }
    if (appearanceTypeId == null) return null

    const appearanceFormTypeIds: number[] = []
    const iElem = args.locator.locator('i').first()
    if ((await iElem.count()) > 0) {
        // [ 'Voice Only' ]
        const characterStatusTexts = (await iElem.innerText())
            .replace(/^\(/, '')
            .replace(/\)$/, '')
            .split(/, |\//)

        for (const appearanceFormTypeText of characterStatusTexts) {
            for (const alias of args.appearanceFormTypeAliases) {
                if (alias.label == appearanceFormTypeText) {
                    appearanceFormTypeIds.push(alias.referenceId)
                    break
                }
            }
        }
    }

    const characterElem = args.locator.locator('a').first()
    if ((await characterElem.count()) === 0) {
        throw new Error('missing character <a>')
    }

    // /wiki/Rick_Grimes_(TV_Universe)
    const characterHref = await characterElem.getAttribute('href')
    if (characterHref === null) {
        throw new Error('invalid character href')
    }

    // Rick Grimes (TV Universe)
    const characterPageName = await characterElem.getAttribute('title')
    if (characterPageName === null) {
        throw new Error('invalid character title')
    }

    // Rick Grimes
    const characterName = (await characterElem.innerText()).trim()

    return {
        characterHref,
        characterPageName,
        characterName,
        appearanceTypeId,
        appearanceFormTypeIds,
    }
}
type ParseEpisodeArgs = {
    page: Page
    appearanceTypeAliases: Alias[]
    appearanceFormTypeAliases: Alias[]
}

async function parseEpisode(args: ParseEpisodeArgs): Promise<EpisodePage> {
    await args.page.waitForSelector('span.mw-page-title-main')

    // Parse episode URL
    const linkElem = args.page.locator('link[rel="canonical"]')
    if ((await linkElem.count()) === 0) {
        throw new Error('no episode link found')
    }

    // https://walkingdead.fandom.com/wiki/Days_Gone_Bye_(TV_Series)
    const canonicalHref = await linkElem.getAttribute('href')
    if (canonicalHref === null) {
        throw new Error(`invalid episode link: ${canonicalHref}`)
    }
    // /wiki/Days_Gone_Bye_(TV_Series)
    const episodeHref = canonicalHref.replace(
        'https://walkingdead.fandom.com',
        '',
    )

    const episodeTitleElem = args.page.locator('h2[data-source="title"]')
    if ((await episodeTitleElem.count()) === 0) {
        throw new Error('no episode title found')
    }
    // Days Gone Bye
    const episodeTitle = await episodeTitleElem.innerText()

    const episodeNumberDescriptionElem = args.page.locator(
        'div[data-source="number"]',
    )
    if ((await episodeNumberDescriptionElem.count()) === 0) {
        throw new Error('no episode number found')
    }

    // Season 1, Episode 1
    const episodeNumberDescriptionElemText = (
        await episodeNumberDescriptionElem.innerText()
    ).trim()

    const episodeNumberMatch = episodeNumberDescriptionElemText.match(
        /^Season ([0-9]+), Episode ([0-9]+)$/,
    )

    if (episodeNumberMatch === null) {
        throw new Error(
            `invalid episode number: ${episodeNumberDescriptionElemText}`,
        )
    }

    const [, episodeSeasonText, episodeNumberText] = episodeNumberMatch

    // 1
    const episodeSeason = Number.parseInt(episodeSeasonText, 10)
    // 1
    const episodeNumber = Number.parseInt(episodeNumberText, 10)

    const triviaElem = args.page.locator('#Trivia')
    if ((await triviaElem.count()) === 0) {
        throw new Error('no trivia section found')
    }

    const triviaUlElem = triviaElem.locator('xpath=following::ul[1]')
    if ((await triviaUlElem.count()) === 0) {
        throw new Error('no trivia list found')
    }

    const triviaLiElems = triviaUlElem.locator('li')

    // Parse episode entity appearances
    const milestones: CharacterMilestone[] = []
    for (let i = 0; i < (await triviaLiElems.count()); i++) {
        const triviaLiElem = triviaLiElems.nth(i)
        const milestone = await parseTriviaLocator({
            locator: triviaLiElem,
            appearanceTypeAliases: args.appearanceTypeAliases,
            appearanceFormTypeAliases: args.appearanceFormTypeAliases,
        })
        if (milestone == null) continue
        milestones.push(milestone)
    }

    return {
        info: {
            name: episodeTitle,
            season: episodeSeason,
            episode: episodeNumber,
            wikiHref: episodeHref,
        },
        milestones,
    }
}

async function parseEpisodesHrefs(page: Page): Promise<string[]> {
    await page.waitForSelector('h1.page-header__title')
    const table = page.locator('div.mw-parser-output table.navbox').first()
    const rows = table.locator('tbody > tr.navbox-rowyes')

    const hrefs: string[] = []
    for (const row of await rows.all()) {
        const links = row.locator('a')
        const [seasonLink, ...episodesLinks] = await links.all()

        const seasonNumberPattern = /\/wiki\/Season_([0-9]+)_\(TV_Series\)/
        const seasonHref = await seasonLink.getAttribute('href')
        if (seasonHref == null) {
            throw new Error('seasonLink has no href')
        }
        const seasonNumberMatch = seasonHref.match(seasonNumberPattern)
        if (seasonNumberMatch == null) {
            throw new Error('seasonHref does not match seasonNumberPattern')
        }
        for (const episodeLink of episodesLinks) {
            const wikiHref = await episodeLink.getAttribute('href')
            if (wikiHref == null) continue
            hrefs.push(wikiHref)
        }
    }
    return hrefs
}

type Args = {
    browser: Browser
    appearanceTypeAliases: Alias[]
    appearanceFormTypeAliases: Alias[]
}

export class PlaywrightWiki implements Wiki {
    private readonly browser: Browser
    private readonly appearanceTypeAliases: Alias[]
    private readonly appearanceFormTypeAliases: Alias[]

    constructor(args: Args) {
        this.browser = args.browser
        this.appearanceTypeAliases = args.appearanceTypeAliases
        this.appearanceFormTypeAliases = args.appearanceFormTypeAliases
    }

    async dispose(): Promise<void> {
        await this.browser.close()
    }

    async getPages(baseUrl: URL): Promise<URL[]> {
        const hrefs: string[] = await using(
            await this.browser.newContext(),
            async (context) => {
                // Parse episodes HREFs
                return await using(await context.newPage(), async (page) => {
                    await page.goto(baseUrl.href)
                    return await parseEpisodesHrefs(page)
                })
            },
        )
        return hrefs.map((href) => new URL(href, baseUrl))
    }

    async getPage(url: URL): Promise<EpisodePage> {
        return await using(await this.browser.newContext(), async (context) => {
            return await using(await context.newPage(), async (page) => {
                await page.goto(url.href)
                return await parseEpisode({
                    page,
                    appearanceTypeAliases: this.appearanceTypeAliases,
                    appearanceFormTypeAliases: this.appearanceFormTypeAliases,
                })
            })
        })
    }
}
