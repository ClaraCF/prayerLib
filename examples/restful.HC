/* Make an HTTP Request to restful-api.dev.
 * Visit https://restful-api.dev/ for reference.
*/

#include "./prayer.HC"

I32 Main()
{
    /* Make a GET request to list all objects */

    // API Endpoint
    U8 *url = "http://api.restful-api.dev/objects";
    
    // We will make a GET request
    Request *request = RequestNew("GET", url);

    // Execute the request and store the result in "response"
    Response *response = RequestExecute(request);


    // Print the response status code and reason
    "* Code: %d\n", response->statusCode;
    "* Reason: %s\n", response->reason;

    // Print all headers in the response one by one
    "* Headers:\n";
    for (I64 i = 0; i < response->headers->size; i++) {
        Header *header = PtrVecGet(response->headers, i);
        "    - %s: %s\n", header->key, header->value;
    }

    // Print the response content type, length and content
    "* Content-Type: %s\n", response->contentType;
    "* Content-Length: %d\n", response->contentLength;
    "* Content:\n%s\n", response->content;

    // Print the whole raw response
    "\n* Raw:\n%s\n", response->raw;

    // IMPORTANT: Release the memory
    RequestRelease(request);
    ResponseRelease(response);

    return 0;
}

