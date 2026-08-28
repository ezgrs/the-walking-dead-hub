import type { RedisClientType } from 'redis'
import { Cache } from '../ports/cache.js'

type Args = {
    redis: RedisClientType
}

export class RedisCache implements Cache {
    private readonly redis: RedisClientType

    constructor(args: Args) {
        this.redis = args.redis
    }

    async dispose() {
        await this.redis.quit()
    }

    async get(key: string): Promise<string | undefined> {
        const value = await this.redis.get(key)
        if (value == null) {
            return undefined
        }
        return value
    }

    async set(
        key: string,
        value: string,
        options?: { ttl?: number },
    ): Promise<void> {
        const ttl = options?.ttl
        if (ttl == null) {
            return void (await this.redis.set(key, value))
        }
        return void (await this.redis.set(key, value, { PX: ttl }))
    }

    async delete(key: string): Promise<void> {
        await this.redis.del(key)
    }
}
