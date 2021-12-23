@isTest
global class ZealynxHttpMockGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":"200","statusText":"OK","errorCount":"0","responses":[{"status":"200","statusText":"OK", "records": [{"isSuccess": true, "id": "1234", "token":"5678", "paymentToken":"ABCD", "status":"Approved", "authCode":"lskdjfslkjdf", "reference":"lskjdf"}]}]}');
        return res;
    }
}