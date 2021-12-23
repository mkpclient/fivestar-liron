@isTest
public with sharing class DeleteBoomPaymentMethodControllerTest {
    @isTest
    private static void testDefaultController() {
        Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

        Account testAcc = BoomTestHelpers.generateAccount();
        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        
        testCtc.MX_Customer_Id__c = '12345';
        update testCtc;
        
        Payment_Method__c testPm1 = BoomTestHelpers.generateTestPmtMethod(testCtc.Id, true);
        Payment_Method__c testPm2 = BoomTestHelpers.generateTestPmtMethod(testCtc.Id, true);

        testPm1.ExternalId__c = '123456';
        update testPm1;
        


        List<Id> pmIds = new List<Id>{testPm1.Id, testPm2.Id};

        List<Payment_Method__c> pms = [SELECT Id, Contact__c, MX_Customer_Id__c, ExternalId__c FROM Payment_Method__c WHERE Id IN :pmIds];

        ApexPages.StandardController sc1 = new ApexPages.StandardController(pms[0]);
        ApexPages.StandardController sc2 = new ApexPages.StandardController(pms[1]);
        DeleteBoomPaymentMethodController controller1 = new DeleteBoomPaymentMethodController(sc1);
        DeleteBoomPaymentMethodController controller2 = new DeleteBoomPaymentMethodController(sc2);


        controller1.doDelete();
        controller2.doDelete();

        List<Payment_Method__c> pmList = [SELECT Id FROM Payment_Method__c WHERE Id IN :pmIds];

        System.assertEquals(0, pmList.size(), 'All payment methods should be deleted');

    }
}