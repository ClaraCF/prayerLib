#include "./idiaot.HC"

#define BUFFER_SIZE 2048

// REQUEST(route, payload?);

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

public class Response
{
    I32 statusCode;
    U8 *headers;
    U8 *content;
};

public Response GET(U8 *route, U8 *data)
{
    // First we discern the address from the port
    U8 *addr = GetHost(route);
    I32 port = GetPort(route);

    // First we stablish a connection with the target route
    // public I32 NetConnect(U8 *addr, I32 port, Bool non_blocking=FALSE);
    I32 sockfd = NetConnect(addr, port);

    // Construct a GET request
    U8 body[BUFFER_SIZE];
    StrPrint(body, "GET / HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n", route);

    // Send the GET request
    write(sockfd, body, StrLen(body));

    // Now we try to read something :sob:
    U8 buffer[BUFFER_SIZE];
    I32 bytes_read = read(sockfd, buffer, BUFFER_SIZE-1);

    "Address: %s\nPort: %d\n", addr, port;
    "sockfd: %d\n", sockfd;
    "Bytes read: %d\n", bytes_read;
    "Buffer: %s\n", buffer;
}

