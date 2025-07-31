import ballerina/http;
import ballerinax/twilio;
import ballerina/log;

configurable string apiKey = ?;
configurable string apiSecret = ?;
configurable string accountSid = ?;

// SMS request record
type SmsRequest record {|
    string toNumber;
    string fromNumber;
    string messageBody;
|};

// SMS response record
type SmsResponse record {|
    boolean success;
    string message;
    string? messageSid?;
|};

service / on new http:Listener(8080) {
    
    isolated resource function post sendSms(SmsRequest smsRequest) returns SmsResponse|http:InternalServerError {
        
        log:printInfo("Starting SMS sending process");
        log:printInfo("SMS Request - To: " + smsRequest.toNumber + ", From: " + smsRequest.fromNumber);
        
        // Initialize Twilio client with ApiKeyConfig
        twilio:ConnectionConfig twilioConfig = {
            auth: {
                apiKey: apiKey,
                apiSecret: apiSecret,
                accountSid: accountSid
            }
        };
        
        twilio:Client|error twilioClientResult = new (twilioConfig);
        if twilioClientResult is error {
            string errorMessage = "Failed to initialize Twilio client: " + twilioClientResult.message();
            log:printError(errorMessage);
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: errorMessage
                }
            };
        }

        twilio:Client twilioClient = twilioClientResult;
        log:printInfo("Twilio client initialized successfully");
        
        // Create message request payload using request parameters
        twilio:CreateMessageRequest messageRequest = {
            To: smsRequest.toNumber,
            From: smsRequest.fromNumber,
            Body: smsRequest.messageBody
        };
        
        log:printInfo("Sending SMS message via Twilio API");
        
        // Send SMS message
        twilio:Message|error smsResponse = twilioClient->createMessage(messageRequest);
        
        if smsResponse is error {
            string errorMessage = "Failed to send SMS: " + smsResponse.message();
            log:printError("SMS sending failed - To: " + smsRequest.toNumber + ", Error: " + smsResponse.message());
            return <http:InternalServerError>{
                body: {
                    success: false,
                    message: errorMessage
                }
            };
        }
        
        string? messageSid = smsResponse?.sid;
        string? messageStatus = smsResponse?.status;
        
        // Log successful SMS sending
        if messageSid is string {
            log:printInfo("SMS sent successfully - Message SID: " + messageSid + ", To: " + smsRequest.toNumber);
        }
        
        if messageStatus is string {
            log:printInfo("SMS Status: " + messageStatus + " for Message SID: " + (messageSid ?: "N/A"));
        }
        
        log:printInfo("SMS sending process completed successfully");
        
        return {
            success: true,
            message: "SMS sent successfully",
            messageSid: messageSid
        };
    }
}