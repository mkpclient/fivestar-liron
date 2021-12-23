@isTest
public with sharing class MarketNewTriggerTest {
    @isTest
    private static void testInsert() {
        Product2 testProd = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePriceBookEntry(testProd.Id);
        Market__c testMarket = BoomTestHelpers.generateMarket(testPbe.Pricebook2Id, false);
        Market__c queriedMkt = [SELECT Id,Price_Book__c FROM Market__c WHERE Id = :testMarket.Id LIMIT 1];
        System.assertEquals(true, queriedMkt.Price_Book__c == testPbe.Pricebook2Id, 'Pricebook Ids do not match on insert');
    }

    @isTest
    private static void testUpdate() {
        Product2 testProd = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePriceBookEntry(testProd.Id);
        Market__c testMarket = BoomTestHelpers.generateMarket(testPbe.Pricebook2Id, false);
        testMarket.Price_Book__c = null;
        update testMarket;
        Market__c queriedMkt = [SELECT Id,Price_Book__c FROM Market__c WHERE Id = :testMarket.Id LIMIT 1];
        System.assertEquals(true, queriedMkt.Price_Book__c == testPbe.Pricebook2Id, 'Pricebook Ids do not match on update');
    }
}