@isTest
public without sharing class BoomTestHelpers {
  public static Product2 generateProduct() {
    Product2 pro = new Product2(
      Name = 'Test Product 1',
      Family = 'Test',
      isActive = true,
      CreateOrderFulfillment__c = true
    );
    insert pro;
    return pro;
  }

  public static PricebookEntry generatePriceBookEntry(Id productId) {
    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );

    update standardPricebook;

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebook.Id,
      Product2Id = productId,
      UnitPrice = 1,
      IsActive = true
    );
    insert pbe;
    return pbe;
  }

  public static Market__c generateMarket(Id pbId, Boolean includePb) {
    Pricebook2 pb = [SELECT Name FROM Pricebook2 WHERE Id = :pbId LIMIT 1];
    Market__c market = new Market__c(
      Name = pb.Name,
      publication_Year__c = String.valueOf(system.today().year()),
      Market_Close_Date__c = system.today().addDays(1)
    );

    if (includePb) {
      market.Price_Book__c = pbId;
    }

    insert market;
    return market;
  }

  public static Account generateAccount() {
    Account account = new Account(
      Name = 'Test Account',
      Type = 'Customer - Direct',
      BillingStreet = '555 Jacobs Street',
      BillingState = 'PA',
      BillingPostalCode = '15219',
      BillingCity = 'Pittsburgh',
      BillingCountry = 'United States',
      ShippingStreet = '555 Jacobs Street',
      ShippingCity = 'Pittsburgh',
      ShippingState = 'PA',
      ShippingPostalCode = '15219',
      ShippingCountry = 'United States',
      Phone = '(412) 338-1168',
      Fax = '(412) 338-1168',
      AccountNumber = 'Test Account',
      Industry = 'Apparel',
      AnnualRevenue = 350000000,
      NumberOfEmployees = 9000,
      Ownership = 'Public',
      TickerSymbol = 'BTXT',
      Description = 'Test Account',
      Site = ''
    );
    insert account;
    return account;
  }

  public static Contact generateContact(Id accId) {
    Contact contact = new Contact(
      AccountId = accId,
      FirstName = 'Jane',
      LastName = 'Doe',
      Email = 'jdoe@testmail.com.ua',
      Phone = '(123) 456-7890',
      MailingStreet = '555 Jacobs Street',
      MailingState = 'PA',
      MailingCity = 'Pittsburgh',
      MailingPostalCode = '15219',
      MailingCountry = 'United States'
    );
    insert contact;
    return contact;
  }

  public static Opportunity generateOpportunity(
    Id accId,
    Id marketId,
    Id contId
  ) {
    Opportunity opportunity = new Opportunity(
      AccountId = accId,
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = system.today().addDays(1),
      Amount = 1000000,
      Probability = 50,
      Type = 'New Business',
      Description = 'Test Opportunity',
      Market_Project__c = marketId,
      ContactId = contId,
      Contact__c = contId
    );
    insert opportunity;
    return opportunity;
  }

  public static SalesOrder__c generateTestBoomOrder(Id oppId) {
    Opportunity opp = [
      SELECT
        Id,
        Name,
        Market_Project__c,
        AccountId,
        Market_Project__r.Price_Book__c,
        ContactId,
        Account.Name,
        OwnerId
      FROM Opportunity
      WHERE Id = :oppId
      LIMIT 1
    ];
    Contact cont = [
      SELECT
        Id,
        FirstName,
        LastName,
        Email,
        Phone,
        MailingStreet,
        MailingState,
        MailingCity,
        MailingPostalCode,
        MailingCountry
      FROM Contact
      WHERE Id = :opp.ContactId
    ];
    System.debug(opp);
    SalesOrder__c generatedSO = new SalesOrder__c();
    generatedSO.OrderDate__c = System.today();
    generatedSO.OrderName__c = opp.Name;
    generatedSO.Market__c = opp.Market_Project__c;
    generatedSO.Opportunity__c = opp.Id;
    generatedSO.Account__c = opp.AccountId;
    if (opp.Market_Project__r.Price_Book__c == null) {
      Pricebook2 pb = [
        SELECT Id
        FROM Pricebook2
        WHERE Name = :opp.Market_Project__r.Name
        LIMIT 1
      ];
      generatedSO.Price_Book__c = pb.Id;
    } else {
      generatedSO.Price_Book__c = opp.Market_Project__r.Price_Book__c;
    }
    generatedSO.ContactBilling__c = opp.ContactId;
    generatedSO.ContactBuying__c = opp.ContactId;
    generatedSO.ContactShipping__c = opp.ContactId;
    generatedSO.BillToName__c = opp.Account.Name;
    generatedSO.BillToCity__c = cont.MailingCity;
    generatedSO.BillToCountry__c = cont.MailingCountry;
    generatedSO.BillToStateProvince__c = cont.MailingState;
    generatedSO.BillToStreetLong__c = cont.MailingStreet;
    generatedSO.BillToZipPostalCode__c = cont.MailingPostalCode;
    generatedSO.ShipToCity__c = cont.MailingCity;
    generatedSO.ShipToCountry__c = cont.MailingCountry;
    generatedSO.ShipToName__c = opp.Account.Name;
    generatedSO.ShipToStateProvince__c = cont.MailingState;
    generatedSO.ShipToStreetLong__c = cont.MailingStreet;
    generatedSO.ShipToZipPostalCode__c = cont.MailingPostalCode;
    System.debug(generatedSO);
    insert generatedSO;
    return generatedSO;
  }

  public static AdditionalChargeCredit__c generateAdditionalChargeCredit(
    Id prodId
  ) {
    AdditionalChargeCredit__c acc = new AdditionalChargeCredit__c(
      IsActive__c = true,
      OpportunitySyncProduct__c = prodId
    );
    insert acc;
    return acc;
  }

  public static SalesOrderProductLine__c generateBoomProductLine(
    Id soId,
    PricebookEntry pbe
  ) {
    SalesOrderProductLine__c sopl = new SalesOrderProductLine__c(
      Quantity__c = 5,
      SalesOrder__c = soId,
      Product__c = pbe.Product2Id,
      ListPrice__c = pbe.UnitPrice,
      SalesPrice__c = 10
    );

    insert sopl;
    return sopl;
  }

  public static Payment_Method__c generateTestPmtMethod(
    Id ctcId,
    Boolean isDefault
  ) {
    Payment_Method__c pmtMethod = new Payment_Method__c(
      Billing_Street__c = '555 Jacobs Street',
      Billing_City__c = 'Pittsburgh',
      Billing_Last_Name__c = 'Doe',
      Billing_First_Name__c = 'Jane',
      Last_4_Digits_of_Card__c = '1234',
      Billing_Country__c = 'United States',
      Billing_State__c = 'PA',
      Billing_Postal_Code__c = '15219',
      Card_Type__c = 'Visa',
      Payment_Processor__c = 'MX Merchant',
      Contact__c = ctcId,
      Expiration_Date__c = Date.today().addYears(1),
      Default__c = isDefault,
      Merchant_Token__c = 'test'
    );

    insert pmtMethod;
    return pmtMethod;
  }

  public static Payment__c generateTestPayment(
    Id soId,
    Id accId,
    Id ctcId,
    Id mtdId,
    Decimal amt,
    String status
  ) {
    Payment__c pmt = new Payment__c(
      Sales_Order__c = soId,
      Payment_Method__c = mtdId,
      Contact__c = ctcId,
      Account__c = accId,
      Date__c = system.today(),
      Amount__c = amt,
      Is_Test_Transaction__c = true,
      Status__c = status
    );

    insert pmt;
    return pmt;
  }

  public static Kit_Bundle_Member__c generateTestKitBundle(
    Id parentProdId,
    Id childProdId
  ) {
    Kit_Bundle_Member__c sampleMember = new Kit_Bundle_Member__c(
      ReferenceKitBundle__c = parentProdId,
      ReferenceMemberProduct__c = childProdId
    );
    insert sampleMember;
    return sampleMember;
  }

  public static Order_Line_Recipient__c generateTestLineRecipient(
    Id soId,
    Id soplId,
    Id ctcId,
    Boolean isPrimary
  ) {
    Order_Line_Recipient__c sampleRecipient = new Order_Line_Recipient__c(
      OrderProductLine__c = soplId,
      Recipient__c = ctcId,
      Order__c = soId,
      Primary__c = isPrimary
    );

    insert sampleRecipient;
    return sampleRecipient;
  }
}