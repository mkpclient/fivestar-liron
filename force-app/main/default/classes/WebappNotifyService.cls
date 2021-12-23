public class WebappNotifyService {
    
    @future (callout=true)
    public static void notifyFulfillmentUpdated(List<String> fulfillmentIds) {
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        if (runningInASandbox()) {
            req.setEndpoint('https://devspotlight.fivestarprofessional.com/api/sffulfillmentupdatetriggers');
        } else {
            req.setEndpoint('https://spotlight.fivestarprofessional.com/api/sffulfillmentupdatetriggers');
        }
        
        req.setMethod('POST');
        req.setCompressed(false);
        String ids = JSON.serialize(fulfillmentIds);
        req.setBody(ids);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        try {
                res = http.send(req);   
        } catch(System.CalloutException e) {
            System.debug('Callout error: '+ e);
        }
    }
    
    public static Boolean runningInASandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }    
}