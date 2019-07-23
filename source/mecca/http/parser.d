/**
 * HTTP parser.
 *
 * Copyright: Copyright (c) 2019 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module mecca.http.parser;

alias Callback = bool delegate(const ref RequestParser);
alias DataCallback = bool delegate(const ref RequestParser, ubyte[] data);

enum Result
{
    invalid,
    invalidMethod,
    noData
}

struct Callbacks
{
    Callback messageBegin;
    DataCallback url;
    DataCallback status;
    DataCallback headerField;
    DataCallback headerValue;
    Callback headersComplete;
    DataCallback body_;
    Callback messageComplete;
}

struct RequestParser
{
    import mecca.http.request : Request;

    private enum State
    {
        initial
    }

    private
    {
        Callbacks callbacks;
        State state;
    }

    @disable this(this);

    this(const ref Callbacks callbacks)
    {
        this.callbacks = callbacks;
    }

    Result parse(const char[] data) pure nothrow @nogc @safe
    {
        import std.algorithm;

        if (data.length == 0)
        {
            with(State) final switch (state)
            {
                case initial: return Result.noData;
            }
        }

        foreach (currentByte; data)
        {

        }

        return Result.invalid;
    }

private:

    bool isValidMethod(ubyte firstByteOfMethod)
    {
        import std.algorithm : map, sort, uniq;
        import std.array : array;
        import std.range : front;
        import std.string : toUpper;

        enum uniqueMethods = [__traits(allMembers, Request.Method)]
            .map!toUpper
            .map!front
            .array
            .sort
            .uniq;

        switch (firstByteOfMethod)
        {
            static foreach (method; uniqueMethods)
                case method: return true;

            default: return false;
        }
    }

    unittest
    {
        RequestParser parser;

        assert(parser.isValidMethod("CONNECT"[0]));
        assert(parser.isValidMethod("DELETE"[0]));
        assert(parser.isValidMethod("GET"[0]));
        assert(parser.isValidMethod("HEAD"[0]));
        assert(parser.isValidMethod("OPTIONS"[0]));
        assert(parser.isValidMethod("PATCH"[0]));
        assert(parser.isValidMethod("POST"[0]));
        assert(parser.isValidMethod("PUT"[0]));
        assert(parser.isValidMethod("TRACE"[0]));
    }
}

// No data, initial state
unittest
{
    Callbacks callbacks;
    auto parser = RequestParser(callbacks);

    assert(parser.parse([]) == Result.noData);
}

// initial state, data == "GET foo";
unittest
{
    bool called = false;

    Callbacks callbacks;
    callbacks.messageBegin = (const ref requestParser) {
        called = true;
        return true;
    };

    auto parser = RequestParser(callbacks);
    parser.parse("GET foo");

    assert(called);
}
