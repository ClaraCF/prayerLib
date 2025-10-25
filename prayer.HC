#include "./idiaot.HC"

#define BUFFER_SIZE 2048

// Returns the host part of the address host[:port] in addr
private U8 *GetHost(U8 *addr)
{
    I64 separatorLocation = FindChar(addr, ':');

    if (separatorLocation == -1)
        return addr;

    return GetSubStr(addr, 0, separatorLocation);
}

// Returns the port part of the address host[:port] in addr
// If no [:port] is specified, default port of 80 is returned
private I32 GetPort(U8 *addr)
{
    I64 separatorLocation = FindChar(addr, ':');

    if (separatorLocation == -1)
        return 80;

    I64 offset = separatorLocation + 1;
    I64 length = StrLen(addr) - offset;

    return AToI32(GetSubStr(addr, offset, length));
}

public class Header
{
    U8 *key;
    U8 *value;
};

public class Request
{
    I32 sockfd;
    U8 *url;
    PtrVec *headers;
    U8 *auth;
    Json *body;
};

public class Response
{
    I32 statusCode;
    U8 *headers;
    U8 *content;
};

public U0 RequestAddLine(Request *request, U8 *line)
{
    U8 *header = MAlloc(sizeof(U8) * (StrLen(line) + 3));
    StrPrint(header, "%s\r\n", line);

    PtrVecPush(request->headers, header);
    Free(header);
}

public U0 RequestAddHeader(Request *request, U8 *key, U8 *value)
{
    U8 *header = MAlloc(sizeof(U8) * (StrLen(key) + StrLen(value) + 5));
    StrPrint(header, "%s: %s", key, value);

    RequestAddLine(request, header);
    Free(header);
}

public Request *CreateRequest(U8 *requestType, U8 *url)
{
    U8 *addr = GetHost(url);
    I32 port = GetPort(url);

    // Stablish a connection with the target host
    I32 sockfd = NetConnect(addr, port);

    // Create a request object
    Request *request = MAlloc(sizeof(Request));
    request->sockfd = sockfd;
    request->url = url;
    request->headers = PtrVecNew(0);
    request->auth = "";
    request->body = JsonParse("{}");

    // Construct the request
    U8 *startLine = StrPrint(NULL, "%s / HTTP/1.1", requestType);
    RequestAddLine(request, startLine);
    RequestAddHeader(request, "Host", request->url);
    RequestAddHeader(request, "Authorization", request->auth);
    RequestAddHeader(request, "Connection", "close");

    return request;
}

public U0 GET(U8 *url, U8 *data = "{}")
{
    Request *request = CreateRequest("GET", url);
    request->body = JsonParse(data);

    if (!JsonIsNull(request->body) && JsonOk(request->body))
    {
        U8 *body = JsonToString(request->body);
        U8 *len;
        I64ToStr(len, StrLen(body));

        RequestAddHeader(request, "Content-Type", "application/json");
        RequestAddHeader(request, "Content-Length", len);
        RequestAddLine(request, "");
        RequestAddLine(request, body);
    }

    // Send the GET request
    for (I64 i = 0; i < PtrVecCapacity(request->headers); i++)
    {
        U8 *line = PtrVecGet(request, i);
        write(request->sockfd, line, StrLen(line));
    }

    // Now we try to read something :sob:
    U8 buffer[BUFFER_SIZE];
    I32 bytes_read = read(request->sockfd, buffer, BUFFER_SIZE-1);

    "URL: %s\n", url;
    "Bytes read: %d\n", bytes_read;
    "Buffer:\n%s\n", buffer;

    PtrVecRelease(request);
    PtrVecClear(request);
    Free(request);
}

