
// ***************************************************
// Circuit Breaker Scenario
// ***************************************************

import ballerina/http;
import ballerina/io;

endpoint http:Listener listener {
    port: 9090
};

endpoint http:Client legacyQuoteEP {
    url: "http://localhost:9095/legacy/quote/circuitbreakermock",

    circuitBreaker: {
        // rollingWindow: {
        //     timeWindowMillis: 10000,
        //     bucketSizeMillis: 2000,
        //     requestVolumeThreshold: 0
        // },
        failureThreshold: 0.4,
        resetTimeMillis: 10000,
        statusCodes: [500, 501, 502]
    },
    timeoutMillis: 500
};


string  default_quote = "The difference between a strong man and a weak one is that the former does not give up after a defeat. - Woodrow Wilson\n";


@http:ServiceConfig {
  basePath: "/"
}
service<http:Service> famousQuotes bind listener {
  @http:ResourceConfig {
      path: "/quotes",
      methods: ["GET"]
  }
  getQuote (endpoint caller, http:Request request) {
      http:Response res;
      var v = legacyQuoteEP->get("/");
      match v {
          http:Response hResp => {
              string quote = check hResp.getTextPayload();
              res.setPayload(untaint quote);
          }
          error err => {
              io:println("Circuit Breaker breaker is open and invocation of the backend service is prevented.");
              res.setPayload("<<Default Quote >> " + default_quote);
          }
      }
      _ = caller->respond(res);
  }
}