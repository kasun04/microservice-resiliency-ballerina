
// ***************************************************
// Loadbalancing Scenario
// ***************************************************


import ballerina/http;
import ballerina/io;


endpoint http:Listener listener {
    port: 9090
};

endpoint http:LoadBalanceClient lbLegacyQuote {
    targets: [
        { url: "http://localhost:6065/us-west/legacy/quote" },
        { url: "http://localhost:6066/us-east/legacy/quote" },
        { url: "http://localhost:6067/us-central/legacy/quote" }
    ],
    algorithm: http:ROUND_ROBIN,
    timeoutMillis: 5000
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
      var v = lbLegacyQuote->get("/");
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