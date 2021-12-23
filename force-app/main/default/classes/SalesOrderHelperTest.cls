@isTest
public with sharing class SalesOrderHelperTest {
  @isTest
  private static void testOrderRelease() {
    Account testAcc = BoomTestHelpers.generateAccount();
    Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
    Product2 testPdc = BoomTestHelpers.generateProduct();
    PricebookEntry testPbe = BoomTestHelpers.generatePriceBookEntry(testPdc.Id);
    Market__c testMkt = BoomTestHelpers.generateMarket(
      testPbe.Pricebook2Id,
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
      testPbe
    );
    Order_Line_Recipient__c testRecipient = BoomTestHelpers.generateTestLineRecipient(
      testSo.Id,
      testProdLine.Id,
      testCtc.Id,
      true
    );

    testSo.Status_Picklist__c = 'Approved';

    update testSo;
    Payment_Method__c testPmtMethod = BoomTestHelpers.generateTestPmtMethod(
      testCtc.Id,
      false
    );
    Payment__c testPmt = BoomTestHelpers.generateTestPayment(
      testSo.Id,
      testAcc.Id,
      testCtc.Id,
      testPmtMethod.Id,
      50,
      'Scheduled'
    );

    Payment__c testPmt2 = BoomTestHelpers.generateTestPayment(
      testSo.Id,
      testAcc.Id,
      testCtc.Id,
      testPmtMethod.Id,
      50,
      'Completed'
    );

    List<Order_Fulfillment__c> fulfillments = [
      SELECT Id
      FROM Order_Fulfillment__c
      WHERE OrderNumber__c = :testSo.Id
    ];

    SalesOrder__c updSo = [
      SELECT Id, Status_Picklist__c, FulfillOrder__c
      FROM SalesOrder__c
      WHERE Id = :testSo.Id
      LIMIT 1
    ];

    List<Payment__c> cxlPmts = [
      SELECT Id
      FROM Payment__c
      WHERE Status__c='Cancelled'
      AND Id=:testPmt.Id
    ];

    System.assertEquals(true, cxlPmts.size() > 0, 'Cancelled Payment not found');

    System.assertEquals(
      'Released',
      updSo.Status_Picklist__c,
      'Sales Order Status is not Released'
    );
    System.assertEquals(
      true,
      fulfillments.size() > 0,
      'Sales Order has no Order Fulfillments. FulfillOrder__c is :' +
      updSo.FulfillOrder__c
    );
    PriceBook2 customPriceBook = new PriceBook2();
    customPriceBook.Name = 'Custom Pricebook';
    customPriceBook.IsActive = true;
    insert customPriceBook;

    updSo.Price_Book__c = customPriceBook.Id;

    update updSo;
  }
}