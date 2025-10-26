class URL
{
    U8 *protocol;
    U8 *host;
    I32 port;
    U8 *route;
};

// Returns the protocol part of the url protocol://host[:port]/route
// If no protocol:// is present in the URL, returns http.
public U8 *GetProtocol(U8 *url)
{
    I64 protocolSeparatorLocation = FindSubStr(url, "://");

    if (protocolSeparatorLocation == -1)
        return "http";

    return GetSubStr(url, 0, protocolSeparatorLocation);
}

// Returns the host part of the url protocol://host[:port]/route
public U8 *GetHost(U8 *url)
{
    // Remove protocol from url
    I64 protocolSeparatorLocation = FindSubStr(url, "://");
    I64 protocolLength = StrLen(url) - protocolSeparatorLocation - 3;
    if (protocolSeparatorLocation != -1)
        url = GetSubStr(url, protocolSeparatorLocation+3, protocolLength);

    // Remove route from url
    I64 routeSeparatorLocation = FindChar(url, '/');
    if (routeSeparatorLocation != -1)
        url = GetSubStr(url, 0, routeSeparatorLocation);

    I64 separatorLocation = FindChar(url, ':');

    if (separatorLocation == -1)
        return url;

    return GetSubStr(url, 0, separatorLocation);
}

// Returns the port part of the url protocol://host[:port]/route
// If no [:port] is specified, default port of 80 is returned
public I32 GetPort(U8 *url)
{
    // Remove protocol from url
    I64 protocolSeparatorLocation = FindSubStr(url, "://");
    I64 protocolLength = StrLen(url) - protocolSeparatorLocation - 3;
    if (protocolSeparatorLocation != -1)
        url = GetSubStr(url, protocolSeparatorLocation+3, protocolLength);

    // Remove route from url
    I64 routeSeparatorLocation = FindChar(url, '/');
    if (routeSeparatorLocation != -1)
        url = GetSubStr(url, 0, routeSeparatorLocation);

    I64 separatorLocation = FindChar(url, ':');

    if (separatorLocation == -1)
        return 80;

    I64 offset = separatorLocation + 1;
    I64 length = StrLen(url) - offset;

    return AToI32(GetSubStr(url, offset, length));
}

// Returns the route part of the url protocol://host[:port]/route
// If no route is present, returns default / route
public U8 *GetRoute(U8 *url)
{
    // Remove protocol from url
    I64 protocolSeparatorLocation = FindSubStr(url, "://");
    I64 protocolLength = StrLen(url) - protocolSeparatorLocation - 3;
    if (protocolSeparatorLocation != -1)
        url = GetSubStr(url, protocolSeparatorLocation+3, protocolLength);

    I64 routeLocation = FindChar(url, '/');
    
    if (routeLocation == -1)
        return "/";

    return GetSubStr(url, routeLocation, StrLen(url)-routeLocation);
}

// Creates a new heap-allocated URL object from url
public URL *UrlNew(U8 *url)
{
    URL *urlobj = MAlloc(sizeof(URL))(URL *);
    urlobj->protocol = GetProtocol(url);
    urlobj->host = GetHost(url);
    urlobj->port = GetPort(url);
    urlobj->route = GetRoute(url);

    return urlobj;
}

