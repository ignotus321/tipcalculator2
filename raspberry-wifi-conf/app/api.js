var path = require("path"),
    util = require("util"),
    express = require("express"),
    bodyParser = require('body-parser'),
    config = require("../config.json"),
    exec    = require("child_process").exec,
    http_test = config.http_test_only;

// Helper function to log errors and send a generic status "SUCCESS"
// message to the caller
function log_error_send_success_with(success_obj, error, response) {
    if (error) {
        console.log("ERROR: " + error);
        response.send({ status: "ERROR", error: error });
    } else {
        success_obj = success_obj || {};
        success_obj["status"] = "SUCCESS";
        response.send(success_obj);
    }
    response.end();
}

/*****************************************************************************\
    Returns a function which sets up the app and our various routes.
\*****************************************************************************/
module.exports = function (wifi_manager, callback) {
    var app = express();

    // Configure the app
    app.set("trust proxy", true);

    // Setup static routes to public assets
    app.use(bodyParser.json());

    //is this the post that awaits the response we need?
    app.post("/api/enable_wifi", function (request, response) {
        var conn_info = {
            wifi_ssid: request.body.wifi_ssid,
            wifi_passcode: request.body.wifi_passcode,
        };

        // TODO: If wifi did not come up correctly, it should fail
        // currently we ignore ifup failures.
        wifi_manager.enable_wifi_mode(conn_info, function (error) {
            if (error) {
                console.log("Enable Wifi ERROR: " + error);
                console.log("Attempt to re-enable AP mode");
                wifi_manager.enable_ap_mode(config.access_point.ssid, function (error) {
                    console.log("... AP mode reset");
                });
                response.redirect("/");
            }else{
                console.log("Wifi - checking dns"); 
                var dns = require('dns');
                dns.lookupService('8.8.8.8', 53, function(err, hostname, service){
                  console.log(hostname, service);
                    // google-public-dns-a.google.com domain
                    if(err){
                        console.log("Enable Wifi ERROR: " + err);
                        console.log("Attempt to re-enable AP mode");
                        wifi_manager.enable_ap_mode(config.access_point.ssid, function (error) {
                            console.log("... AP mode reset");
                        });
                        response.redirect("/");

                    }else{
                        console.log("no dns error");
                    }
                });

            }

            // Success! - exit
            console.log("Wifi Enabled! - Exiting");
       
            process.exit(0);
        });
    });

    // Listen on our server
    app.listen(config.server.port);
}
