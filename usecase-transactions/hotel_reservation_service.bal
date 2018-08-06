import ballerina/io;
import ballerina/log;
import ballerina/http;
import ballerina/config;

endpoint http:Listener participantAirlineService {
    port:5050
};


@http:ServiceConfig {
    basePath:"/hotel"
}
service<http:Service> AirlineService  bind participantAirlineService {

    @http:ResourceConfig {
        path:"/reservation"
    }
    bookHotel(endpoint caller, http:Request req) {
        http:Response res;
        json reqJ = check req.getJsonPayload();


        transaction with oncommit = onCommit, onabort = onAbort {

            if (reqJ.hotel.toString() == "hilton") {
                json resJ = { fullName: reqJ.full_name.toString(), status: "Successful!"};
                res.setJsonPayload(untaint reqJ);

                io:println(">>>>>>>>>>> Hotel reservation done. -> Name - "
                        + reqJ.full_name.toString() + ", Hotel - " + reqJ.hotel.toString());

                _ = caller -> respond(res);
            } else {
                io:println(">>>>>>>>>> Hotel reservation has failed. -> Cannot reserve hotel : " + reqJ.hotel.toString());
                res.setPayload("Hotel reservation has failed!");
                res.statusCode = http:INTERNAL_SERVER_ERROR_500;
                _ = caller -> respond(res);
                abort;
            }

        }
    }
}


function onAbort(string transactionid) {
    log:printInfo("--- [On-abort] Hotel reservation is CANCELLED. --- TXID " + transactionid);
}

function onCommit(string transactionid) {
    log:printInfo("--- [On-Commit] Hotel reservation is CONFIRMED. --- TXID " + transactionid);
}

