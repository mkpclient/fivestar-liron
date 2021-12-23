@isTest
public with sharing class BoomOrderCloneTest {
  @isTest
  public static void testMethod1() {
    Product2 testProd = BoomTestHelpers.generateProduct();
    PricebookEntry testPbe = BoomTestHelpers.generatePricebookEntry(
      testProd.Id
    );
    Market__c testMarket = BoomTestHelpers.generateMarket(testPbe.Pricebook2Id, true);
    Account testAcct = BoomTestHelpers.generateAccount();
    Contact testCont = BoomTestHelpers.generateContact(testAcct.Id);
    Opportunity testOpp = BoomTestHelpers.generateOpportunity(
      testAcct.Id,
      testMarket.Id,
      testCont.Id
    );
    System.debug(testCont);

    SalesOrder__c testSO = BoomTestHelpers.generateTestBoomOrder(testOpp.Id);
    AdditionalChargeCredit__c testACC = BoomTestHelpers.generateAdditionalChargeCredit(testProd.Id);
    SalesOrderAdditionalChargeCredit__c testSAOCC = new SalesOrderAdditionalChargeCredit__c(
      SalesOrder__c = testSO.Id,
      Additional_Charge_Credit__c = testACC.Id
    );
    insert testSAOCC;

    SalesOrderProductLine__c testOPL = BoomTestHelpers.generateBoomProductLine(testSO.Id, testPbe);
    Order_Line_Recipient__c testOLR = BoomTestHelpers.generateTestLineRecipient(testSO.Id, testOPL.Id, testCont.Id, true);

    Test.startTest();
        Id clonedOrder = BoomOrderCloneController.cloneBoomOrder(testSO.Id);
    System.assertEquals(
      true,
      String.isNotEmpty(clonedOrder),
      'A new order was created'
    );
    Test.stopTest();
  }
}