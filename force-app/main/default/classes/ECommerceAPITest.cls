@isTest(seeAllData=true)
public with sharing class ECommerceAPITest {
    @isTest
    public static void testAPI() {
        Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ecommerce'; //Request URL
        req.httpMethod = 'POST';

        RestContext.request = req;
        RestContext.response= res;

        ECommerceAPI.eCommerceRequestResource ecr = new ECommerceAPI.eCommerceRequestResource().mock();
        ecr = ECommerceAPI.processBody(JSON.serialize(ecr),'test');      
    }
}