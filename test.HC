#include "./prayer.HC"

U0 Main()
{
    //Request *request = RequestNew("GET", "httpforever.com");
    Request *request = RequestNew("GET", "127.0.0.1:10");
    U8 *response = RequestExecute(request);

    "Raw response:\n%s\n", response;
}

