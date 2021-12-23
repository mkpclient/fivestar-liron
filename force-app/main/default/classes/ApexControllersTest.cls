@isTest
public with sharing class ApexControllersTest {
  @isTest
  public static void ApexControllersTest() {
    Product2 testProd = BoomTestHelpers.generateProduct();
    PricebookEntry testPbe = BoomTestHelpers.generatePricebookEntry(
      testProd.Id
    );
    Market__c testMarket = BoomTestHelpers.generateMarket(
      testPbe.Pricebook2Id,
      true
    );
    Account testAcct = BoomTestHelpers.generateAccount();
    Contact testCont = BoomTestHelpers.generateContact(testAcct.Id);
    Opportunity testOpp = BoomTestHelpers.generateOpportunity(
      testAcct.Id,
      testMarket.Id,
      testCont.Id
    );
    Test.startTest();
    Id oppId = testOpp.Id;
    DescribeSObjectResult describeResult = oppId.getSObjectType().getDescribe();
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

    // Get all of the fields on the object
    List<String> fieldNames = new List<String>(fieldMap.keySet());
    Id ctcId = testCont.Id;
    DescribeSObjectResult describeCtcResult = ctcId.getSObjectType().getDescribe();
    Map<String, Schema.SObjectField> ctcFieldMap = describeResult.fields.getMap();

    // Get all of the fields on the object
    List<String> ctcFieldNames = new List<String>(ctcFieldMap.keySet());

    // Build a Dynamic Query String.
    String soqlQuery =
      ' SELECT ' +
      string.join(fieldNames, ',') + ', Market_Project__r.Price_Book__c, Market_Project__r.Name, ' +
      'Contact__r.MailingCity,Contact__r.MailingCountry,Contact__r.MailingState,Contact__r.MailingStreet,Contact__r.MailingPostalCode,Contact__r.OtherCity,Contact__r.OtherCountry,Account.Name,Contact__r.OtherState,Contact__r.OtherStreet,Contact__r.OtherPostalCode' +
      ' FROM ' +
      describeResult.getName() +
      ' Where Id =: oppId';
    
    soqlQuery = soqlQuery.replace(', Contact__r.isprivate', '');
    List<Opportunity> record = Database.query(soqlQuery);
    ApexPages.StandardController sc = new ApexPages.StandardController(record[0]);
    ApexControllers testController = new ApexControllers(sc);
    Pagereference testPage = testController.generateOrder();
    System.assertEquals(
      testPage.getUrl().contains(String.valueOf(testOpp.Id)),
      true
    );
    Test.stopTest();
  }
}