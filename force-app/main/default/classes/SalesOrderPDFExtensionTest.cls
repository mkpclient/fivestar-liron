@isTest
public with sharing class SalesOrderPDFExtensionTest {
  @isTest
  private static void salesOrderPdfTest() {
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
      'Completed'
    );

    Pagereference testPageRef = Page.OnlineOrderVf;
    Test.setCurrentPage(testPageRef);
    ApexPages.currentPage().getParameters().put('id', testSo.Id);
    ApexPages.currentPage().getParameters().put('acceptedByName', 'Test Name');
    ApexPages.currentPage().getParameters().put('signature', 'Test Signature');
    SalesOrderPDFExtension custController = new SalesOrderPDFExtension();
    SalesOrderPDFExtension controller = new SalesOrderPDFExtension(new ApexPages.StandardController(testSo));
    
    System.assertEquals(controller.orderId, testSo.Id, 'Ids should match');
    controller.captureAcceptedByInput();
    System.assertEquals(
      controller.acceptedBy,
      'Test Name',
      'Names should match'
    );
    Boolean oldAcceptTerms = controller.acceptTerms;
    controller.toggleAcceptTerms();
    Boolean newAcceptTerms = controller.acceptTerms;
    System.assertNotEquals(
      oldAcceptTerms,
      newAcceptTerms,
      'Accept terms should have changed'
    );
    System.assertEquals(
      controller.showAcceptedByNameErrorBlock,
      false,
      'Error block should be hidden'
    );
    

    Pagereference testPdfRef = controller.attachPDF();
    System.assertEquals(
      testPdfRef.getParameters().get('id'),
      testSo.Id,
      'Ids should match with pdf ref'
    );

    System.assertEquals(
      'test.pdf.url.com',
      controller.downloadPDFURL,
      'String values should match'
    );

    Pagereference testOnlineTerminalRef = new PageReference(
      '/apex/publicPaymentVfPage?id=' + testSo.Id + '&isEssential=false'
    );
    Pagereference returnedOnlineTerminalRef = controller.acceptAndPayOnline();

    System.assertEquals(testOnlineTerminalRef.getParameters().get('id'), returnedOnlineTerminalRef.getParameters().get('id'), 'Refs should match');

    System.assertEquals('Test Signature', controller.encodedSignature, 'Signatures should match');

    DateTime dt = Datetime.now();

    // System.assertEquals('Jane Doe', controller.InitialedBy, 'Names should match');
    System.assertEquals('Test Name', controller.getTermsAcceptedBy(), 'Names should match');
    System.assertEquals(dt.format(), controller.getTermsAcceptedDate(), 'Dates should match');
    System.assertEquals(controller.getIPAddress(), controller.getTermsAcceptedFromIPAddress(), 'IP Addresses should match');
    System.assertEquals('USD', controller.getISOCurrencyCode(), 'Currency Codes should match');
    System.assertEquals(false, controller.getIsMultiCurrencyEnabled(), 'Multi Currency should match');
    System.assertEquals(false, controller.showInitialByErrorBlock, 'Error block should be hidden');
    System.assertEquals(true, controller.checkout() == null && controller.getProductsHaveDescriptions() && controller.getAccsHaveDescriptions() && controller.getDisplayShipToInfo() && controller.getRenderPaymentButton() && !controller.gethasProductTextandTerms() && controller.getProducts() == null, 'booleans should match');
    System.assertEquals(true, controller.getProductLineCount() == controller.ProductLines.size(), 'Product Line Count should match');
    System.assertEquals(true, controller.getChargeCreditLineCount() == controller.ACCLines.size(), 'Additional Charge Ids should match');
    System.assertEquals('test.com', controller.getLogoUrl(), 'Logo Url should match');
    System.assertEquals(testSo.Id, controller.Order.Id, 'Order ids should match');
    System.assertEquals(true, controller.Payments.size() > 0, 'Payment count should be greater than 0');
    System.assertEquals(true, controller.settings.SignatureLinestoPDF && controller.settings.PrintCompanyTextandTerms && String.isNotEmpty(controller.settings.CompanyTextandTerms) && String.isNotEmpty(controller.settings.OnlinePaymentButton), 'Settings should all have values');
  
    controller.getPaymentURL();
    controller.LineRecipients.size();
    controller.UniqueLineRecipients.size();
    controller.PaymentSchedules.size();
  }
}