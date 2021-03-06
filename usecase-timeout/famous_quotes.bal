

import ballerina/http;
import ballerina/io;


endpoint http:Listener listener {
    port: 9090
};

endpoint http:Client legacyQuoteEP {
    url: "http://localhost:9095/legacy/quote/timeoutmock"

    // ToDo : Add timeout 
};





string  default_quote = "The difference between a strong man and a weak one is that the former does not give up after a defeat. - Woodrow Wilson";

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
              io:println("Backend invocation has timeout. Setting the default response.");
              res.setPayload("<<Default Quote >> " + default_quote);
          }
      }
      _ = caller->respond(res);
  }
}