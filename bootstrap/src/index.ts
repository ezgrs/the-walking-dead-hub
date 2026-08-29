import 'dotenv/config'
import { PrismaPg } from '@prisma/adapter-pg'
import { PrismaClient } from './generated/prisma/client.js'
import { chromium } from 'playwright'
import { PrismaDatabase } from './services/database-prisma.js'
import { RunUseCase } from './use-cases/run.js'
import { PlaywrightWiki } from './services/wiki-playwright.js'
import { CachedWiki } from './services/wiki-cached.js'
import { createClient } from 'redis'
import { RedisCache } from './services/redis-cache.js'
import { Dependency } from './utils/dependency.js'
import { Wiki } from './ports/wiki.js'

async function main() {
    // Creates Redis handling
    const redisDependency = new Dependency<RedisCache>({
        createFn: async () =>
            new RedisCache({
                redis: await createClient({
                    url:
                        `redis://` +
                        `${process.env['REDIS_HOST']}:` +
                        `${process.env['REDIS_PORT']}`,
                }).connect(),
            }),
        disposeFn: async (cache) => {
            await cache.dispose()
        },
    })

    // Creates Prisma handling
    const prismaDependency = new Dependency<PrismaDatabase>({
        createFn: async () =>
            new PrismaDatabase({
                prisma: new PrismaClient({
                    adapter: new PrismaPg({
                        connectionString:
                            `postgresql://` +
                            `${process.env['POSTGRES_USERNAME']}:` +
                            `${process.env['POSTGRES_PASSWORD']}@` +
                            `${process.env['POSTGRES_HOST']}:` +
                            `${process.env['POSTGRES_PORT']}/` +
                            `${process.env['POSTGRES_DATABASE']}`,
                    }),
                }),
            }),
        disposeFn: async (database) => {
            await database.dispose()
        },
    })

    await prismaDependency.using(async (database) => {
        // Creates Playwright handling
        const playwrightDependency = new Dependency<PlaywrightWiki>({
            createFn: async () =>
                new PlaywrightWiki({
                    browser: await chromium.launch({ headless: false }),
                    appearanceTypeAliases:
                        await database.getAppearanceTypeAliases(),
                    appearanceFormTypeAliases:
                        await database.getAppearanceFormTypeAliases(),
                }),
            disposeFn: async (wiki) => {
                await wiki.dispose()
            },
        })

        // Links Redis with Playwright
        const wikiDependency: Dependency<Wiki> = redisDependency.flatMap(
            (cache) =>
                playwrightDependency.map<Wiki>(
                    (wiki) => new CachedWiki({ cache, wiki }),
                ),
        )

        await new RunUseCase({
            database: database,
            wikiDependency: wikiDependency,
        }).execute({
            scriptVersion: 1,
            baseUrl: new URL(
                'https://walkingdead.fandom.com/wiki/Template:EpisodeList',
            ),
        })
    })
}

main().catch((error) => {
    console.error('Bootstrap failed')
    console.error(error)
    process.exitCode = 1
})
