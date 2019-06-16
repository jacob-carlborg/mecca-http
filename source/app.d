import std.stdio;

import mecca.reactor.io.fd : ConnectedSocket;

int main()
{
    import mecca.reactor : theReactor;

    theReactor.setup();
    scope (exit) theReactor.teardown();

    theReactor.spawnFiber!fiber;
    return theReactor.start();

    // fiber();
    // return 0;
}

struct Url
{
    string protocol;
    string hostname;
    ushort port;
    string path;
}

struct Headers(size_t count)
{
    import std.array : empty, front, popFront;
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

struct HttpRequest
{
    import mecca.containers.arrays : FixedString;

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

    private enum dataSize = 10_000;

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

void append(String)(ref String str, string data) @safe
{
    foreach (char c; data)
        str ~= c;
}

enum Url url = {
    protocol: "ws",
    hostname: "192.168.0.2",
    port: 2345,
    path: "/"
};

struct WebsocketConnection
{
    import core.sys.posix.sys.types : ssize_t;

    import mecca.lib.net : AF_INET, SockAddr, SockAddrIPv4;
    import mecca.lib.time : Timeout, seconds;
    import mecca.reactor : theReactor;

    private const Timeout timeout;

    private ConnectedSocket socket;
    private Url url;

    HttpRequest* request;

    this(Url url)
    {
        this.url = url;
        timeout = Timeout(5.seconds);
    }

    void connect()
    {
        const ipAddress = SockAddr.resolve(url.hostname).ipv4.addr;
        const address = SockAddrIPv4(ipAddress, url.port);
        socket = ConnectedSocket.connect(address);
    }

    void send(ref HttpRequest request)
    {
        write(request.toData);
        read();
    }

    void write(string data) @trusted
    {
        ssize_t bytesWritten = 0;

        while (data.length > 0)
        {
            bytesWritten = socket.write(data, timeout);
            data = data[bytesWritten .. $];
            writefln!"writer written=%s"(bytesWritten);
        }
    }

    void read()
    {
        // char[4096] buffer = void;
        // ssize_t bytesRead = 0;
        // size_t position = 0;
        //
        // while (true)
        // {
        //     bytesRead = socket.read(buffer[position .. $]);
        //     position += bytesRead
        // }
        theReactor.stop();
    }
}

HttpRequest createHttpRequest()
{
    enum websocketGuid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

    HttpRequest request;

    request.method = request.Method.get;
    request.path = url.path;
    request.addHeader("Host", url.hostname);
    request.addHeader("Upgrade", "websocket");
    request.addHeader("Connection", "Upgrade");
    request.addHeader("Sec-WebSocket-Key", "x3JJHMbDL1EzLkh9GBhYDw==");
    request.addHeader("Sec-WebSocket-Version", "13");
    request.addHeader("Origin", "192.168.0.2");

    return request;
}

void fiber() @trusted
{
    auto connection = WebsocketConnection(url);
    connection.connect();

    auto request = createHttpRequest();
    connection.send(request);
}
