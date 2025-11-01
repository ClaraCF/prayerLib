#include "./src/wheel.HC"
#include "./src/net.HC"

#define BUFFER_SIZE 1024

public class Header {
    U8 *key;
    U8 *value;
};

public class Request {
    I32 sockfd;
    U8 *url;
    U8 *requestLine;
    PtrVec *headers;
    Json *body;
};

public class Response {
    U8 *raw;            // Set by RequestExecute()
    I32 statusCode;     // Set by ParseStatusLine()
    U8 *reason;         // Set by ParseStatusLine()
    PtrVec *headers;    // Set by ParseResponseHeaders()
    U8 *contentType;    // Set by ParseResponseContent()
    I64 contentLength;  // Set by ParseResponseContent()
    U8 *content;        // Set by ParseResponseContent()
};

// This function will free the memory of a Header
// and all of its internal structures
public U0 HeaderRelease(Header *header) {
    Free(header->key);
    Free(header->value);
    Free(header);
    header = NULL;
}

// This funcion will free the memory of a Request
// and all of its internal structures
public U0 RequestRelease(Request *request) {
    Free(request->url);
    PtrVecRelease(request->headers);
    JsonRelease(request->body);
    Free(request);
    request = NULL;
}

// This funcion will free the memory of a Response
// and all of its internal structures
public U0 ResponseRelease(Response *response) {
    Free(response->raw);
    Free(response->reason);
    PtrVecRelease(response->headers);
    Free(response->contentType);
    Free(response->content);
    Free(response);
    response = NULL;
}

public Header *HeaderNew(U8 *key = NULL, U8 *value = NULL) {
    Header *header = MAlloc(sizeof(Header))(Header *);
    header->key = key;
    header->value = value;
    return header;
}

// TODO: PtrVecFindHeader should check for key AND value
// Implement a different PtrVecFindHeaderByKey.

/* Search vec for header.
 * Returns the index where header is located in vec.
 * Returns -1 if not found
*/
private I64 PtrVecFindHeader(PtrVec* vec, Header *header) {
    for (I64 i = 0; i < vec->size; i++) {
        Header *vecHeader = PtrVecGet(vec, i)(Header *);

        if (!StrCmp(vecHeader->key, header->key))
            return i;
    }

    return -1;
}

/* Search vec for header.
 * Returns 1 if it exists in vec.
 * Returns 0 otherwise.
*/
private Bool PtrVecHeaderExists(PtrVec *vec, Header *header) {
    return PtrVecFindHeader(vec, header) != -1;
}

/* Adds a header to the request.
 * Returns 1 on success.
 * If the header already exists, does nothing and returns 0.
*/
public Bool RequestAddHeader(Request *request, Header *header) {
    if (PtrVecHeaderExists(request->headers, header))
        return 0;

    PtrVecPush(request->headers, header);

    return 1;
}

// TODO: RemoveHeader should use RequestRemoveHeader matching key AND value
// Implement a different RequestRemoveHeaderByKey

/* Removes a header from the request, matching by key.
 * Returns 1 on success, 0 if not found.
 * If freeMem is TRUE, function will call Free() on the header before popping it off
   the PtrVec to avoid leaking memory in cases when uses a different Header instance with
   the same value for "key".
*/
public Bool RequestRemoveHeader(Request *request, Header *header, Bool freeMem = FALSE) {
    I64 idx = PtrVecFindHeader(request->headers, header);
    
    if (idx == -1)
        return 0;

    if (freeMem)
        Free(PtrVecGet(request->headers, idx));

    PtrVecPopIdx(request->headers, idx);

    return 1;
}

public Request *RequestNew(U8 *requestType, U8 *url) {
    U8 *host = GetHost(url);
    I32 port = GetPort(url);
    U8 *route = GetRoute(url);

    // Stablish a connection with the target host
    I32 sockfd = NetConnect(host, port);

    // Create a request object
    Request *request = MAlloc(sizeof(Request))(Request *);
    request->sockfd = sockfd;
    request->url = StrNew(url);
    request->headers = PtrVecNew();
    request->body = NULL;

    // Construct the request
    request->requestLine = StrPrint(NULL, "%s %s HTTP/1.1\r\n", requestType, route);
    Header *hostHeader = HeaderNew("Host", StrNew(host));
    Header *connHeader = HeaderNew("Connection", "close");

    RequestAddHeader(request, hostHeader);
    RequestAddHeader(request, connHeader);
    
    Free(host);
    Free(route);

    return request;
}

// Returns the Content-Type of the Response as a U8* string
// For example, "application/json".
public U8 *ResponseGetContentType(Response *response) {
    return response->contentType;
}

