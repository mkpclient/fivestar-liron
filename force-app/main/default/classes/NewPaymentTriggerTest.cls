@isTest
public with sharing class NewPaymentTriggerTest {
    @IsTest(SeeAllData=true) 
    static void testNewPayment() {
        Account testAcc = BoomTestHelpers.generateAccount();
        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        Product2 testPdc = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePriceBookEntry(testPdc.Id);
        Market__c testMkt = BoomTestHelpers.generateMarket(testPbe.Pricebook2Id, true);
        Opportunity testOpp = BoomTestHelpers.generateOpportunity(testAcc.Id, testMkt.Id, testCtc.Id);
        SalesOrder__c testSo = BoomTestHelpers.generateTestBoomOrder(testOpp.Id);
        SalesOrderProductLine__c testProdLine = BoomTestHelpers.generateBoomProductLine(testSo.Id, testPbe);
        Payment_Method__c testPmtMethod = BoomTestHelpers.generateTestPmtMethod(testCtc.Id, false);
        Test.startTest();
        Payment__c testPmt = BoomTestHelpers.generateTestPayment(testSo.Id, testAcc.Id, testCtc.Id, testPmtMethod.Id, 40, 'Completed');
        Payment__c testPmt2 = BoomTestHelpers.generateTestPayment(testSo.Id, testAcc.Id, testCtc.Id, testPmtMethod.Id, 10, 'Scheduled');
        testPmt2.Status__c = 'Completed';
        update testPmt2; 
        String expectedPmtName = 'Payment for Sales Order ' + [SELECT Name FROM SalesOrder__c WHERE Id = :testSo.Id][0].Name;
        String returnedPmtName = [SELECT Name FROM Payment__c WHERE Id = :testPmt.Id][0].Name;

        testSo.DateReleased__c = (Date) System.today();
        testSo.Released__c = System.Now().addHours(-5);
        update testSo;
        Payment__c testPmt3 = BoomTestHelpers.generateTestPayment(testSo.Id, testAcc.Id, testCtc.Id, testPmtMethod.Id, 40, 'Completed');

        System.assertEquals(expectedPmtName, returnedPmtName, 'Payment name does not match expected name');
        Test.stopTest();
    }
}