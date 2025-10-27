/* Make an HTTP Request to restful-api.dev.
 * Visit https://restful-api.dev/ for reference.
*/

#include "./prayer.HC"

I32 Main()
{
    // Make a GET request to list all objects
    U8 *url = "http://api.restful-api.dev/objects";
    
    Request *request = RequestNew("GET", url);
    Response *response = RequestExecute(request);

    "Code: %d\n", response->statusCode;
    "Reason: %s\n", response->reason;
    "Lol: %d %d\n", StrLen(response->raw), sizeof(response->raw);
    "Raw: %s\n", response->raw;

    return 0;
}

