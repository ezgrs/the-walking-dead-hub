import { Alias } from '../models/alias.js'
import { EpisodePage } from '../models/episode-page.js'

export interface Database {
    getCurrentVersion(): Promise<number | null>
    setCurrentVersion(version: number): Promise<void>

    getAppearanceTypeAliases(): Promise<Alias[]>
    getAppearanceFormTypeAliases(): Promise<Alias[]>

    update(pages: EpisodePage[]): Promise<void>
}
