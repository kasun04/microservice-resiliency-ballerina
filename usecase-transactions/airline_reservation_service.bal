import ballerina/io;
import ballerina/log;
import ballerina/http;
import ballerina/config;

endpoint http:Listener participantAirlineService {
    port:7070
};


@http:ServiceConfig {
    basePath:"/airline"
}
service<http:Service> AirlineService  bind participantAirlineService {

    @http:ResourceConfig {
        path:"/reservation"
    }
    bookAirline(endpoint caller, http:Request req) {
        http:Response res = new;
        transaction with oncommit = onCommit, onabort = onAbort {
            json reqJ = check req.getJsonPayload();
            if(reqJ.airline.toString() == "delta") {
                io:println(">>>>>>>>>> Airline reservation done. -> Name - "
                        + reqJ.full_name.toString() + ", Airline - " + reqJ.airline.toString());
                res.setPayload("Airline reserved!  " + untaint reqJ.full_name.toString() );
                _ = caller -> respond(res);
            } else {
                io:println(">>>>>>>>>> Airline reservation has failed. -> Cannot reserve airline : " + reqJ.airline.toString());
                res.setPayload("Airline reservation has failed!");
                res.statusCode = http:INTERNAL_SERVER_ERROR_500;
                _ = caller -> respond(res);
                abort;
            }
        }
    }
}


function onAbort(string transactionid) {
    log:printInfo("--- [On-abort] Airline reservation is CANCELLED. --- TXID " + transactionid);
}

function onCommit(string transactionid) {
    log:printInfo("--- [On-abort] Airline reservation is CONFIRMED. --- TXID " + transactionid);
}
