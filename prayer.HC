#include "./idiaot.HC"

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
    I32 conn = NetConnect(route, port);

    // Now we try to read something :sob:
}

