interface Closeable {
    close(): Promise<void>
}

export async function using<T extends Closeable, R>(
    obj: T,
    usage: (obj: T) => Promise<R>,
): Promise<R> {
    try {
        return await usage(obj)
    } finally {
        await obj.close()
    }
}
