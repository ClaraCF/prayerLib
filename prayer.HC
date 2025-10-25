#include "./idiaot.HC"

#define BUFFER_SIZE 256

U0 Debug1(){}
U0 Debug2(){}
U0 Debug3(){}
U0 Debug4(){}
U0 Debug5(){}
U0 Debug6(){}
U0 Debug7(){}
U0 Debug8(){}
U0 Debug9(){}
U0 Debug10(){}

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

public class Request
{
    I32 sockfd;
    U8 *url;
    PtrVec *headers;
    Json *body;
};

public class Response
{
    U8 *raw;
    I32 statusCode;
    PtrVec *headers;
    U8 *content;
};

public U0 RequestAddLine(Request *request, U8 *line)
{
    U8 *header = StrPrint(NULL, "%s\r\n", line);
    PtrVecPush(request->headers, header);
    //Free(header);
}

public U0 RequestAddHeader(Request *request, U8 *key, U8 *value)
{
    U8 *header = StrPrint(NULL, "%s: %s", key, value);
    RequestAddLine(request, header);
    //Free(header);
}

public Request *RequestNew(U8 *requestType, U8 *url)
{
    U8 *addr = GetHost(url);
    I32 port = GetPort(url);

    // Stablish a connection with the target host
    I32 sockfd = NetConnect(addr, port);

    // Create a request object
    Request *request = MAlloc(sizeof(Request))(Request *);
    request->sockfd = sockfd;
    request->url = url;
    request->headers = PtrVecNew();
    request->body = JsonParse("{}");

    // Construct the request
    U8 *startLine = StrPrint(NULL, "%s / HTTP/1.1", requestType);
    RequestAddLine(request, startLine);
    RequestAddHeader(request, "Host", request->url);
    RequestAddHeader(request, "Connection", "close");

    return request;
}

private U8 *RequestReadBuffer(Request *request)
{
    U8 *response = "";
    U8 buffer[BUFFER_SIZE];
    I64 contentLength = 0;
    I64 bytesRead = -1;

    while (bytesRead != 0)
    {
        bytesRead = read(request->sockfd, buffer, BUFFER_SIZE-1);
        buffer[bytesRead+1] = 0;
        response = StrMerge(response, buffer);
    }

    return response;
}

private Response ResponseNew()
{

}

private Response ParseResponseBuffer(U8 *buffer)
{

}

//public Response RequestExecute(Request *request)
public U8 *RequestExecute(Request *request)
{
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

    else
        RequestAddLine(request, "");

    for (I64 i = 0; i < request->headers->size; i++)
    {
        U8 *line = PtrVecGet(request->headers, i);
        write(request->sockfd, line, StrLen(line));
    }

    // Now we try to read something :sob:
    U8 buffer[BUFFER_SIZE];
    I32 bytesRead = -1;

    //PtrVecRelease(request);
    //PtrVecClear(request);
    //Free(request);

    return RequestReadBuffer(request);
}

