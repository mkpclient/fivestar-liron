/**
   * *************************************************************************
   * * uncomment everything that's commented below if I leave anything out *
   * *************************************************************************
   */

@isTest
public with sharing class SalesOrderProductLineHelperTest {
  @TestSetup
  static void setup() {
    Account testAcc = BoomTestHelpers.generateAccount();
    Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
    Product2 testPdc1 = BoomTestHelpers.generateProduct();
    Product2 testPdc2 = BoomTestHelpers.generateProduct();
    Kit_Bundle_Member__c sampleMember = BoomTestHelpers.generateTestKitBundle(
      testPdc1.Id,
      testPdc2.Id
    );
    PricebookEntry testPbe1 = BoomTestHelpers.generatePriceBookEntry(
      testPdc1.Id
    );
    PricebookEntry testPbe2 = BoomTestHelpers.generatePriceBookEntry(
      testPdc2.Id
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

    Order_Line_Recipient__c testRecipient = BoomTestHelpers.generateTestLineRecipient(
      testSo.Id,
      testProdLine.Id,
      testCtc.Id,
      true
    );
  }

  @isTest
  private static void testInsert() {
    SalesOrderProductLine__c insertedProdLine = [
      SELECT KitBundle__c, Id, SalesOrder__c
      FROM SalesOrderProductLine__c
      WHERE SalesPrice__c = 10 AND Quantity__c = 5 AND KitBundle__c = TRUE
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    System.assertEquals(
      false,
      insertedProdLine == null,
      'Product line was not modified at insert'
    );

    List<SalesOrderProductLine__c> bundleProdLine = [
      SELECT Id, KitBundleLine__c
      FROM SalesOrderProductLine__c
      WHERE KitBundleLine__c = :insertedProdLine.Id
    ];

    System.assertEquals(
      true,
      bundleProdLine.size() > 0,
      'Bundle product line was not created'
    );


    Product2 sampleProd = BoomTestHelpers.generateProduct();
    sampleProd.Sample_Product__c = true;
    update sampleProd;

    PricebookEntry samplePbe = BoomTestHelpers.generatePriceBookEntry(
      sampleProd.Id
    );
    samplePbe.UnitPrice = 0;
    update samplePbe;

    SalesOrderProductLine__c testSampleProdLine = BoomTestHelpers.generateBoomProductLine(
      insertedProdLine.SalesOrder__c,
      samplePbe
    );

    List<SalesOrder__c> sampleOrders = [
      SELECT Id
      FROM SalesOrder__c
      WHERE Sample_ELM_Copy__c = true
    ];

    System.assertEquals(
      true,
      sampleOrders.size() == 0,
      'Order should not be a sample order'
    );


  }

  @isTest
  private static void testSampleProdInsert() {
    Product2 sampleProd = BoomTestHelpers.generateProduct();
    sampleProd.Sample_Product__c = true;
    update sampleProd;

    PricebookEntry samplePbe = BoomTestHelpers.generatePriceBookEntry(
      sampleProd.Id
    );
    samplePbe.UnitPrice = 0;
    update samplePbe;

    SalesOrder__c testSo = [
      SELECT Id
      FROM SalesOrder__c
      WHERE CreatedDate = TODAY
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    delete [SELECT Id FROM SalesOrderProductLine__c WHERE SalesOrder__c = :testSo.Id];

    SalesOrderProductLine__c testProdLine = BoomTestHelpers.generateBoomProductLine(
      testSo.Id,
      samplePbe
    );
    

    List<SalesOrder__c> sampleOrders = [
      SELECT Id
      FROM SalesOrder__c
      WHERE Sample_ELM_Copy__c = true
      AND Id = :testSo.Id
    ];

    System.assertEquals(
      true,
      sampleOrders.size() > 0,
      'Order was not updated'
    );

    delete testProdLine;

    List<SalesOrder__c> sampleOrders2 = [
      SELECT Id
      FROM SalesOrder__c
      WHERE Sample_ELM_Copy__c = true
      AND Id = :testSo.Id
    ];

    System.assertEquals(
      true,
      sampleOrders2.size() == 0,
      'Order was not unset'
    );
    
    SalesOrderProductLine__c testProdLine2 = BoomTestHelpers.generateBoomProductLine(
      testSo.Id,
      samplePbe
    );

    List<SalesOrder__c> resetOrders = [
      SELECT Id
      FROM SalesOrder__c
      WHERE Sample_ELM_Copy__c = true
      AND Id = :testSo.Id
    ];

    Boolean beforeUpdate = sampleOrders.size() > 0;

    Product2 regProd = BoomTestHelpers.generateProduct();
    PricebookEntry regPbe = BoomTestHelpers.generatePriceBookEntry(
      regProd.Id
    );
    SalesOrderProductLine__c regProdLine = BoomTestHelpers.generateBoomProductLine(
      testSo.Id,
      regPbe
    );

    List<SalesOrder__c> removedSampleOrders  = [
      SELECT Id
      FROM SalesOrder__c
      WHERE Sample_ELM_Copy__c = true
      AND Id = :testSo.Id
    ];

    Boolean afterUpdate = removedSampleOrders.size() > 0;

    System.assertEquals(
      beforeUpdate,
      !afterUpdate,
      'Order was not updated'
    );


  }

  @isTest
  private static void testUpdate() {
    SalesOrderProductLine__c prodLineToUpdate = [
      SELECT KitBundle__c, Id
      FROM SalesOrderProductLine__c
      WHERE SalesPrice__c = 10 AND Quantity__c = 5 AND KitBundle__c = TRUE
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    prodLineToUpdate.Quantity__c = 10;
    update prodLineToUpdate;
  }

  @isTest
  private static void testDelete() {
    SalesOrderProductLine__c prodLineToDelete = [
      SELECT KitBundle__c, Id,SalesOrder__c
      FROM SalesOrderProductLine__c
      WHERE SalesPrice__c = 10 AND KitBundle__c = TRUE
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    SalesOrder__c testSo = [
      SELECT Id, NetAmount__c,ContactBilling__c,Account__c
      FROM SalesOrder__c
      WHERE Id = :prodLineToDelete.SalesOrder__c
      LIMIT 1
    ];

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
      testSo.NetAmount__c,
      'Completed'
    );

    // List<Fulfillment__c> beforeDeleteFulfillments = [
    //   SELECT Id
    //   FROM Fulfillment__c
    //   WHERE Boom_Order_Product_Line__c = :prodLineToDelete.Id
    // ];

    // System.assertEquals(
    //   true,
    //   beforeDeleteFulfillments.size() > 0,
    //   'Fulfillments were not created'
    // );
    
    testSo.Status_Picklist__c = 'Draft';
    update testSo;

    delete prodLineToDelete;

    List<SalesOrderProductLine__c> bundleProdLine = [
      SELECT Id, KitBundleLine__c
      FROM SalesOrderProductLine__c
      WHERE KitBundleLine__c = :prodLineToDelete.Id
    ];

    // List<Fulfillment__c> afterDeleteFulfillments = [
    //   SELECT Id
    //   FROM Fulfillment__c
    //   WHERE Boom_Order_Product_Line__c = :prodLineToDelete.Id
    // ];

    List<Order_Line_Recipient__c> afterDeleteRecipients = [
      SELECT Id
      FROM Order_Line_Recipient__c
      WHERE OrderProductLine__c = :prodLineToDelete.Id
    ];

    System.assertEquals(
      false,
      bundleProdLine.size() > 0,
      'Bundle product line was not deleted'
    );

    // System.assertEquals(
    //   false,
    //   afterDeleteFulfillments.size() > 0,
    //   'Fulfillments were not deleted'
    // );

    System.assertEquals(
      false,
      afterDeleteRecipients.size() > 0,
      'Recipients were not deleted'
    );
  }


}