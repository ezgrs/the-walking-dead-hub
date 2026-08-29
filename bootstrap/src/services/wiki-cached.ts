import { createHash } from 'crypto'
import { EpisodePage } from '../models/episode-page.js'
import { Cache } from '../ports/cache.js'
import { Wiki } from '../ports/wiki.js'

type Args = {
    cache: Cache
    wiki: Wiki
}

export class CachedWiki implements Wiki {
    private readonly cache: Cache
    private readonly wiki: Wiki

    constructor(args: Args) {
        this.cache = args.cache
        this.wiki = args.wiki
    }

    async getPages(url: URL): Promise<URL[]> {
        const cacheKey = `wiki:summary:${createHash('sha256')
            .update(url.href)
            .digest('hex')}`

        const cachedValue = await this.cache.get(cacheKey)
        let urls: URL[]
        if (cachedValue == null) {
            urls = await this.wiki.getPages(url)
            await this.cache.set(
                cacheKey,
                JSON.stringify(urls.map((url) => url.href)),
            )
        } else {
            urls = (JSON.parse(cachedValue) as string[]).map(
                (href) => new URL(href),
            )
        }
        return urls
    }

    async getPage(url: URL): Promise<EpisodePage> {
        const cacheKey = `wiki:episode:${createHash('sha256')
            .update(url.href)
            .digest('hex')}`

        const cachedValue = await this.cache.get(cacheKey)
        let page: EpisodePage
        if (cachedValue == null) {
            page = await this.wiki.getPage(url)
            await this.cache.set(cacheKey, JSON.stringify(page))
        } else {
            page = JSON.parse(cachedValue) as EpisodePage
        }
        return page
    }
}
