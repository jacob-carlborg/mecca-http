/**
 * HTTP request.
 *
 * Copyright: Copyright (c) 2019 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module mecca.http.request;

struct Request
{
    import mecca.containers.arrays : FixedString;
    import mecca.http.headers;

    enum Method
    {
        get,
        post,
        head,
        delete_,
        put,
        patch,
        connect,
        options,
        trace
    }

    enum Protocol
    {
        http1_1
    }

    Method method;
    string path;
    Protocol protocol = Protocol.http1_1;

    private Headers!100 headers;
    private FixedString!1000 data;

    void addHeader(string name, string value) pure nothrow @nogc @safe
    {
        headers.add(name, value);
    }

    string toData() pure nothrow return @nogc @trusted
    {
        data.append("GET");
        data ~= ' ';
        data.append(path);
        data ~= ' ';

        final switch (protocol)
        {
            case Protocol.http1_1: data.append("HTTP/1.1"); break;
        }

        data.append("\r\n");

        foreach (header; headers)
        {
            data.append(header.name);
            data.append(": ");
            data.append(header.value);
            data.append("\r\n");
        }

        data.append("\r\n");

        return cast(string) data.array;
    }
}

private void append(String)(ref String str, string data) @safe
{
    foreach (char c; data)
        str ~= c;
}
