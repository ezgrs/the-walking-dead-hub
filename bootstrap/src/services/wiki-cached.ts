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

    async getPages(url: URL): Promise<EpisodePage[]> {
        const cacheKey = `http:response:${createHash('sha256')
            .update(url.href)
            .digest('hex')}`

        const cachedValue = await this.cache.get(cacheKey)
        let pages: EpisodePage[]
        if (cachedValue == null) {
            pages = await this.wiki.getPages(url)
            await this.cache.set(cacheKey, JSON.stringify(pages))
        } else {
            pages = JSON.parse(cachedValue) as EpisodePage[]
        }
        return pages
    }
}
