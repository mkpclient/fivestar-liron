@isTest
public with sharing class SalesOrderHelperTest {
  @TestSetup
  static void makeData(){
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
  }


  @isTest
  private static void testOrderReleaseSingleFulfillment() {
    Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

    SalesOrder__c testSo = [SELECT Id, Account__c, ContactBilling__c FROM SalesOrder__c WHERE OrderDate__c=TODAY ORDER BY CreatedDate Desc LIMIT 1];
    testSo.Status_Picklist__c = 'Approved';

    update testSo;

    Payment_Method__c testPmtMethod = BoomTestHelpers.generateTestPmtMethod(
      testSo.ContactBilling__c,
      false
    );

    Payment__c testPmt = BoomTestHelpers.generateTestPayment(
      testSo.Id,
      testSo.Account__c,
      testSo.ContactBilling__c,
      testPmtMethod.Id,
      50,
      'Scheduled'
    );

    Payment__c testPmt2 = BoomTestHelpers.generateTestPayment(
      testSo.Id,
      testSo.Account__c,
      testSo.ContactBilling__c,
      testPmtMethod.Id,
      50,
      'Completed'
    );

    List<Fulfillment__c> fulfillments = [
      SELECT Id,Boom_Order_Product_Line__c
      FROM Fulfillment__c
      WHERE Boom_Order__c = :testSo.Id
    ];

    List<Order_Line_Recipient__c> olrs = [
      SELECT Id, Fulfillment__c FROM Order_Line_Recipient__c
      WHERE Order__c = :testSo.Id
      AND Fulfillment__c IN :fulfillments
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
    System.assertEquals(true, olrs.size() > 0, 'Line recipients were not updated');
    
    PriceBook2 customPriceBook = new PriceBook2();
    customPriceBook.Name = 'Custom Pricebook';
    customPriceBook.IsActive = true;
    insert customPriceBook;

    updSo.Price_Book__c = customPriceBook.Id;

    update updSo;

    updSo.FulfillOrder__c = false;
    update updSo;

    List<Fulfillment__c> newFulfillments = [
      SELECT Id
      FROM Fulfillment__c
      WHERE Boom_Order__c = :testSo.Id
    ];

    System.assertEquals(true, newFulfillments.size() == 0, 'Fulfillments not removed');

  }

  @isTest
  public static void testOrderReleaseWithChildFulfillments() {
    Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

    SalesOrder__c testSo = [SELECT Id, Account__c, ContactBilling__c FROM SalesOrder__c WHERE OrderDate__c=TODAY ORDER BY CreatedDate Desc LIMIT 1];
    Product2 productWithX2 = BoomTestHelpers.generateProduct();

    productWithX2.Name = 'Test Product - 2X';
    update productWithX2;
    PricebookEntry testPbe2 = BoomTestHelpers.generatePriceBookEntry(productWithX2.Id);

    SalesOrderProductLine__c testProdLine = BoomTestHelpers.generateBoomProductLine(
      testSo.Id,
      testPbe2
    );
    Order_Line_Recipient__c testRecipient = BoomTestHelpers.generateTestLineRecipient(
      testSo.Id,
      testProdLine.Id,
      testSo.ContactBilling__c,
      true
    );

    testSo.Status_Picklist__c = 'Approved';

    update testSo;

    Payment_Method__c testPmtMethod = BoomTestHelpers.generateTestPmtMethod(
      testSo.ContactBilling__c,
      false
    );

    Payment__c testPmt = BoomTestHelpers.generateTestPayment(
      testSo.Id,
      testSo.Account__c,
      testSo.ContactBilling__c,
      testPmtMethod.Id,
      100,
      'Completed'
    );

    List<Fulfillment__c> fulfillments = [
      SELECT Id
      FROM Fulfillment__c
      WHERE Boom_Order_Product_Line__c = :testProdLine.Id
      AND ParentFulfillment__c != null
    ];

    System.assertEquals(1, fulfillments.size(), 'Child fulfillments were not created');

  }

  @IsTest
  public static void testOrderCancellation() {
    Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

    Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
    SalesOrder__c testSo = [SELECT Id, Account__c, ContactBilling__c FROM SalesOrder__c WHERE OrderDate__c=TODAY ORDER BY CreatedDate Desc LIMIT 1];
    testSo.Status_Picklist__c = 'Approved';

    update testSo;

    Payment_Method__c testPmtMethod = BoomTestHelpers.generateTestPmtMethod(
      testSo.ContactBilling__c,
      false
    );

    Payment__c testPmt = BoomTestHelpers.generateTestPayment(
      testSo.Id,
      testSo.Account__c,
      testSo.ContactBilling__c,
      testPmtMethod.Id,
      50,
      'Completed'
    );

    testSo.Status_Picklist__c = 'Cancelled';

    update testSo;

    List<Fulfillment__c> fulfillments = [
      SELECT Id
      FROM Fulfillment__c
      WHERE Boom_Order__c = :testSo.Id
      AND Status__c = 'Cancelled'
    ];

    System.assertEquals(1, fulfillments.size(), 'Fulfillment was not cancelled');

  }

  
}