// Returns the raw http response as a U8* string
public U8 *ResponseGetRaw(Response *response) {
    return response->raw;
}

// Returns the status code of the response
public I32 ResponseGetStatusCode(Response *response) {
    return response->statusCode;
}
    
// Returns the reason of the response as a U8* string
public U8 *ResponseGetReason(Response *response) {
    return response->reason;
}

// Returns a PtrVec* with the headers for a Request
public PtrVec *RequestGetHeaders(Request *request) {
    return request->headers;
}

// Returns a PtrVec* with the headers for a Response
public PtrVec *ResponseGetHeaders(Response *response) {
    return response->headers;
}

// Searches for header with key in a Request.
// Returns a pointer to that header.
// Returns NULL if not found
public Header *RequestGetHeader(Request *request, U8 *key) {
    Header *header = HeaderNew(key);
    I64 idx = PtrVecFindHeader(request->headers, header);
    if (idx == -1)
        return NULL;
    Free(header);
    return PtrVecGet(request->headers, idx);
}

// Searches for header with key in a Response.
// Returns a pointer to that header.
// Returns NULL if not found
public Header *ResponseGetHeader(Response *response, U8 *key) {
    Header *header = HeaderNew(key);
    I64 idx = PtrVecFindHeader(response->headers, header);
    Free(header);

    if (idx == -1)
        return NULL;

    return PtrVecGet(response->headers, idx);
}

// Sets the User-Agent for the request.
// If User-Agent is already set, it replaces it.
// Returns 1 on success, 0 on failure.
public Bool RequestSetUserAgent(Request *request, U8 *userAgent) {
    Header *header = HeaderNew("User-Agent");
    RequestRemoveHeader(request, header, TRUE);
    Free(header);
    return RequestAddHeader(request, HeaderNew("User-Agent", userAgent));
}

// Sets the Authorization header for the request.
// If it is already set, replaces it.
// Returns 1 on success, 0 on failure.
public Bool RequestSetAuthorization(Request *request, U8 *auth) {
    Header *header = HeaderNew("Authorization");
    RequestRemoveHeader(request, header, TRUE);
    Free(header);
    return RequestAddHeader(request, HeaderNew("Authorization", auth));
}

