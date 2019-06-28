/**
 * A socket adopted for HTTP.
 *
 * Copyright: Copyright (c) 2019 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module mecca.http.socket;

struct Socket
{
    import mecca.reactor.io.fd : ConnectedSocket;
    import mecca.lib.time : Timeout;

    private ConnectedSocket socket;

    /**
     * Sends all the given data to the socket.
     *
     * Params:
     *  data = the data to send to the socket
     *  flags = flags argument as defined for the standard socket `send`
     *  timeout = how long to wait before timing out
     *
     * Returns: `true` if all data was written
     */
    bool send(
        const void[] data,
        int flags = 0,
        Timeout timeout = Timeout.infinite
    ) @nogc @safe
    {
        import core.sys.posix.sys.types : ssize_t;

        ssize_t bytesWritten = 0;
        size_t position = 0;

        while (position < data.length)
        {
            bytesWritten = socket.send(data[position .. $], flags, timeout);

            if (bytesWritten == -1)
                return false;

            position += bytesWritten;
        }

        return true;
    }

    /**
     * Receives a header into the given buffer.
     *
     * Receives data into the given buffer until a header end sentinel has been
     * received.
     *
     * Params:
     *  buffer = the buffer to place the received data in. This buffer needs to
     *      be large enough to fit the header including the end sentinel
     *  flags = flags argument as defined for the standard socket `recv`
     *  timeout = how long to wait before timing out
     *
     * Returns: `true` if a header end sentinel was received. `false` if the
     *  connection was closed before receiving the end sentinel.
     */
    bool receiveHeader(void[] buffer, int flags = 0,
        Timeout timeout = Timeout.infinite) @nogc @safe
    {
        import core.sys.posix.sys.types : ssize_t;
        import mecca.http.header : Header;

        static const(void[]) end(const void[] buffer, size_t position)
        {
            return buffer[position - Header.endSentinel.length .. position];
        }

        static bool hasReceivedHeaderSentinel(
            const void[] buffer, size_t position, ssize_t bytesRead
        )
        {
            return bytesRead >= Header.endSentinel.length
                && end(buffer, position) == Header.endSentinel;
        }

        return receiveUntil!hasReceivedHeaderSentinel(buffer, flags, timeout);
    }

    /**
     * Receives data until a condition has been fulfilled.
     *
     * Receives data into the given buffer until the given predicate returns
     * `true`.
     *
     * Params:
     *  buffer = the buffer to place the received data in
     *  flags = flags argument as defined for the standard socket `recv`
     *  timeout = how long to wait before timing out
     *
     * Returns: `true` if a header end sentinel was received. `false` if the
     *  connection was closed before receiving the end sentinel.
     */
    private bool receiveUntil(alias predicate)(void[] buffer, int flags = 0,
        Timeout timeout = Timeout.infinite) @nogc @safe
    {
        import core.sys.posix.sys.types : ssize_t;

        ssize_t bytesRead = 0;
        size_t position = 0;

        do
        {
            bytesRead = socket.recv(buffer[position .. $], flags, timeout);
            position += bytesRead;

            if (predicate(buffer, position, bytesRead))
                return true;
        } while (bytesRead > 0);

        return predicate(buffer, position, bytesRead);
    }
}
