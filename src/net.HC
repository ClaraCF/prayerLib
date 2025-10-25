// Returns the host part of the address host[:port] in addr
public U8 *GetHost(U8 *addr)
{
    I64 separatorLocation = FindChar(addr, ':');

    if (separatorLocation == -1)
        return addr;

    return GetSubStr(addr, 0, separatorLocation);
}

// Returns the port part of the address host[:port] in addr
// If no [:port] is specified, default port of 80 is returned
public I32 GetPort(U8 *addr)
{
    I64 separatorLocation = FindChar(addr, ':');

    if (separatorLocation == -1)
        return 80;

    I64 offset = separatorLocation + 1;
    I64 length = StrLen(addr) - offset;

    return AToI32(GetSubStr(addr, offset, length));
}

