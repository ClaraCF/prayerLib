#include "./src/wheel.HC"
#include "./src/net.HC"

#define BUFFER_SIZE 256

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

