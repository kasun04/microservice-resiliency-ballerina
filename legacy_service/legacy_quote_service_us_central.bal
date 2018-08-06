import ballerina/http;
import ballerina/io;
import ballerina/runtime;
import ballerina/math; 

public  int counter = 1;
public  int retry_counter = 1;

endpoint http:Listener listener {
    port:6067
};

@http:ServiceConfig { basePath:"/us-central/legacy" }
service<http:Service> legacyQuoteUSCENTRAL bind listener {

    @http:ResourceConfig{
        path: "/quote",  methods: ["GET"]
    }
    getQuote (endpoint caller, http:Request request) {
        http:Response response;
        io:println("Request is successfully processed! - US Central");
        string payload = getRandomQuote(); 
        _ = caller -> respond(payload);
    }
}


function getRandomQuote () returns (string) {
    string[] quotes = [ "Many of life’s failures are people who did not realize how close they were to success when they gave up. - Thomas A. Edison", 
                        "Believe you can and you’re halfway there. — Theodore Roosevelt", 
                        "Be sure you put your feet in the right place, then stand firm. - Abraham Lincoln", 
                        "Strive not to be a success, but rather to be of value. — Albert Einstein", 
                        "A person who never made a mistake never tried anything new.—— Albert Einstein", 
                        "We can easily forgive a child who is afraid of the dark; the real tragedy of life is when men are afraid of the light. —Plato" 
                        ];

    int index = math:randomInRange(0, lengthof quotes); 
    string quote = quotes[index]; 
    return quote; 
}