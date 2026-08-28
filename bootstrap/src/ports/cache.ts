export type CacheOptions = {
    ttl?: number
}

export interface Cache {
    get(key: string): Promise<string | undefined>
    set(key: string, value: string, options?: CacheOptions): Promise<void>
    delete(key: string): Promise<void>
}
