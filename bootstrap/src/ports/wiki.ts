import { EpisodePage } from '../models/episode-page.js'

export interface Wiki {
    getPages(url: URL): Promise<URL[]>
    getPage(url: URL): Promise<EpisodePage>
}
