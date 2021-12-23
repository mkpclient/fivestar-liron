/* attempt to clone the manage lines setup method without being the mange lines class */
public without sharing class TestFactory {
  public static void testSetup(){
    kugo2p.Kugamon.TestMode = true;

    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update standardPricebook;

    kugo2p__OrderInvoiceRelationship__c oir = new kugo2p__OrderInvoiceRelationship__c(
      kugo2p__Invoice__c = Invoice.Id,
      kugo2p__SalesOrder__c = SalesOrder.Id
    );
    insert oir;
  }

  public static kugo2p__KugamonSetting__c kugamonSettings() {
    setupPricebook();
    System.debug(getPricebook());
    System.debug('test pricebook id ' + Test.getStandardPricebookId());
    kugo2p__KugamonSetting__c ks = new kugo2p__KugamonSetting__c();
    ks.Name = 'My Org Setting';
    ks.kugo2p__PriceBookName__c = getPricebook().Name;
    ks.kugo2p__PrintSpecificTextandTerms__c = false;
    ks.kugo2p__UnitOfMeasure__c = 'Each';
    ks.kugo2p__TaxableExcise__c = false;
    ks.kugo2p__TaxableSales__c = true; 
    ks.kugo2p__TaxableUsage__c = false; 
    ks.kugo2p__TaxableVat__c = false; 
    ks.kugo2p__AutoReleaseOrder__c = false; 
    ks.kugo2p__CompanyTextAndTerms__c = 'This legally binding Order Form is governed by the Master Subscription Agreement between Customer and Kugamon LLC. Prices shown do not include any taxes that may apply. Any such taxes are the responsibility of Customer. Sandbox subscriptions, if ordered, are for testing and development use only and not for production use. Subscriptions are non-cancelable before their End Date.'; 
    ks.kugo2p__PrintCompanyTextAndTerms__c = true; 
    ks.kugo2p__SpecificTextandTerms__c = 'Specific Terms & Conditions';
    ks.kugo2p__PrintInvoiceTextandTerms__c = true; 
    ks.kugo2p__InvoiceTextandTerms__c = 'Invoice Terms'; 
    ks.kugo2p__PaymentMethod__c = 'Debit/Credit Card'; 
    ks.kugo2p__PaymentTerms__c = 'Due Upon Receipt'; 
    ks.kugo2p__DaysTillPaymentDue__c = 0;
    ks.kugo2p__Admin_User__c = UserInfo.getUserId(); 
    ks.kugo2p__OnlinePaymentButton__c = 'Accept & Pay'; 
    ks.kugo2p__OnlineConfirmationTextandTerms__c = 'Confirmation Text';
    List<kugo2p__KugamonSetting__c> existingSettings = [
      SELECT Id
      ,Name
      ,kugo2p__PriceBookName__c
      ,kugo2p__PrintSpecificTextandTerms__c
      ,kugo2p__UnitOfMeasure__c
      ,kugo2p__TaxableExcise__c
      ,kugo2p__TaxableSales__c
      ,kugo2p__TaxableUsage__c
      ,kugo2p__TaxableVat__c
      ,kugo2p__AutoReleaseOrder__c
      ,kugo2p__CompanyTextAndTerms__c
      ,kugo2p__PrintCompanyTextAndTerms__c
      ,kugo2p__SpecificTextandTerms__c
      ,kugo2p__PrintInvoiceTextandTerms__c
      ,kugo2p__InvoiceTextandTerms__c
      ,kugo2p__PaymentMethod__c
      ,kugo2p__PaymentTerms__c
      ,kugo2p__DaysTillPaymentDue__c
      ,kugo2p__Admin_User__c
      ,kugo2p__OnlinePaymentButton__c
      ,kugo2p__OnlineConfirmationTextandTerms__c
      FROM kugo2p__KugamonSetting__c
      LIMIT 1
    ];
    if ( existingSettings.size() > 0 ){
      ks = existingSettings[0];
    } else {
      insert ks;
    }
    return ks;
  }

  public static String CurrencyIsoCodeField {
    get {
      return kugo2p.Currencies.isMultiCurrencyEnabled
        ? 'CurrencyIsoCode, '
        : '';
    }
  }

  public static kugo2p__SalesOrder__c getSalesOrder(Id soId) {
    return Database.query(
      'select Id, Name, ' +
      CurrencyIsoCodeField +
      'kugo2p__Account__c, kugo2p__Account__r.Name,' +
      'kugo2p__Opportunity__c, kugo2p__OrderDate__c, kugo2p__PriceBookName__c, kugo2p__DateRequired__c, kugo2p__ServiceDateRequired__c, kugo2p__PaymentTerms__c,' +
      'kugo2p__BillingFrequency__c, kugo2p__RecordStatus__c, kugo2p__PaymentMethod__c, kugo2p__DiscountPercent__c, kugo2p__ShipToStreet__c ' +
      // FS04 changes
      ', kugo2p__BalanceDueAmount__c, kugo2p__PaymentStatus2__c, kugo2p__ProductDiscountAmount__c, kugo2p__ContactBilling__c, kugo2p__ContactBuying__c, kugo2p__ContactBuying__r.Name, Market__c, Market__r.Publication_Year__c, FinanceTerm__c, FinanceOverride__c ' +
      ' from kugo2p__SalesOrder__c where Id = :soId'
    );
  }

  public static String StandardPriceBookName = 'Standard Price Book';
  public static Id StandardPriceBookId {
    get {
      if (StandardPriceBookId == null) {
        StandardPriceBookId = Test.getStandardPricebookId();
      }
      return StandardPriceBookId;
    }
    private set;
  }

  private static Pricebook2 CustomPriceBook {
    get {
      if (CustomPriceBook == null) {
        CustomPriceBook = new Pricebook2(
          Name = 'SF Market',
          IsActive = true,
          Description = 'Test'
        );
        insert CustomPriceBook;
      }
      return CustomPriceBook;
    }
    private set;
  }

  public static kugo2p__KugamonSetting__c KugamonSettings {
    get {
      if (KugamonSettings == null) {
        KugamonSettings = kugamonSettings();

        KugamonSettings.kugo2p__WareHouse__c = warehouses[0].Id;
        update KugamonSettings;
      }
      return KugamonSettings;
    }
    private set;
  }

  public static list<kugo2p__InvoiceSchedule__c> InvoiceSchedules {
    get {
      if (InvoiceSchedules == null) {
        invoiceschedules = new List<kugo2p__InvoiceSchedule__c>{
          new kugo2p__InvoiceSchedule__c(
            Name = 'One-Time Invoicing',
            kugo2p__Description__c = 'One-Time Invoicing',
            kugo2p__SchedulePeriod__c = null,
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          ),
          new kugo2p__InvoiceSchedule__c(
            Name = 'Yearly Invoicing',
            kugo2p__Description__c = 'Yearly Invoicing',
            kugo2p__SchedulePeriod__c = 'Annually',
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          ),
          new kugo2p__InvoiceSchedule__c(
            Name = 'Quarterly Invoicing',
            kugo2p__Description__c = 'Quarterly Invoicing',
            kugo2p__SchedulePeriod__c = 'Quarterly',
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          ),
          new kugo2p__InvoiceSchedule__c(
            Name = 'Monthly Invoicing',
            kugo2p__Description__c = 'Monthly Invoicing',
            kugo2p__SchedulePeriod__c = 'Monthly',
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          ),
          new kugo2p__InvoiceSchedule__c(
            Name = 'Weekly Invoicing',
            kugo2p__Description__c = 'Weekly Invoicing',
            kugo2p__SchedulePeriod__c = 'Weekly',
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          ),
          new kugo2p__InvoiceSchedule__c(
            Name = 'Daily Invoicing',
            kugo2p__Description__c = 'Daily Invoicing',
            kugo2p__SchedulePeriod__c = 'Daily',
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          )
        };

        insert invoiceschedules;
      }
      return invoiceschedules;
    }
    private set;
  }

  public static kugo2p__Settings__c PaymentSettings {
    get {
      if (PaymentSettings == null) {
        PaymentSettings = new kugo2p__Settings__c(
          Name = 'Test Payment Settings',
          kugo2p__Gateway_Simulation_Mode__c = true,
          kugo2p__Admin_User__c = UserInfo.getUserId()
        );
        insert PaymentSettings;
      }
      return PaymentSettings;
    }
    private set;
  }

  public static kugo2p__Processor_Connection__c ProcessorConnection {
    get {
      if (ProcessorConnection == null) {
        ProcessorConnection = new kugo2p__Processor_Connection__c(
          Name = 'Test Processor Connection',
          kugo2p__Account_Type__c = 'Website Payments Pro',
          kugo2p__PaymentConnect_Setup__c = PaymentSettings.Id,
          kugo2p__Default_Connection__c = true,
          kugo2p__Assigned_To_Terminal__c = true,
          kugo2p__Processor_Id__c = 'Authorize.Net',
          kugo2p__Enabled_Card_Types__c = 'Visa; Mastercard; Amex; Discover',
          kugo2p__Site_Checkout__c = 'Both',
          kugo2p__PDF_Checkout__c = 'Native',
          kugo2p__Tokenized_Card_Service_Enabled__c = true,
          kugo2p__Test_Mode__c = true,
          kugo2p__Notification_Relay_Method__c = 'Visualforce',
          kugo2p__Relay_Id__c = 'kugo2p__AuthNetRelay',
          kugo2p__Relay_Script__c = 'https://kugamon-customdoc-developer-edition.na15.force.com/kugo2p__AuthNetRelay'
        );
        insert ProcessorConnection;
      }
      return ProcessorConnection;
    }
    private set;
  }

  public static list<kugo2p__Warehouse__c> warehouses {
    get {
      if (warehouses == null) {
        warehouses = new List<kugo2p__Warehouse__c>{
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
      }
      return warehouses;
    }
    private set;
  }

  public static list<Product2> Products {
    get {
      if (Products == null) {
        Products = new List<Product2>{
          new Product2(
            Name = 'Test GenWatt Bundle',
            ProductCode = 'GC1040',
            Family = 'Test Product',
            IsActive = true
          ),
          new Product2(
            Name = 'Test Service Bundle',
            ProductCode = 'GC1041',
            Family = 'Test Service',
            IsActive = true
          ),
          new Product2(
            Name = 'Kit Member Product 1',
            ProductCode = 'GC1040',
            Family = 'Test Product',
            IsActive = true
          ),
          new Product2(
            Name = 'Kit Member Service 1',
            ProductCode = 'GC1041',
            Family = 'Test Service',
            IsActive = true
          )
        };

        insert Products;

        system.assertEquals(APDs.size() > 0, true);
        system.assertEquals(PricebookEntries.isEmpty(), false);
      }
      return Products;
    }
    private set;
  }

  public static list<kugo2p__AdditionalProductDetail__c> APDs {
    get {
      if (APDs == null) {
        APDs = [
          SELECT
            Id,
            Name,
            kugo2p__UnitofTerm__c,
            kugo2p__UnitofMeasure__c,
            kugo2p__ProductDescription__c,
            kugo2p__ProductFamily__c,
            kugo2p__ReferenceProduct__c,
            kugo2p__Service__c,
            kugo2p__StandardPrice__c,
            kugo2p__UnitCost__c,
            kugo2p__Active__c,
            RecipientLimit__c
          FROM kugo2p__AdditionalProductDetail__c
          WHERE kugo2p__ReferenceProduct__c IN :Products
        ];

        // Product - Bundle
        APDs[0].kugo2p__Service__c = false;
        APDs[0].kugo2p__PrintProductTextandTerms__c = true;
        APDs[0].kugo2p__KitBundle__c = true;
        APDs[0].kugo2p__KitBundlePricing__c = 'Member Prices Only';
        // Five Star changes
        APDs[0].RecipientLimit__c = '1';
        APDs[0].LockPrice__c = true;
        APDs[0].CreateOrderFulfillment__c = true;
        APDs[0].NumberofOrderFulfillments__c = 1;

        // Service - Bundle
        APDs[1].kugo2p__Service__c = true;
        APDs[1].kugo2p__UnitofTerm__c = 'Month';
        APDs[1].kugo2p__PrintProductTextandTerms__c = true;
        APDs[1].kugo2p__KitBundle__c = true;
        APDs[1].kugo2p__KitBundlePricing__c = 'Member Prices Only';
        // Five Star changes
        //APDs[1].RecipientLimit__c = 'No Limit';
        APDs[1].RecipientLimit__c = '1';
        APDs[1].LockPrice__c = true;
        APDs[1].CreateOrderFulfillment__c = true;
        APDs[1].NumberofOrderFulfillments__c = 2;

        // Product - Kit Member
        APDs[2].kugo2p__Service__c = false;
        APDs[2].kugo2p__PrintProductTextandTerms__c = true;
        // Five Star changes
        APDs[2].RecipientLimit__c = '1';
        APDs[2].LockPrice__c = true;
        APDs[2].CreateOrderFulfillment__c = true;
        APDs[2].NumberofOrderFulfillments__c = 3;

        // Service - Kit Member
        APDs[3].kugo2p__Service__c = true;
        APDs[3].kugo2p__UnitofTerm__c = 'Month';
        APDs[3].kugo2p__PrintProductTextandTerms__c = true;
        // Five Star changes
        APDs[2].RecipientLimit__c = '1';
        APDs[2].LockPrice__c = true;
        APDs[2].CreateOrderFulfillment__c = true;
        APDs[2].NumberofOrderFulfillments__c = 4;

        update APDs;
      }
      return APDs;
    }
    private set;
  }

  public static list<PricebookEntry> PricebookEntries {
    get {
      if (PricebookEntries == null) {
        PricebookEntries = new List<PricebookEntry>{
          // kit Bundle
          new PricebookEntry(
            Product2Id = Products[0].Id,
            Pricebook2Id = StandardPriceBookId,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 10
          ),
          new PricebookEntry(
            Product2Id = Products[1].Id,
            Pricebook2Id = StandardPriceBookId,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 20
          ),
          new PricebookEntry(
            Product2Id = Products[0].Id,
            Pricebook2Id = CustomPriceBook.Id,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 100
          ),
          new PricebookEntry(
            Product2Id = Products[1].Id,
            Pricebook2Id = CustomPriceBook.Id,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 200
          ),
          // kit Members
          new PricebookEntry(
            Product2Id = Products[2].Id,
            Pricebook2Id = StandardPriceBookId,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 30
          ),
          new PricebookEntry(
            Product2Id = Products[3].Id,
            Pricebook2Id = StandardPriceBookId,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 40
          ),
          new PricebookEntry(
            Product2Id = Products[2].Id,
            Pricebook2Id = CustomPriceBook.Id,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 300
          ),
          new PricebookEntry(
            Product2Id = Products[3].Id,
            Pricebook2Id = CustomPriceBook.Id,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 400
          )
        };
        insert PricebookEntries;
      }
      return PricebookEntries;
    }
    private set;
  }

  public static list<kugo2p__TieredPricing__c> tieredPricing{
    get {
      if (tieredPricing == null) {
        tieredPricing = new List<kugo2p__TieredPricing__c>{
          new kugo2p__TieredPricing__c(
            Name = 'Summer Product pricing',
            kugo2p__IsActive__c = true,
            kugo2p__Pricebook2Id__c = CustomPriceBook.Id,
            kugo2p__PriceBookName__c = CustomPriceBook.Name,
            kugo2p__Product__c = Products[0].Id
          ),
          new kugo2p__TieredPricing__c(
            Name = 'Summer Service pricing',
            kugo2p__IsActive__c = true,
            kugo2p__Pricebook2Id__c = CustomPriceBook.Id,
            kugo2p__PriceBookName__c = CustomPriceBook.Name,
            kugo2p__Product__c = Products[1].Id
          )
        };
        insert tieredPricing;
      }
      return tieredPricing;
    }
    private set;
  }

  public static list<kugo2p__Tier__c> tiers {
    get {
      if (tiers == null) {
        tiers = new List<kugo2p__Tier__c>{
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[0].Id,
            kugo2p__QuantityStart__c = 10,
            kugo2p__TierPrice__c = 10.00
          ),
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[0].Id,
            kugo2p__QuantityStart__c = 20,
            kugo2p__TierPrice__c = 20.00
          ),
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[0].Id,
            kugo2p__QuantityStart__c = 30,
            kugo2p__TierPrice__c = 30.00
          ),
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[1].Id,
            kugo2p__QuantityStart__c = 100,
            kugo2p__TierPrice__c = 15.00
          ),
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[1].Id,
            kugo2p__QuantityStart__c = 200,
            kugo2p__TierPrice__c = 25.00
          ),
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[1].Id,
            kugo2p__QuantityStart__c = 300,
            kugo2p__TierPrice__c = 35.00
          )
        };
        insert tiers;
      }
      return tiers;
    }
    private set;
  }

  public static list<RecommendedProduct__c> RecommendedProducts {
    get {
      if (RecommendedProducts == null) {
        RecommendedProducts = new List<RecommendedProduct__c>{
          new RecommendedProduct__c(
            Product__c = Products[0].Id,
            ReferenceProduct__c = Products[1].Id,
            Quantity__c = 1
          ),
          new RecommendedProduct__c(
            Product__c = Products[1].Id,
            ReferenceProduct__c = Products[0].Id,
            Quantity__c = 1
          )
        };

        insert RecommendedProducts;
      }

      return RecommendedProducts;
    }
    private set;
  }

  public static list<kugo2p__KitBundleMember__c> kitBundleMembers {
    get {
      if (kitBundleMembers == null) {
        kitBundleMembers = new List<kugo2p__KitBundleMember__c>{
          // Product Kit members
          new kugo2p__KitBundleMember__c(
            kugo2p__ReferenceKitBundle__c = APDs[0].Id,
            kugo2p__ReferenceMemberProductService__c = APDs[2].Id,
            kugo2p__AllowQuantityChange__c = true,
            kugo2p__Required__c = true,
            kugo2p__Quantity__c = 1
          ),
          new kugo2p__KitBundleMember__c(
            kugo2p__ReferenceKitBundle__c = APDs[0].Id,
            kugo2p__ReferenceMemberProductService__c = APDs[3].Id,
            kugo2p__AllowQuantityChange__c = false,
            kugo2p__Required__c = false,
            kugo2p__Quantity__c = 1
          ),
          // Service Kit members
          new kugo2p__KitBundleMember__c(
            kugo2p__ReferenceKitBundle__c = APDs[1].Id,
            kugo2p__ReferenceMemberProductService__c = APDs[3].Id,
            kugo2p__AllowQuantityChange__c = false,
            kugo2p__Required__c = true,
            kugo2p__Quantity__c = 1
          )
        };

        insert kitBundleMembers;
      }

      return kitBundleMembers;
    }
    private set;
  }

  public static Account account {
    get {
      if (account == null) {
        account = new Account(
          Name = 'Test Account',
          Type = 'Customer - Direct',
          BillingStreet = '3545 Ave',
          BillingState = 'California',
          BillingPostalCode = '95050',
          BillingCountry = 'United States',
          ShippingStreet = '525 Ave',
          ShippingCity = 'San Jose',
          ShippingState = 'California',
          ShippingPostalCode = '95050',
          ShippingCountry = 'United States',
          Phone = '(336) 222-7000',
          Fax = '(336) 222-8000',
          AccountNumber = 'Test ANo',
          Website = 'www.kkk.com',
          Industry = 'Apparel',
          AnnualRevenue = 350000000,
          NumberOfEmployees = 9000,
          Ownership = 'Public',
          TickerSymbol = 'BTXT',
          Description = 'Test Account',
          Site = ''
        );
        insert account;
      }
      return account;
    }
    private set;
  }

  public static kugo2p__AdditionalAccountDetail__c AdditionalAccountDetail {
    get {
      if (AdditionalAccountDetail == null) {
        try {
          AdditionalAccountDetail = [
            SELECT
              Id,
              kugo2p__PricebookName__c,
              kugo2p__Warehouse__c,
              kugo2p__PaymentMethod__c
            FROM kugo2p__AdditionalAccountDetail__c
            WHERE kugo2p__Account__c = :account.Id
          ];
          AdditionalAccountDetail.kugo2p__PricebookName__c = CustomPriceBook.Name;
          AdditionalAccountDetail.kugo2p__Warehouse__c = warehouses[0].Id;
          AdditionalAccountDetail.kugo2p__PaymentMethod__c = 'Check';
          AdditionalAccountDetail.kugo2p__ContactBilling__c = contacts[0].Id;
          AdditionalAccountDetail.kugo2p__ContactBuying__c = contacts[0].Id;

          update AdditionalAccountDetail;
        } catch (exception ex) {
          AdditionalAccountDetail = new kugo2p__AdditionalAccountDetail__c(
            kugo2p__Account__c = account.Id,
            kugo2p__PricebookName__c = CustomPriceBook.Name,
            kugo2p__Warehouse__c = warehouses[0].Id,
            kugo2p__PaymentMethod__c = 'Check',
            kugo2p__ContactBilling__c = contacts[0].Id,
            kugo2p__ContactBuying__c = contacts[0].Id
          );
          insert AdditionalAccountDetail;
        }
      }
      return AdditionalAccountDetail;
    }
    private set;
  }

  public static list<Contact> contacts {
    get {
      if (contacts == null) {
        contacts = new List<Contact>{
          new Contact(
            AccountId = account.Id,
            FirstName = 'Will',
            LastName = 'Smith',
            Phone = '333-333-3333',
            MailingStreet = '1 Kugamon Street',
            MailingState = 'California',
            MailingCity = 'San Francisco',
            MailingPostalCode = '95050',
            MailingCountry = 'United States',
            Awarded_Years__c = String.valueOf(system.today().year()),
            Market_Project__c = market.Id
          ),
          new Contact(
            AccountId = account.Id,
            FirstName = 'Michael',
            LastName = 'Jackson',
            Phone = '333-333-3333',
            MailingStreet = '1 Kugamon Street',
            MailingState = 'California',
            MailingCity = 'San Francisco',
            MailingPostalCode = '95050',
            MailingCountry = 'United States',
            Awarded_Years__c = String.valueOf(system.today().year()),
            Market_Project__c = market.Id
          )
        };
        insert contacts;
      }
      return contacts;
    }
    private set;
  }

  public static Market__c market {
    get {
      if (market == null) {
        market = new Market__c(
          Name = 'SF Market',
          publication_Year__c = String.valueOf(system.today().year()),
          Market_Close_Date__c = system.today().addDays(1)
        );

        insert market;
      }
      return market;
    }
    private set;
  }

  public static Opportunity opportunity {
    get {
      if (opportunity == null) {
        OpportunityStage stage = [
          SELECT MasterLabel
          FROM OpportunityStage
          WHERE IsWon = FALSE AND IsClosed = FALSE AND isActive = TRUE
          LIMIT 1
        ];
        system.debug(
          ' ### Queries: ' +
          Limits.getQueries() +
          '/' +
          Limits.getLimitQueries()
        );
        opportunity = new Opportunity(
          Name = 'Test Opp',
          AccountId = account.Id,
          StageName = stage.MasterLabel,
          CloseDate = system.today().addDays(-15),
          PriceBook2Id = StandardPriceBookId,
          Market_Project__c = market.Id,
          Next_call_date__c = system.today()
        );
        insert opportunity;

        //opportunity = [select Id, Name, AccountId, StageName, closeDate, PriceBook2Id, Pricebook2.Name from Opportunity where Id = : opportunity.Id];
        //system.debug(' ### opportunity ' + opportunity.PriceBook2Id + ' => ' + opportunity.Pricebook2.Name + ' opp ' + opportunity);
      }
      return opportunity;
    }
    private set;
  }

  public static list<OpportunityLineItem> oppLineItems {
    get {
      if (oppLineItems == null) {
        oppLineItems = new List<OpportunityLineItem>{
          new OpportunityLineItem(
            // Interest_Level__c = 'Interested',
            Description = 'Item 1',
            OpportunityId = opportunity.Id,
            Quantity = 1,
            ServiceDate = system.today(),
            pricebookEntryId = PricebookEntries[0].Id,
            TotalPrice = 100
          ),
          new OpportunityLineItem(
            // Interest_Level__c = 'Interested',
            Description = 'Item 2',
            OpportunityId = opportunity.Id,
            Quantity = 2,
            ServiceDate = system.today(),
            pricebookEntryId = PricebookEntries[1].Id,
            TotalPrice = 100
          )
        };
        insert oppLineItems;
      }
      return oppLineItems;
    }
    private set;
  }

  public static kugo2p__SalesOrder__c SalesOrder {
    get {
      if (SalesOrder == null) {
        SalesOrder = new kugo2p__SalesOrder__c(
          kugo2p__Account__c = account.Id,
          kugo2p__Opportunity__c = opportunity.Id,
          kugo2p__OrderDate__c = system.today(),
          kugo2p__PriceBookName__c = CustomPriceBook.Name,
          kugo2p__DiscountPercent__c = null,
          kugo2p__PaymentMethod__c = 'Authorize.Net',
          kugo2p__ContactShipping__c = contacts[0].Id,
          kugo2p__ContactBuying__c = contacts[0].Id,
          kugo2p__ContactBilling__c = contacts[0].Id,
          kugo2p__RecordStatus__c = 'Draft',
          kugo2p__Warehouse__c = warehouses[0].Id,
          kugo2p__ShipToStreet__c = 'https://kugamon.com/sitesurl',
          kugo2p__InvoiceSchedule__c = InvoiceSchedules[3].Id,
          // FS04 changes
          kugo2p__ShipToName__c = (contacts[0].FirstName +
          ' ' +
          contacts[0].LastName),
          kugo2p__ShipToStreetLong__c = contacts[0].MailingStreet,
          kugo2p__ShipToCity__c = contacts[0].MailingCity,
          kugo2p__ShipToStateProvince__c = contacts[0].MailingState,
          kugo2p__ShipToZipPostalCode__c = contacts[0].MailingPostalCode,
          Market__c = market.Id,
          FinanceOverride__c = true,
          Shipping_Type__c = 'Residential',
          FulfillOrder__c = false,
          FinanceTerm__c = '12'
        );
        insert SalesOrder;

        // update Sales Order to override Ship to Street address
        kugo2p__SalesOrder__c tempSO = new kugo2p__SalesOrder__c(
          Id = SalesOrder.Id,
          kugo2p__ShipToStreet__c = 'https://kugamon.com/sitesurl'
        );
        update tempSO;
      }
      return SalesOrder;
    }
    set;
  }

  public static list<kugo2p__SalesOrderProductLine__c> OrderProductLines {
    get {
      if (OrderProductLines == null) {
        OrderProductLines = new List<kugo2p__SalesOrderProductLine__c>{
          new kugo2p__SalesOrderProductLine__c(
            kugo2p__LineDescription__c = 'Item 1',
            kugo2p__SalesOrder__c = SalesOrder.id,
            kugo2p__Quantity__c = 10,
            kugo2p__Product__c = APDs[0].Id,
            kugo2p__DateAvailableToPromise__c = System.today(),
            kugo2p__DateRequired__c = System.today(),
            kugo2p__ContactShipping__c = contacts[0].Id,
            kugo2p__OpportunityLineItemId__c = oppLineItems[0].Id,
            kugo2p__SalesQuoteProductLine__c = QuoteProductLines[0].Id,
            kugo2p__Warehouse__c = warehouses[0].Id
          )
        };
        insert OrderProductLines;

        OrderProductLines = [
          SELECT
            Id,
            Name,
            kugo2p__SalesOrder__c,
            kugo2p__LineDescription__c,
            kugo2p__Quantity__c,
            kugo2p__ListPrice__c,
            kugo2p__SalesPrice__c,
            kugo2p__Product__c,
            kugo2p__DateRequired__c,
            kugo2p__ContactShipping__c,
            kugo2p__OpportunityLineItemId__c,
            kugo2p__SalesQuoteProductLine__c,
            kugo2p__SalesOrder__r.kugo2p__Account__c,
            kugo2p__Product__r.kugo2p__ReferenceProduct__r.Name,
            kugo2p__SalesOrder__r.kugo2p__ContactBuying__c,
            kugo2p__Product__r.kugo2p__ReferenceProduct__c,
            kugo2p__DiscountSalesPrice__c,
            kugo2p__DateAvailableToPromise__c,
            kugo2p__Warehouse__c
          FROM kugo2p__SalesOrderProductLine__c
          WHERE Id IN :OrderProductLines
        ];

        boolean updateSOPLs = false;
        for (kugo2p__SalesOrderProductLine__c sopl : OrderProductLines) {
          if (sopl.kugo2p__Warehouse__c != warehouses[0].Id) {
            updateSOPLs = true;
            sopl.kugo2p__Warehouse__c = warehouses[0].Id;
          }
        }
        system.debug(' ### updateSOPLs ' + updateSOPLs);
        if (updateSOPLs)
          update OrderProductLines;
      }
      return OrderProductLines;
    }
    private set;
  }

  public static list<kugo2p__SalesOrderServiceLine__c> OrderServiceLines {
    get {
      if (OrderServiceLines == null) {
        OrderServiceLines = new List<kugo2p__SalesOrderServiceLine__c>{
          new kugo2p__SalesOrderServiceLine__c(
            kugo2p__LineDescription__c = 'Item 2',
            kugo2p__SalesOrder__c = SalesOrder.Id,
            kugo2p__Quantity__c = 2,
            kugo2p__Service__c = APDs[1].Id,
            kugo2p__DateServiceStart__c = System.today(),
            kugo2p__DateServiceEnd__c = System.today().addMonths(2),
            kugo2p__ServiceTerm__c = 2,
            kugo2p__OpportunityLineItemId__c = oppLineItems[1].Id,
            kugo2p__SalesQuoteServiceLine__c = QuoteServiceLines[0].Id
          )
        };

        insert OrderServiceLines;

        SalesOrder = getSalesOrder(SalesOrder.Id);
        //system.debug(' ### SalesOrder ' + SalesOrder.kugo2p__PriceBookName__c + ' => ' + SalesOrder);
      }
      return OrderServiceLines;
    }
    private set;
  }

  public static list<kugo2p__AdditionalChargeCredit__c> accs {
    get {
      if (accs == null) {
        accs = new List<kugo2p__AdditionalChargeCredit__c>{
          new kugo2p__AdditionalChargeCredit__c(
            Name = 'Shipping Fee',
            kugo2p__UnitPrice__c = 25,
            kugo2p__IsActive__c = true
          ),
          new kugo2p__AdditionalChargeCredit__c(
            Name = 'Late Fee',
            kugo2p__UnitPrice__c = 50,
            kugo2p__IsActive__c = true
          )
        };

        insert accs;
      }
      return accs;
    }
    private set;
  }

  public static list<kugo2p__SalesQuoteAdditionalChargeCredit__c> QuoteACCs {
    get {
      if (QuoteACCs == null) {
        QuoteACCs = new List<kugo2p__SalesQuoteAdditionalChargeCredit__c>{
          new kugo2p__SalesQuoteAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[0].Id,
            kugo2p__SalesQuote__c = SalesQuote.Id,
            kugo2p__Quantity__c = 1,
            kugo2p__LineDescription__c = 'Acc Desc 1'
          ),
          new kugo2p__SalesQuoteAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[1].Id,
            kugo2p__SalesQuote__c = SalesQuote.Id,
            kugo2p__Quantity__c = 2,
            kugo2p__LineDescription__c = 'Acc Desc 2'
          )
        };
        insert QuoteACCs;
      }
      return QuoteACCs;
    }
    private set;
  }

  public static list<kugo2p__SalesOrderAdditionalChargeCredit__c> OrderACCs {
    get {
      if (OrderACCs == null) {
        OrderACCs = new List<kugo2p__SalesOrderAdditionalChargeCredit__c>{
          new kugo2p__SalesOrderAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[0].Id,
            kugo2p__SalesOrder__c = SalesOrder.Id,
            kugo2p__Quantity__c = 1,
            kugo2p__LineDescription__c = 'Acc Desc 1'
          ),
          new kugo2p__SalesOrderAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[1].Id,
            kugo2p__SalesOrder__c = SalesOrder.Id,
            kugo2p__Quantity__c = 2,
            kugo2p__LineDescription__c = 'Acc Desc 2'
          )
        };
        insert OrderACCs;
      }
      return OrderACCs;
    }
    private set;
  }

  public static kugo2p__SalesQuote__c SalesQuote {
    get {
      if (SalesQuote == null) {
        SalesQuote = new kugo2p__SalesQuote__c(
          kugo2p__Account__c = Account.Id,
          kugo2p__Opportunity__c = opportunity.Id,
          kugo2p__PriceBookName__c = CustomPriceBook.Name,
          kugo2p__Warehouse__c = warehouses[0].Id
        );
        insert SalesQuote;
      }
      return SalesQuote;
    }
    private set;
  }

  public static list<kugo2p__SalesQuoteProductLine__c> QuoteProductLines {
    get {
      if (QuoteProductLines == null) {
        QuoteProductLines = new List<kugo2p__SalesQuoteProductLine__c>{
          new kugo2p__SalesQuoteProductLine__c(
            kugo2p__LineDescription__c = 'Item 1',
            kugo2p__SalesQuote__c = SalesQuote.Id,
            kugo2p__Quantity__c = 1,
            kugo2p__Product__c = APDs[0].Id,
            kugo2p__DateRequired__c = system.today().addMonths(2),
            kugo2p__OpportunityLineItemId__c = oppLineItems[0].Id
          )
        };
        insert QuoteProductLines;
      }

      return QuoteProductLines;
    }
    private set;
  }

  public static list<kugo2p__SalesQuoteServiceLine__c> QuoteServiceLines {
    get {
      if (QuoteServiceLines == null) {
        QuoteServiceLines = new List<kugo2p__SalesQuoteServiceLine__c>{
          new kugo2p__SalesQuoteServiceLine__c(
            kugo2p__LineDescription__c = 'Item 2',
            kugo2p__SalesQuote__c = SalesQuote.Id,
            kugo2p__Quantity__c = 3,
            kugo2p__Service__c = APDs[1].Id,
            kugo2p__DateServiceStart__c = system.today().addMonths(2),
            kugo2p__DateServiceEnd__c = system.today().addMonths(4),
            kugo2p__ServiceTerm__c = 2,
            kugo2p__OpportunityLineItemId__c = oppLineItems[1].Id
          )
        };
        insert QuoteServiceLines;
      }

      return QuoteServiceLines;
    }
    private set;
  }

  public static list<kugo2p__SalesQuoteOptionalLine__c> QuoteOptionalLines {
    get {
      if (QuoteOptionalLines == null) {
        QuoteOptionalLines = new List<kugo2p__SalesQuoteOptionalLine__c>{
          new kugo2p__SalesQuoteOptionalLine__c(
            kugo2p__SalesQuote__c = SalesQuote.Id,
            kugo2p__ProductService__c = apds[0].Id,
            kugo2p__ListPrice__c = 100,
            kugo2p__SalesPrice__c = 85,
            kugo2p__LineDescription__c = 'Optional product'
          ),
          new kugo2p__SalesQuoteOptionalLine__c(
            kugo2p__SalesQuote__c = SalesQuote.Id,
            kugo2p__ProductService__c = apds[1].Id,
            kugo2p__ListPrice__c = 100,
            kugo2p__SalesPrice__c = 85,
            kugo2p__LineDescription__c = 'Optional service'
          )
        };
        insert QuoteOptionalLines;
      }
      return QuoteOptionalLines;
    }
    private set;
  }

  public static kugo2p__KugamonInvoice__c Invoice {
    get {
      if (Invoice == null) {
        Invoice = new kugo2p__KugamonInvoice__c(
          kugo2p__Account__c = account.Id,
          kugo2p__AdditionalAccountDetail__c = AdditionalAccountDetail.Id,
          kugo2p__InvoiceDate__c = Date.today(),
          kugo2p__InvoiceDueDate__c = Date.today().addDays(4),
          kugo2p__RecordStatus__c = 'Unsent',
          kugo2p__ContactBilling__c = contacts[0].Id
        );
        insert invoice;
      }
      return Invoice;
    }
    private set;
  }

  public static list<kugo2p__KugamonInvoiceLine__c> InvoiceLines {
    get {
      if (InvoiceLines == null) {
        InvoiceLines = new List<kugo2p__KugamonInvoiceLine__c>{
          new kugo2p__KugamonInvoiceLine__c(
            kugo2p__Invoice__c = Invoice.Id,
            kugo2p__SalesOrder__c = SalesOrder.Id,
            kugo2p__SalesOrderProductLine__c = OrderProductLines[0].Id,
            kugo2p__ProductService__c = apds[0].Id,
            kugo2p__UnitOfMeasure__c = apds[0].kugo2p__UnitOfMeasure__c,
            kugo2p__UnitOfTerm__c = apds[0].kugo2p__UnitOfTerm__c, //ShipmentLine__c = shipmentLine.Id,
            kugo2p__CalculatedQuantity__c = 1,
            kugo2p__Quantity__c = 1,
            kugo2p__LineDescription__c = OrderProductLines[0]
              .kugo2p__LineDescription__c
          ),
          new kugo2p__KugamonInvoiceLine__c(
            kugo2p__Invoice__c = Invoice.Id,
            kugo2p__SalesOrder__c = SalesOrder.Id,
            kugo2p__SalesOrderServiceLine__c = OrderServiceLines[0].Id,
            kugo2p__ProductService__c = apds[1].Id,
            kugo2p__UnitOfMeasure__c = apds[1].kugo2p__UnitOfMeasure__c,
            kugo2p__UnitOfTerm__c = apds[1].kugo2p__UnitOfTerm__c, //ShipmentLine__c = shipmentLine.Id,
            kugo2p__CalculatedQuantity__c = 1,
            kugo2p__Quantity__c = 1,
            kugo2p__LineDescription__c = OrderServiceLines[0]
              .kugo2p__LineDescription__c
          )
        };
        insert InvoiceLines;
      }
      return InvoiceLines;
    }
    private set;
  }

  public static list<kugo2p__KugamonInvoiceAdditionalChargeCredit__c> InvoiceACCs {
    get {
      if (InvoiceACCs == null) {
        InvoiceACCs = new List<kugo2p__KugamonInvoiceAdditionalChargeCredit__c>{
          new kugo2p__KugamonInvoiceAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[0].Id,
            kugo2p__Invoice__c = Invoice.Id,
            kugo2p__Quantity__c = 1,
            kugo2p__LineDescription__c = 'Acc Desc 1'
          ),
          new kugo2p__KugamonInvoiceAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[1].Id,
            kugo2p__Invoice__c = Invoice.Id,
            kugo2p__Quantity__c = 2,
            kugo2p__LineDescription__c = 'Acc Desc 2'
          )
        };
        insert InvoiceACCs;
      }
      return InvoiceACCs;
    }
    private set;
  }

  public static list<LineRecipient__c> LineRecipients {
    get {
      if (LineRecipients == null) {
        LineRecipients = new List<LineRecipient__c>{
          new LineRecipient__c(
            Order__c = salesOrder.Id,
            OrderProductLine__c = OrderProductLines[0].Id,
            OrderServiceLine__c = null,
            Recipient__c = contacts[1].Id,
            Primary__c = true
          )
        };
        insert LineRecipients;
      }
      return LineRecipients;
    }
    private set;
  }

  public static kugo2p__Payment_Profile__c RecurringCharge {
    get {
      if (RecurringCharge == null) {
        RecurringCharge = new kugo2p__Payment_Profile__c(
          Name = 'Test Profile',
          kugo2p__AuthNet_Subscription_Id__c = '13224sskjfs',
          kugo2p__SalesOrder__c = salesOrder.Id,
          kugo2p__Contact__c = contacts[0].Id,
          kugo2p__Amount__c = salesOrder.kugo2p__BalanceDueAmount__c,
          kugo2p__Subscription_Status__c = 'Not Active',
          kugo2p__Frequency__c = 1,
          kugo2p__Period__c = 'Month',
          kugo2p__Total_Occurrences__c = 1
        );

        insert RecurringCharge;
      }
      return RecurringCharge;
    }
    private set;
  }

  // FS04 - Five Star changes
  public static list<kuga_FinanceChargeRule__c> FinanceChargeRules {
    get {
      if (FinanceChargeRules == null) {
        delete [
          SELECT Id
          FROM kuga_FinanceChargeRule__c
          WHERE kuga_Term__c = 3
        ];

        FinanceChargeRules = new List<kuga_FinanceChargeRule__c>{
          new kuga_FinanceChargeRule__c(
            kuga_KugamonSetting__c = KugamonSettings.Id,
            kuga_IsFinanceCharged__c = true,
            kuga_IsFinanceOverride__c = false,
            kuga_MinimumInitialPaymentAmount__c = 3,
            kuga_MinimumOrderAmount__c = 3,
            kuga_Term__c = 3
          )
        };
        insert FinanceChargeRules;
      }
      return FinanceChargeRules;
    }
    private set;
  }

  public static List<PaymentSchedule__c> paymentSchedules {
    get {
      if (paymentSchedules == null) {
        List<PaymentSchedule__c> schedules = new List<PaymentSchedule__c>();
        PaymentSchedule__c sch = new PaymentSchedule__c();
        sch.OrderNumber__c = SalesOrder.Id;
        sch.Amount__c = 100;
        schedules.add(sch);
        insert schedules;
        return schedules;
      } else {
        return [ SELECT Id, Amount__c, OrderNumber__c FROM PaymentSchedule__c];
      }
    }
    private set;
  }

  public static List<PaymentSchedule__c> getPaymentSchedules() {
    return paymentschedules;
  }

  public static kugo2p__SalesOrder__c getOrder() {
    return SalesOrder;
  }

  public static kugo2p__AdditionalAccountDetail__c additionalAccountDetail() {
    return AdditionalAccountDetail;
  }

  public static Pricebook2 getPricebook() {
    return [ SELECT Id, Name FROM Pricebook2 WHERE Id = :Test.getStandardPricebookId() ];
  }

  public static void setupPricebook() {
    System.debug('TEST - setup pricebook');
    Product2 prod = new Product2(Name = 'Laptop X200', Family = 'Hardware');
    insert prod;
        
    Id pricebookId = Test.getStandardPricebookId();
    Pricebook2 pb = new Pricebook2();
    pb.Id = Test.getStandardPricebookId();
    pb.isActive = true;
    update pb;
        
    PricebookEntry standardPrice = new PricebookEntry(
      Pricebook2Id = pricebookId, Product2Id = prod.Id,
      UnitPrice = 10000, IsActive = true
    );
    insert standardPrice;
        
    Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
    insert customPB;
        
    PricebookEntry customPrice = new PricebookEntry(
      Pricebook2Id = customPB.Id, Product2Id = prod.Id,
      UnitPrice = 12000, IsActive = true
    );
    insert customPrice;
  }

  public static String dynamicQuery(String objectName, Integer num) {
    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objectName).getDescribe().fields.getMap();

    List<String>apiNames =  new List<String>();

    for ( String apiName : fieldMap.keyset() ) {
      if(fieldMap.get(apiName).getDescribe().isCreateable()) {
        apiNames.add(apiName);
      }
    }

    String fields = String.join(apiNames, ',');

    return 'SELECT ' + fields + ' FROM ' + objectName + ' LIMIT ' + (num == null ? 1 : num);
  }

  public static void callEverythingForTest() {
    setupPricebook();
    testSetup();
    kugamonSettings();
    String s = CurrencyIsoCodeField;
    String stdName = StandardPriceBookName;
    Id pbId = StandardPriceBookId;
    Pricebook2 pb2 = CustomPriceBook;
    List<kugo2p__InvoiceSchedule__c> invSchedule = InvoiceSchedules;
    kugo2p__Settings__c paysettings = PaymentSettings;
    kugo2p__Processor_Connection__c processconnect = ProcessorConnection;
    list<kugo2p__Warehouse__c> whs = warehouses;
    list<Product2> pdts = products;
    list<kugo2p__AdditionalProductDetail__c> productdetails = APDs;
    list<PricebookEntry> pbentries = PricebookEntries;
    list<kugo2p__Tier__c> trs = tiers;
    list<RecommendedProduct__c> rpdts = RecommendedProducts;
    list<kugo2p__KitBundleMember__c> kbms = kitBundleMembers;
    account ac = account;
    kugo2p__AdditionalAccountDetail__c accountdetails = AdditionalAccountDetail;
    list<Contact> cts = contacts;
    Market__c mkt = market;
    Opportunity opp = opportunity;
    // list<OpportunityLineItem> olis = oppLineItems;
    // kugo2p__SalesOrder__c sord = SalesOrder;
    list<kugo2p__SalesOrderProductLine__c> orderlines = OrderProductLines;
    list<kugo2p__SalesOrderServiceLine__c> servicelines = OrderServiceLines;
    list<kugo2p__AdditionalChargeCredit__c> chargecredits = accs;
    list<kugo2p__SalesQuoteAdditionalChargeCredit__c> quotechrages = QuoteACCs;
    kugo2p__SalesQuote__c sq = SalesQuote;
    // list<kugo2p__SalesQuoteProductLine__c> qpls = QuoteProductLines;
    list<kugo2p__SalesQuoteServiceLine__c> qsrvlines = QuoteServiceLines;
    list<kugo2p__SalesQuoteOptionalLine__c> qoptlines = QuoteOptionalLines;
    kugo2p__KugamonInvoice__c inv = Invoice;
    // list<kugo2p__KugamonInvoiceLine__c> invlines = InvoiceLines;
    list<kugo2p__KugamonInvoiceAdditionalChargeCredit__c> invaccs = InvoiceACCs;
    list<LineRecipient__c> linerecps = LineRecipients;
    kugo2p__Payment_Profile__c reccharge = RecurringCharge;
    list<kuga_FinanceChargeRule__c> finchargerules = FinanceChargeRules;
    list<kugo2p__SalesOrderAdditionalChargeCredit__c> oaccs = OrderACCs;
  }
}