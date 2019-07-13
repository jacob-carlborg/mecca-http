/**
 * HTTP headers.
 *
 * Copyright: Copyright (c) 2019 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module mecca.http.headers;

package enum immutable(void)[] endSentinel = "\r\n\r\n";

struct Headers(size_t count)
{
    import mecca.containers.arrays : FixedArray;

    private struct Pair
    {
        string name;
        string value;
    }

    private FixedArray!(Pair, count) storage;

    void add(string name, string value) pure nothrow @nogc @safe
    {
        storage ~= Pair(name, value);
    }

    inout(Pair)[] opSlice() inout pure nothrow return @nogc @safe
    {
        return storage.array;
    }
}
