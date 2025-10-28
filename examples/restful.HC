/* Make an HTTP Request to restful-api.dev.
 * Visit https://restful-api.dev/ for reference.
*/

#include "./prayer.HC"

I32 Main()
{
    // Make a GET request to list all objects
    U8 *url = "http://api.restful-api.dev/objects";
    //U8 *url = "http://127.0.0.1/pene";
    
    Request *request = RequestNew("POST", url);

    RequestSetBody(request, JsonParse("{
                \"name\": \"Apple MacBook Pro 16\",
                \"data\": {
                    \"year\": 2019,
                    \"price\": 1849,
                    \"CPU model\": \"Intel Core i9\",
                    \"Hard disk size\": \"1 TB\"
                }
    }"));

    /*PtrVec *headers = request->headers;
    for (I64 i = 0; i < headers->size; i++) {
        Header *header = PtrVecGet(headers, i);
        "- %s: %s\n", header->key, header->value;
    //}*/

    Response *response = RequestExecute(request);

    "Code: %d\n", response->statusCode;
    "Reason: %s\n", response->reason;
    "Raw:\n%s\n", response->raw;

    return 0;
}

