@isTest
public with sharing class BoomOrderInvoiceWithAttachmentTest {
    @isTest
    private static void testMethod1() {
        Account testAcc = BoomTestHelpers.generateAccount();
        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        Product2 testPdc = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePriceBookEntry(testPdc.Id);
        Market__c testMkt = BoomTestHelpers.generateMarket(testPbe.Pricebook2Id, true);
        Opportunity testOpp = BoomTestHelpers.generateOpportunity(testAcc.Id, testMkt.Id, testCtc.Id);
        SalesOrder__c testSo = BoomTestHelpers.generateTestBoomOrder(testOpp.Id);
        SalesOrderProductLine__c testProdLine = BoomTestHelpers.generateBoomProductLine(testSo.Id, testPbe);
        Payment_Method__c testPmtMethod = BoomTestHelpers.generateTestPmtMethod(testCtc.Id, false);
        Payment__c testPmt = BoomTestHelpers.generateTestPayment(testSo.Id, testAcc.Id, testCtc.Id, testPmtMethod.Id, 50, 'Completed');
        Test.startTest();
        BoomOrderInvoiceWithAttachment.sendEmailWithAttachment(new List<Id>{testSo.Id});
        Test.stopTest();
    }

    @isTest 
    static void send_one_hour_later_email() {
        Account testAcc = BoomTestHelpers.generateAccount();
        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        Product2 testPdc = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePriceBookEntry(testPdc.Id);
        Market__c testMkt = BoomTestHelpers.generateMarket(testPbe.Pricebook2Id, true);
        Opportunity testOpp = BoomTestHelpers.generateOpportunity(testAcc.Id, testMkt.Id, testCtc.Id);
        SalesOrder__c testSo = BoomTestHelpers.generateTestBoomOrder(testOpp.Id);
        SalesOrderProductLine__c testProdLine = BoomTestHelpers.generateBoomProductLine(testSo.Id, testPbe);
        Payment_Method__c testPmtMethod = BoomTestHelpers.generateTestPmtMethod(testCtc.Id, false);
        Payment__c testPmt = BoomTestHelpers.generateTestPayment(testSo.Id, testAcc.Id, testCtc.Id, testPmtMethod.Id, 50, 'Completed');

        SalesOrder__c order = [SELECT Id FROM SalesOrder__c];
        Test.startTest();
        BoomPDFOneHourBatch batch = new BoomPDFOneHourBatch(new List<String>{order.Id});
        Database.executeBatch(batch);
    }
}