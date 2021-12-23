@isTest
public with sharing class PaymentMethodTriggerTest {
    @isTest
    private static void testMethod1() {
        Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

        Account testAcc = BoomTestHelpers.generateAccount();
        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        testCtc.MX_Customer_Id__c = '12345';
        update testCtc;
        Payment_Method__c testPm1 = BoomTestHelpers.generateTestPmtMethod(testCtc.Id, true);
        Payment_Method__c testPm2 = BoomTestHelpers.generateTestPmtMethod(testCtc.Id, true);
        Payment_Method__c newPm1 = [SELECT Id, Default__c FROM Payment_Method__c WHERE Id = :testPm1.Id LIMIT 1];
        System.assertEquals(false, newPm1.Default__c, 'Default__c should be false');

        newPm1.Default__c = true;
        update newPm1;

        Payment_Method__c newPm2 = [SELECT Id, Default__c FROM Payment_Method__c WHERE Id = :testPm2.Id LIMIT 1];
        System.assertEquals(false, newPm2.Default__c, 'Default__c should be false');
        newPm2.ExternalId__c = '123456';
        update newPm2;
    }
}