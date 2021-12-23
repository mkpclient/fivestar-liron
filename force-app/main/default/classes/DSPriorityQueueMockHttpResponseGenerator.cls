@isTest
global class DSPriorityQueueMockHttpResponseGenerator implements HttpCalloutMock
{
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req)
    {
        String endpoint = req.getEndpoint().split('\\?')[0];
        if(endpoint.contains('List'))
        {
        	System.assertEquals('https://rs.refractivedialer.com/SubmitCallBackList.php', endpoint);
        }
        else
        {
        	System.assertEquals('https://rs.refractivedialer.com/SubmitCallBack.php', endpoint);
        }
        System.assertEquals('POST', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('');
        res.setStatusCode(201);
        return res;
    }
}