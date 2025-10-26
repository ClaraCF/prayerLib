#include "./src/wheel.HC"
#include "./src/net.HC"

#define BUFFER_SIZE 32

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
    U8 *reason;
    PtrVec *headers;
    Json *content;
};

private U0 RequestAddLine(Request *request, U8 *line)
{
    U8 *header = StrPrint(NULL, "%s\r\n", line);
    PtrVecPush(request->headers, header);
    //Free(header);   // BUG: If shit breaks comment out this line
}

// Adds a header to the request. key: value.
// Returns 1 on success.
// If the header already exists, does nothing and returns 0
public Bool RequestAddHeader(Request *request, U8 *key, U8 *value)
{
    U8 *header = StrMerge(key, ": ");
    if (FindSubStrInPtrVec(request->headers, header) != -1)
    {
        Free(header);
        return 0;
    }

    header = StrPrint(NULL, "%s: %s", key, value);
    RequestAddLine(request, header);

    //Free(header);   // BUG: If shit breaks comment this line
    return 1;
}

// Removes a header from the request.
// Returns 1 on success, 0 if not found.
public Bool RequestRemoveHeader(Request *request, U8 *key)
{
    U8 *header = StrMerge(key, ": ");
    I64 idx = FindSubStrInPtrVec(request->headers, header);
    
    if (idx == -1)
        return 0;

    PtrVecPopIdx(request->headers, idx);
    return 1;
}

public Request *RequestNew(U8 *requestType, U8 *url)
{
    // TODO: Handle protocols other than http
    //U8 *protocol = GetProtocol(url);

    U8 *host = GetHost(url);
    I32 port = GetPort(url);
    U8 *route = GetRoute(url);

    // Stablish a connection with the target host
    I32 sockfd = NetConnect(host, port);

    // Create a request object
    Request *request = MAlloc(sizeof(Request))(Request *);
    request->sockfd = sockfd;
    request->url = url;
    request->headers = PtrVecNew();
    request->body = NULL;

    // Construct the request
    U8 *requestLine = StrPrint(NULL, "%s %s HTTP/1.1", requestType, route);
    RequestAddLine(request, requestLine);
    RequestAddHeader(request, "Host", host);
    RequestAddHeader(request, "Connection", "close");

    return request;
}

// Sets the User-Agent for the request.
// If User-Agent is already set, it replaces it.
// Returns 1 on success, 0 on failure.
public Bool RequestSetUserAgent(Request *request, U8 *userAgent)
{
    RequestRemoveHeader(request, "User-Agent");
    return RequestAddHeader(request, "User-Agent", userAgent);
}

// Sets the Authorization header for the request.
// If it is already set, replaces it.
// Returns 1 on success, 0 on failure.
public Bool RequestSetAuthorization(Request *request, U8 *auth)
{
    RequestRemoveHeader(request, "Authorization");
    return RequestAddHeader(request, "Authorization", auth);
}

// Sets the Accept header for the request.
// If it is already set, replaces it.
// Returns 1 on success, 0 on failure.
public Bool RequestSetAccept(Request *request, U8 *accept)
{
    RequestRemoveHeader(request, "Accept");
    return RequestAddHeader(request, "Accept", accept);
}

/* Adds an additional accepted format to the Accept header.
 * If the header does not exist, creates it.
 * Will not check for duplicated entries. There is nothing
   stopping you from ending up with
   Accept: application/json, application/json, application/json, application/json
 * Returns 1 on success, 0 on failure.
 * Be thoughtful when adding entries to accept, as I have no plans of
   programming a "RequestRemoveAccept" anytime soon (cry).
 TODO: Program a RequestRemoveAccept();
*/
// TODO: Code this shit
public Bool RequestAddAccept(Request *request, U8 *accept)
{

}

private U8 *RequestReadBuffer(Request *request)
{
    U8 *response = NULL, *bufStr = NULL;
    U8 buffer[BUFFER_SIZE];
    I64 bytesRead = -1;

    while (bytesRead != 0)
    {
        bytesRead = read(request->sockfd, buffer, BUFFER_SIZE-1);
        buffer[bytesRead+1] = 0;
        bufStr = StrNew(buffer);
        response = StrMerge(response, bufStr);
    }

    return response;
}

private Response *ResponseNew()
{
    Response *response = MAlloc(sizeof(Response))(Response *);
    response->raw = "";
    response->statusCode = 0;
    response->reason = "";
    response->headers = PtrVecNew();
    response->content = NULL;

    // TODO: Handle freeing this memory
    return response;
}

private U0 ParseResponseLine(Response *response, U8 *buffer)
{
    response->raw = StrNew(buffer);

    I64 responseLineIdx = FindChar(buffer, '\n');
    U8 *responseLine = GetSubStr(buffer, 0, responseLineIdx-1);

    // Remove the protocol HTTP/1.1 from the response line
    I64 protocolIdx = FindChar(responseLine, ' ');
    responseLine = GetSubStr(responseLine, protocolIdx+1, StrLen(responseLine)-protocolIdx-1);

    I64 statusCodeIdx = FindChar(responseLine, ' ');
    U8 *statusCode = GetSubStr(responseLine, 0, statusCodeIdx);

    // Remove the status code from the response line
    responseLine = GetSubStr(responseLine, statusCodeIdx+1, StrLen(responseLine)-statusCodeIdx-1);

    response->statusCode = AToI32(statusCode);
    response->reason = StrNew(responseLine);

    //Free(responseLine); // BUG: If shit breaks check this line
    //Free(statusCode);
}

private U0 ParseResponseHeaders(Response *response, U8 *buffer)
{
    List *lines = SplitStr(buffer, "\r\n");

    // Remove the first line which is the response line
    ListDeque(lines);

    Bool headersDone = FALSE;
    U8 *line;

    while ((line = ListDeque(lines)(U8 *)) != NULL && !headersDone)
    {
        if (StrLen(line) != 0)
        {
            // TODO: Add the headers to the response
            // I am really tired
        }

        else headersDone = TRUE;
    }

    ListRelease(lines, NULL);

}

private U0 ParseResponseBody(Response *response, U8 *buffer)
{

}

public Response *RequestExecute(Request *request)
{
    Response *response = ResponseNew();

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

    U8 *buffer = RequestReadBuffer(request);
    ParseResponseLine(response, buffer);

    //PtrVecRelease(request);
    //PtrVecClear(request);
    //Free(request);
    Free(buffer);

    return response;
}

