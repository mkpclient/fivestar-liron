@isTest
/* THIS TEST CLASS WILL NOT PASS IF MASS MAIL PRIVILEGES ARE NOT TURNED ON */
private class OrderInvoiceWithAttachmentTest {
  
  static testMethod void Test1() {
    Account acc = new Account();
    acc.Name = 'Test';
    insert acc;

    Contact c = new Contact();
    c.AccountId = acc.Id;
    c.LastName = 'Test';
    c.Client_Type__c = 'BD';
    insert c;

    Market__c market = new Market__c();
    market.Name = 'SF Market';
    market.Sales_Close__c = Date.today().AddDays(1);
    market.Market_Close_Date__c = Date.today().AddDays(1);
    insert market;

    Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), Name = 'Standard Price Book', IsActive = true);
    update standardPricebook;   

    Opportunity opp = new Opportunity();
    opp.AccountId = acc.Id;
    opp.Contact__c = c.Id;
    opp.Name = 'Test Opp';
    opp.StageName = 'Gold';
    opp.CloseDate = Date.Today();
    opp.Market_Project__c = ManageLinesTests.market.Id;
    opp.Next_call_date__c = Date.Today();
    opp.Next_Call_Date_Time__c = Date.Today();
    // opp.Pardot_Campaign_Type__c = 'Core';
    opp.PriceBook2Id = StandardPriceBook.Id;
    insert opp;

    kugo2p__KugamonSetting__c KugamonSettings = new kugo2p__KugamonSetting__c(
      Name = 'My Org Setting',
      kugo2p__PriceBookName__c = CustomPriceBook.Name,
      kugo2p__AccountingGroup__c = 'Business Sale',
      kugo2p__AllowZeroUnitPrice__c = true,
      kugo2p__PrintSpecificTextandTerms__c = false /*kugo2p__WareHouse__c = buildWareHouse().Id ,*/,
      kugo2p__MultiCurrencyEnabled__c = false,
      kugo2p__UnitOfMeasure__c = 'Each',
      kugo2p__TaxableExcise__c = false,
      kugo2p__TaxableSales__c = true,
      kugo2p__TaxableUsage__c = false,
      kugo2p__TaxableVat__c = false,
      kugo2p__AutoReleaseOrder__c = false,
      kugo2p__CompanyTextAndTerms__c = 'This legally binding Order Form is governed by the Master Subscription Agreement between Customer and Kugamon LLC. Prices shown do not include any taxes that may apply. Any such taxes are the responsibility of Customer. Sandbox subscriptions, if ordered, are for testing and development use only and not for production use. Subscriptions are non-cancelable before their End Date.',
      kugo2p__PrintCompanyTextAndTerms__c = true,
      kugo2p__SpecificTextandTerms__c = 'Specific Terms & Conditions',
      kugo2p__PrintInvoiceTextandTerms__c = true,
      kugo2p__InvoiceTextandTerms__c = 'Invoice Terms',
      kugo2p__PaymentMethod__c = 'Debit/Credit Card',
      kugo2p__PaymentTerms__c = 'Due Upon Receipt',
      kugo2p__DaysTillPaymentDue__c = 0,
      kugo2p__Admin_User__c = UserInfo.getUserId(),
      kugo2p__OnlinePaymentButton__c = 'Accept & Pay',
      kugo2p__OnlineConfirmationTextandTerms__c = 'Confirmation Text',
      kugo2p__AutoClosedLostQuote__c = false,
      kugo2p__AutoCancelOrder__c = false,
      kugo2p__AllowOverrideServiceDateUpdate__c = true
    );
    insert KugamonSettings;

    list<kugo2p__Warehouse__c> warehouses = new List<kugo2p__Warehouse__c>{
      new kugo2p__Warehouse__c(
        kugo2p__KugamonSetting__c = KugamonSettings.Id,
        Name = 'Main Warehouse',
        kugo2p__Description__c = 'Main Warehouse',
        kugo2p__WarehouseStreet__c = '1 Market Street',
        kugo2p__WareHouseCity__c = 'San Francisco',
        kugo2p__WareHouseStateProvince__c = 'California',
        kugo2p__WareHouseZipPostalCode__c = '80005',
        kugo2p__WareHouseCountry__c = 'United States'
      ),
      new kugo2p__Warehouse__c(
        kugo2p__KugamonSetting__c = KugamonSettings.Id,
        Name = 'International Warehouse',
        kugo2p__Description__c = 'International Warehouse',
        kugo2p__WarehouseStreet__c = '1 Bazaar Street',
        kugo2p__WareHouseCity__c = 'Chennai',
        kugo2p__WareHouseStateProvince__c = 'Tamil Nadu',
        kugo2p__WareHouseZipPostalCode__c = '600001',
        kugo2p__WareHouseCountry__c = 'India'
      )
    };
    insert warehouses;

    kugo2p__SalesQuote__c SalesQuote = new kugo2p__SalesQuote__c(
      kugo2p__Account__c = acc.Id,
      kugo2p__Opportunity__c = opp.Id,
      kugo2p__PriceBookName__c = StandardPriceBook.Name,
      kugo2p__Warehouse__c = warehouses[0].Id
    );
    insert SalesQuote;

    kugo2p__SalesOrder__c SalesOrder = new kugo2p__SalesOrder__c(
      kugo2p__Account__c = acc.Id,
      kugo2p__Opportunity__c = opp.Id,
      kugo2p__OrderDate__c = system.today(),
      kugo2p__DiscountPercent__c = null,
      kugo2p__PaymentMethod__c = 'Invoice',
      kugo2p__Warehouse__c = warehouses[0].Id,
      kugo2p__ContactShipping__c = c.Id,
      kugo2p__ContactBuying__c = c.Id,
      kugo2p__RecordStatus__c = 'Draft',
      kugo2p__PrintSpecificTextandTerms__c = true,
      Initial_Invoice_Sent__c = false,
      kugo2p__ContactBilling__c = c.Id,
      kugo2p__SalesQuote__c = Salesquote.Id,
      Market__c = market.id,
      kugo2p__PriceBookName__c = CustomPriceBook.Name, 
      Email_To_Send__c = true
    );
    insert SalesOrder;

    test.starttest();
    OrderInvoiceWithAttachment.sendEmailWithAttachment(
      new List<ID>{ SalesOrder.Id }
    );
    test.stoptest();
  }

  private static Pricebook2 CustomPriceBook {
    get {
        if (CustomPriceBook == null) {
            CustomPriceBook = new Pricebook2(Name='SF Market', IsActive=true, Description='Test');
            insert CustomPriceBook;
        }
        return CustomPriceBook;
    }

    private set;
  }


}