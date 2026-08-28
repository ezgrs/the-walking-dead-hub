type Args<T> = {
    createFn: () => Promise<T>
    disposeFn: (obj: T) => Promise<void>
}

export class Dependency<T> {
    private readonly createFn: () => Promise<T>
    private readonly disposeFn: (obj: T) => Promise<void>

    constructor(args: Args<T>) {
        this.createFn = args.createFn
        this.disposeFn = args.disposeFn
    }

    async create(): Promise<T> {
        return this.createFn()
    }

    async dispose(obj: T): Promise<void> {
        return this.disposeFn(obj)
    }

    async using<R>(usage: (obj: T) => Promise<R>): Promise<R> {
        const obj = await this.create()

        try {
            return await usage(obj)
        } finally {
            await this.dispose(obj)
        }
    }

    map<B>(map: (value: T) => B): Dependency<B> {
        let parentRef: T | undefined
        return new Dependency({
            createFn: async () => {
                const parent = await this.create()
                parentRef = parent

                try {
                    return map(parent)
                } catch (error) {
                    await this.dispose(parent)
                    parentRef = undefined
                    throw error
                }
            },
            disposeFn: async () => {
                if (parentRef == null) {
                    return
                }
                const parent = parentRef
                parentRef = undefined
                await this.dispose(parent)
            },
        })
    }

    flatMap<B>(map: (value: T) => Dependency<B>): Dependency<B> {
        let parentRef: T | undefined
        let childDependency: Dependency<B> | undefined

        return new Dependency({
            createFn: async () => {
                const parent = await this.create()

                try {
                    const child = map(parent)
                    const value = await child.create()

                    parentRef = parent
                    childDependency = child

                    return value
                } catch (error) {
                    await this.dispose(parent)
                    throw error
                }
            },
            disposeFn: async (value) => {
                if (parentRef == null || childDependency == null) {
                    return
                }
                try {
                    await childDependency.dispose(value)
                } finally {
                    await this.dispose(parentRef)
                    parentRef = undefined
                    childDependency = undefined
                }
            },
        })
    }
}
