@isTest
public with sharing class ProductUpdateBatchTest {
    @isTest
    public static void testMethod1() {
        Product2 testProd = BoomTestHelpers.generateProduct();
        kugo2p__AdditionalProductDetail__c testAdp = new kugo2p__AdditionalProductDetail__c(kugo2p__ReferenceProduct__c = testProd.Id);
        insert testAdp;
        
        Test.startTest();
        Database.executeBatch(new ProductUpdateBatch());
        Test.stopTest();
    }
}