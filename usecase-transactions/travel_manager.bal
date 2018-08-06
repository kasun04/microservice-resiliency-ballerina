

import ballerina/http;
import ballerina/io;
import ballerina/config;
import ballerinax/kubernetes;
import ballerina/log;



@final string AIRLINE_HOST = config:getAsString("AIRLINE_HOST", default = "127.0.0.1");
@final int AIRLINE_PORT = config:getAsInt("AIRLINE_PORT", default = 7070);

@final string HOTEL_HOST = config:getAsString("HOTEL_HOST", default = "127.0.0.1");
@final int HOTEL_PORT = config:getAsInt("HOTEL_PORT", default = 5050);

endpoint http:Listener initiatorEP {
    port:6060
};


endpoint http:Client participantAirlineService {
    url: "http://" + AIRLINE_HOST + ":" + AIRLINE_PORT
};

endpoint http:Client participantHotelService {
    url: "http://" + HOTEL_HOST + ":" + HOTEL_PORT
};


@http:ServiceConfig {
    basePath:"/travel"
}
service<http:Service> TravelMgtInitiator bind initiatorEP {

    @http:ResourceConfig {
        path:"/"
    }
    bookTrip (endpoint caller, http:Request req) {

        http:Response airlineRes = new;
        http:Response hotelRes = new;
        http:Request hotelReq = new;
        http:Response finalResponse = new;

        json reqJ = check req.getJsonPayload();
        string name = reqJ.full_name.toString();
        string checkIn = reqJ.start_date.toString();
        string checkOut = reqJ.end_date.toString();
        string hotelName = reqJ.hotel.toString();
        json hotelReqJ = { fullName: name, checkIn: checkIn, checkOut: checkOut, hotel: hotelName };
        hotelReq.setJsonPayload(untaint hotelReqJ);
        string reservationStatus;

        io:println(" Hotel " + HOTEL_HOST + " - port " + HOTEL_PORT);

        transaction {
            io:println("Started : Hotel Service Invocation");
            hotelRes = check participantHotelService -> post("/hotel/reservation", hotelReq);
            if (hotelRes.statusCode != 200) {
                io:println(">> Error invoking Hotel Service.");
                reservationStatus = reservationStatus + " : Hotel Reservation Failed";
                json failureMsg = {status:reservationStatus};
                finalResponse.setJsonPayload(failureMsg);
                _ = caller -> respond(finalResponse);
            }
            io:println("Complete : Hotel Service Invocation");

            io:println("Started : Airline Service Invocation");
            airlineRes = check participantAirlineService -> post("/airline/reservation", untaint req);
            if (airlineRes.statusCode != 200) {
                io:println(">> Error invoking Airline Service.");
                reservationStatus = reservationStatus + " : Airline Reservation Failed.";
                json failureMsg = {status:reservationStatus};

                finalResponse.setJsonPayload(failureMsg);
                _ = caller -> respond(finalResponse);
            }
            io:println("Completed : Airline Service Invocation");

            io:println("All service calls are completed.");
            if (hotelRes.statusCode == 200 && airlineRes.statusCode == 200) {
                json successMsg = {status:"Airline and Hotel reservations successful!"};
                finalResponse.setJsonPayload(successMsg);
                _ = caller -> respond(finalResponse);
            }
        }
    }
}


function onAbort(string transactionid) {
    log:printInfo("--- onAbort --- TXID " + transactionid);
}
function onCommit(string transactionid) {
    log:printInfo("--- onCommit --- TXID " + transactionid);
}


