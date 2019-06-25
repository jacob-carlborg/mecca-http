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
     * Writes all the given data to the socket.
     *
     * Params:
     *  data = the data to write to the socket
     *  timeout = how long to wait before timing out
     *
     * Returns: `true` if all data was written
     */
    bool write(const void[] data, Timeout timeout = Timeout.infinite) @nogc @safe
    {
        import core.sys.posix.sys.types : ssize_t;

        ssize_t bytesWritten = 0;
        size_t bufferPosition = 0;

        while (bufferPosition < data.length)
        {
            bytesWritten = socket.write(data[bufferPosition .. $]);

            if (bytesWritten == -1)
                return false;

            bufferPosition += bytesWritten;
        }

        return true;
    }
}
