@isTest
public with sharing class ManageChargesCreditsTest {
    @isTest
    private static void testMethod1() {
        List<Id> ccIds = new List<Id>();
        Product2 testProd = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePriceBookEntry(testProd.Id);
        Account testAcc = BoomTestHelpers.generateAccount();
        Market__c testMkt = BoomTestHelpers.generateMarket(testPbe.Pricebook2Id, true);
        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        Opportunity testOppt = BoomTestHelpers.generateOpportunity(testAcc.Id, testMkt.Id, testCtc.Id);
        SalesOrder__c testSo = BoomTestHelpers.generateTestBoomOrder(testOppt.Id);
        for(Integer i = 0; i < 3; i++) {
            ccIds.add(BoomTestHelpers.generateAdditionalChargeCredit(testProd.Id).Id);
        }
        Test.startTest();
        String retVal = ManageChargesCreditsController.addNewOrderChargesCredits(ccIds, testSo.Id);
        System.assertEquals(false, retVal.contains('Error'), 'Error returned from addNewOrderChargesCredits');
        Test.stopTest();
    }
}