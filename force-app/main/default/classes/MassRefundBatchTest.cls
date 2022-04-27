@isTest
public with sharing class MassRefundBatchTest {
    @isTest
    public static void testBatch(){ 
        Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

        Account testacct = BoomTestHelpers.generateAccount();
        Contact testContact = BoomTestHelpers.generateContact(testacct.Id);
        testContact.MX_Customer_Id__c = '1234';
        update  testContact;
        Payment_Method__c testPm = BoomTestHelpers.generateTestPmtMethod(
        testContact.Id,
        false
        );
        Product2 testProd = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePricebookEntry(
        testProd.Id
        );
        Market__c testMkt = BoomTestHelpers.generateMarket(
        testPbe.Pricebook2Id,
        true
        );
        Opportunity testOpp = BoomTestHelpers.generateOpportunity(
        testacct.Id,
        testMkt.Id,
        testContact.Id
        );
        SalesOrder__c testSo = BoomTestHelpers.generateTestBoomOrder(testOpp.Id);
        List<SalesOrder__c> testSoList = new List<SalesOrder__c>();

        for(Integer i = 0; i < 50; i++) {
        testSoList.add(testSo.clone(false, true, false, false));
        }

        insert testSoList;
        SalesOrderProductLine__c testSoProd = BoomTestHelpers.generateBoomProductLine(
        testSo.Id,
        testPbe
        );
        testSo.Status_Picklist__c = 'Approved';

        update testSo;

        Payment__c testPayment = BoomTestHelpers.generateTestPayment(
        testSo.Id,
        testacct.Id,
        testContact.Id,
        testPm.Id,
        1,
        'Completed'
        );



        List<Id> contactIds = new List<Id>{testContact.Id};


        Test.startTest();
        Database.executeBatch(new MassRefundBatch(contactIds), 1);
        Test.stopTest();

        List<Payment__c> pmts = [SELECT Id FROM Payment__c WHERE Transaction_Type__c = 'Refund'];
        System.assertEquals(true, pmts.size() > 0);
    }
}
