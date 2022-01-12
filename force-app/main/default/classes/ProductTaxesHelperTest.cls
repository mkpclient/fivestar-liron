@isTest
public with sharing class ProductTaxesHelperTest {
    @isTest
    public static void productTaxesTest() {
        Account testAcc = BoomTestHelpers.generateAccount();
        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        testCtc.MailingState = 'MN';
        update testCtc;
        Product2 testPdc1 = BoomTestHelpers.generateProduct();
        testPdc1.TaxableSale__c = true;
        update testPdc1;
        PricebookEntry testPbe1 = BoomTestHelpers.generatePriceBookEntry(
          testPdc1.Id
        );
        Market__c testMkt = BoomTestHelpers.generateMarket(
          testPbe1.Pricebook2Id,
          true
        );
        Opportunity testOpp = BoomTestHelpers.generateOpportunity(
          testAcc.Id,
          testMkt.Id,
          testCtc.Id
        );
        SalesOrder__c testSo = BoomTestHelpers.generateTestBoomOrder(testOpp.Id);
    
        SalesOrderProductLine__c testProdLine = BoomTestHelpers.generateBoomProductLine(
          testSo.Id,
          testPbe1
        );

        testProdLine.ContactShipping__c = testCtc.Id;
        update testProdLine;
    
        Order_Line_Recipient__c testRecipient = BoomTestHelpers.generateTestLineRecipient(
          testSo.Id,
          testProdLine.Id,
          testCtc.Id,
          true
        );

        List<SalesOrderProductLine__c> beforeUpdateSopls =[SELECT Id, TaxAmount__c, Tax_Amount_Hidden__c FROM SalesOrderProductLine__c WHERE Id = :testProdLine.Id];
        System.assertEquals(beforeUpdateSopls[0].TaxAmount__c, beforeUpdateSopls[0].Tax_Amount_Hidden__c, 'Tax Amounts should be equal before update');

        testPdc1.TaxableSale__c = false;
        update testPdc1;

        List<SalesOrderProductLine__c> afterUpdateSopls =[SELECT Id, TaxAmount__c, Tax_Amount_Hidden__c FROM SalesOrderProductLine__c WHERE Id = :testProdLine.Id];
        System.assertEquals(afterUpdateSopls[0].TaxAmount__c, afterUpdateSopls[0].Tax_Amount_Hidden__c, 'Tax Amounts should be equal before update');
        System.assertNotEquals(afterUpdateSopls[0].TaxAmount__c, beforeUpdateSopls[0].TaxAmount__c, 'Tax Amounts should have been updated');


    }
}
