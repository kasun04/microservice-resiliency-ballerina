import ballerina/http;
import ballerina/io;
import ballerina/runtime;
import ballerina/math; 

public  int counter = 1;
public  int retry_counter = 1;

endpoint http:Listener listener {
    port:9095
};

@http:ServiceConfig {basePath:"/legacy"}
service<http:Service> legacy_quote bind listener {
    @http:ResourceConfig {
        path: "/quote/circuitbreakermock",  methods: ["GET"]
    }
    getQuoteCircuitBreaker (endpoint caller, http:Request request) {
        http:Response response;
        string customTimeString = getRandomQuote(); 

        if (counter % 3 == 0) {
            io:println("Legacy Service : Behavior - Slow");
            runtime:sleep(1000);
            counter = counter + 1;
            response.setTextPayload(customTimeString);
            _ = caller -> respond(response);
        } else if (counter % 3 == 2) {
            counter = counter + 1;
            response.statusCode = 500;
            io:println("Legacy Service : Behavior - Faulty");
            response.setTextPayload("Internal error occurred while processing the request.");
            _ = caller -> respond(response);
        } else {
            io:println("Legacy Service : Behavior - Normal");
            counter = counter + 1;
            response.setTextPayload(customTimeString);
            _ = caller -> respond(response);
        }
    }


    @http:ResourceConfig{
        path: "/quote/timeoutmock",  methods: ["GET"]
    }
    getQuoteTimeout (endpoint caller, http:Request request) {
        http:Response response;
        io:println("Service is processing the request. Please wait.. ");
        runtime:sleep(8000);
        io:println("Service has processed the request!");
        string payload = getRandomQuote(); 
        _ = caller -> respond(payload);
    }

    @http:ResourceConfig{
        path: "/quote/retry",  methods: ["GET"]
    }
    getQuoteRetry (endpoint caller, http:Request request) {
        io:println("===== Legacy Quote service invoked! =====");
        http:Response response;
        if (retry_counter % 5 == 0) {
            string payload = getRandomQuote();
            retry_counter++;
            io:println("Request is processed successfully!");

            _ = caller -> respond(payload);
        } else {
            io:println("Server error occured! No response sent. ");
            retry_counter++;
        }
    }
    
    
}


function getRandomQuote () returns (string) {
    string[] quotes = [ "Many of life’s failures are people who did not realize how close they were to success when they gave up. - Thomas A. Edison\n",
                        "Believe you can and you’re halfway there. — Theodore Roosevelt\n",
                        "Be sure you put your feet in the right place, then stand firm. - Abraham Lincoln\n",
                        "Strive not to be a success, but rather to be of value. — Albert Einstein\n",
                        "A person who never made a mistake never tried anything new.—— Albert Einstein\n",
                        "We can easily forgive a child who is afraid of the dark; the real tragedy of life is when men are afraid of the light. — Plato\n"
                        ];

    int index = math:randomInRange(0, lengthof quotes); 
    string quote = quotes[index]; 
    return quote; 
}