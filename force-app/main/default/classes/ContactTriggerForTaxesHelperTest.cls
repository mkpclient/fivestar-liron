@isTest
public with sharing class ContactTriggerForTaxesHelperTest {
    @isTest
    public static void testChangeMailingAddress() {
        Account testAcc = BoomTestHelpers.generateAccount();
        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        testCtc.MailingState = 'WA';
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

        testCtc.MailingState = 'MN';
        update testCtc;

        List<SalesOrderProductLine__c> soplsUpdated = [SELECT Id, State_Tax_Rate__c FROM SalesOrderProductLine__c WHERE Id = :testProdLine.Id];
        System.assertEquals(Sales_Tax__mdt.getInstance('MN').Rate__c, soplsUpdated[0].State_Tax_Rate__c, 'State tax rate should be updated');
    
    }
}
