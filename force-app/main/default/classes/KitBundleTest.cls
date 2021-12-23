@isTest
public with sharing class KitBundleTest {
    @isTest
    private static void testMethod1() {
        Product2 sampleProd1 = BoomTestHelpers.generateProduct();
        Product2 sampleProd2 = BoomTestHelpers.generateProduct();
        Kit_Bundle_Member__c sampleMember = BoomTestHelpers.generateTestKitBundle(sampleProd1.Id, sampleProd2.Id);

        Test.startTest();
        Product2 retProd = [SELECT IsKitBundle__c FROM Product2 WHERE Id = :sampleProd1.Id];
        System.assertEquals(true, retProd.IsKitBundle__c, 'Product should be a kit bundle');
        Test.stopTest();
    }
}