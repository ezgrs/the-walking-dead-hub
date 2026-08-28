import { Database } from '../ports/database.js'
import { Wiki } from '../ports/wiki.js'
import { Dependency } from '../utils/dependency.js'

type RunUseCaseArgs = {
    database: Database
    wikiDependency: Dependency<Wiki>
}

type RunArgs = {
    scriptVersion: number
    baseUrl: URL
}

export class RunUseCase {
    database: Database
    wikiDependency: Dependency<Wiki>

    constructor(args: RunUseCaseArgs) {
        this.database = args.database
        this.wikiDependency = args.wikiDependency
    }

    async execute(args: RunArgs) {
        // Checks if script even needs to be run
        const currentVersion = await this.database.getCurrentVersion()
        if (currentVersion != null && args.scriptVersion <= currentVersion) {
            return
        }

        await this.wikiDependency.using(async (wiki) => {
            // Parse episodes to be upserted
            const episodes = await wiki.getPages(args.baseUrl)

            // // Push changes to the database
            // await this.database.update(episodes)

            // // Update script
            // await this.database.setCurrentVersion(args.scriptVersion)
        })
    }
}