// Sets the Accept header for the request.
// If it is already set, replaces it.
// Returns 1 on success, 0 on failure.
public Bool RequestSetAccept(Request *request, U8 *accept) {
    Header *header = HeaderNew("Accept");
    RequestRemoveHeader(request, header, TRUE);
    Free(header);
    return RequestAddHeader(request, HeaderNew("Accept", accept));
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
public Bool RequestAddAccept(Request *request, U8 *accept) {
    Header *header = RequestGetHeader(request, "Accept");

    if (!header) {
        header = HeaderNew("Accept", accept);
        RequestAddHeader(request, header);
        return 1;
    }

    header->value = StrPrint(NULL, "%s, %s", header->value, accept);
}

private U8 *RequestReadBuffer(Request *request) {
    U8 *response = NULL, *bufStr = NULL;
    U8 buffer[BUFFER_SIZE];
    I64 bytesRead = -1;

    while (bytesRead != 0) {
        bytesRead = read(request->sockfd, buffer, BUFFER_SIZE-1);
        buffer[bytesRead+1] = 0;
        bufStr = StrNew(buffer);
        response = StrMerge(response, bufStr);
    }

    Free(bufStr);

    return response;
}

private Response *ResponseNew() {
    Response *response = MAlloc(sizeof(Response))(Response *);
    response->raw = NULL;
    response->statusCode = 0;
    response->reason = NULL;
    response->headers = PtrVecNew();
    response->contentType = NULL;
    response->content = NULL;

    return response;
}

private U0 ParseResponseLine(Response *response, U8 *buffer) {
    U8 *string = StrNew(buffer);

    I64 responseLineIdx = FindChar(string, '\n');
    U8 *responseLine = GetSubStr(string, 0, responseLineIdx-1);

    // Remove the protocol HTTP/1.1 from the response line
    I64 protocolIdx = FindChar(responseLine, ' ');
    responseLine = GetSubStr(responseLine, protocolIdx+1, StrLen(responseLine)-protocolIdx-1);

    I64 statusCodeIdx = FindChar(responseLine, ' ');
    U8 *statusCode = GetSubStr(responseLine, 0, statusCodeIdx);

    // Remove the status code from the response line
    responseLine = GetSubStr(responseLine, statusCodeIdx+1, StrLen(responseLine)-statusCodeIdx-1);

    response->statusCode = AToI32(statusCode);
    response->reason = StrNew(responseLine);

    Free(string);
    Free(responseLine);
    Free(statusCode);
}

private U0 ParseResponseHeaders(Response *response, U8 *buffer) {
    PtrVec *lines = SplitStr(buffer, "\r\n");

    // Ignore first line as it's the http response line
    for (I64 i = 1; i < lines->size; i++) {
        U8 *line = PtrVecGet(lines, i);
        if (StrLen(line) != 0) {
            PtrVec *split = SplitStr(line, ": ");
            U8 *key = PtrVecGet(split, 0);
            U8 *value = PtrVecGet(split, 1);
            Header *header = HeaderNew(key, value);
            PtrVecPush(response->headers, header);
        }

        else
            break;
    }

    PtrVecRelease(lines);
}

private U0 ParseResponseContent(Response *response, U8 *buffer) {
    PtrVec *lines = SplitStr(buffer, "\r\n");

    I64 contentIdx = 0;

    // Skip all the request header
    for (I64 i = 0; i < lines->size; i++) {
        U8 *line = PtrVecGet(lines, i);
        if (StrLen(line) == 0) {
            contentIdx = ++i;
            Free(line);
            break;
        }

        Free(line);
    }

    if (contentIdx < lines->size) {
        U8 *line = PtrVecGet(lines, contentIdx);
        response->contentLength = strtoll(line, NULL, 16);
        Free(line);
    }

    else
        response->contentLength = 0;

    I64 totalRead = 0;
    U8 *content = "";

    // Skip one line (content length)
    for (I64 i = contentIdx+1; i < lines->size && totalRead != response->contentLength; i++) {
        U8 *line = PtrVecGet(lines, i);

        // Read byte by byte
        for (I64 j = 0; j < StrLen(line) && totalRead++ != response->contentLength; j++)
            content = StrPrint(NULL, "%s%c", content, line[j]);

        Free(line);
    }

    Header *contentType = ResponseGetHeader(response, "Content-Type");
    if (contentType != NULL)
        response->contentType = contentType->value;
    else
        // Default to text/plain
        response->contentType = "text/plain";

    response->content = content;

    PtrVecRelease(lines);
}

/* Will set the body of the request.
 * If a body was already set, replaces it and re-calculates Content-Length.
 * If the Json is invalid, does nothing and returns 0.
    - This means that if a body was already set and this function is called
       with a new, invalid body, the previous body and Content-Length will remain.
 * Otherwise returns 1;
*/
public Bool RequestSetBody(Request *request, Json *body) {
    if (JsonIsNull(body) || !JsonOk(body))
        return 0;

    U8 *bodyStr = JsonToString(body);
    U8 *len = StrPrint(NULL, "%d", StrLen(bodyStr));

    // This memory will have to be freed by the user.
    // Easily done by using RequestRelease(request).
    Header *contentType = HeaderNew("Content-Type", "application/json");
    Header *contentLength = HeaderNew("Content-Length", StrNew(len));

    /* If for whatever reason, the user of this library decides to
     * create a Header* for Content-Length, set it manually, then
     * calls this function, the memory will be freed, the pointer will
     * be deemed invalid and the developer will die.
    */

    // Replace the previous Content-Length header if it exists
    RequestRemoveHeader(request, contentLength, TRUE);
    RequestAddHeader(request, contentType);
    RequestAddHeader(request, contentLength);

    request->body = body;

    Free(bodyStr);
    Free(len);
}

public Response *RequestExecute(Request *request) {
    // User will have to ResponseRelease() this memory.
    Response *response = ResponseNew();

    // Send the request line first
    write(request->sockfd, request->requestLine, StrLen(request->requestLine));

    // Send the headers right after
    for (I64 i = 0; i < request->headers->size; i++) {
        Header *header = PtrVecGet(request->headers, i);
        U8 *line = StrPrint(NULL, "%s: %s\r\n", header->key, header->value);
        write(request->sockfd, line, StrLen(line));
        Free(line);
    } write(request->sockfd, "\r\n", 2);    // Empty line after headers

    // Send the body if applicable
    if (!JsonIsNull(request->body) && JsonOk(request->body)) {
        U8 *body = JsonToString(request->body);
        write(request->sockfd, body, StrLen(body));
        Free(body);
    }

    U8 *buffer = RequestReadBuffer(request);

    response->raw = StrNew(buffer);

    ParseResponseLine(response, buffer);
    ParseResponseHeaders(response, buffer);
    ParseResponseContent(response, buffer);

    Free(buffer);

    return response;
}

