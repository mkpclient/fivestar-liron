/* --------------------------------------- */
/*   CustomDocumentTests class by Kugamon  */
/*   Copyright: Kugamon LLC                */
/*   http://www.kugamon.com                */
/*   NO SUPPORT PROVIDED                   */
/*   DO NOT COPY, STEAL, SELL THIS CODE    */
/* --------------------------------------- */

@isTest //(seeAllData=true)
public class CustomDocumentTests {

    static testMethod void test_CustomOrderPDFExt() {

        DataSetup();

        // Switch to test context
        Test.startTest();

        CustomOrderPDFExt orderpdf = new CustomOrderPDFExt();
        orderpdf.orderIdValue = SalesOrder.Id;

        // CustomOrderPDFExt orderpdf = new CustomOrderPDFExt(new ApexPages.StandardController(SalesOrder));
        //orderpdf.orderIdValue = SalesOrder.Id;

        // system.assertEquals(orderpdf.Order.Id, SalesOrder.Id);
        // system.assertNotEquals(orderpdf.settings.Id, null);
        // system.assertEquals(orderpdf.ProductLines.isEmpty(), false);
        // system.assertEquals(orderpdf.ServiceLines.isEmpty(), false);
        // system.assertNotEquals(orderpdf.ACCLines.isEmpty(), null);

        // system.assertNotEquals(orderpdf.downloadPDFURL, null);
        // system.assertNotEquals(orderpdf.getPaymentURL(), null);

        orderpdf.orderPDFExt.acceptTerms = true;
        orderpdf.orderPDFExt.acceptedBy = 'Kiran';
        orderpdf.orderPDFExt.initialBy = 'KK';
        orderpdf.encodedSignature = 'Test Signature';

        orderpdf.AcceptAndPayOnline();

        orderpdf.Order.kugo2p__RecordStatus__c = 'Draft';
        orderpdf.checkout();

        //system.assertNotEquals(orderpdf.SignatureUrl, null);

        // system.assertEquals(orderpdf.LineRecipients.isEmpty(), true);
        // system.assertEquals(orderpdf.PaymentSchedules.isEmpty(), true);

        // Switch back to runtime context
        Test.stopTest();
    }
    
    static testMethod void test_CustomOrderPDFExt2() {

        DataSetup();

        // Switch to test context
        Test.startTest();

        SalesOrder.kugo2p__PaymentMethod__c = 'Credit Card';
        update SalesOrder;

        CustomOrderPDFExt orderpdf = new CustomOrderPDFExt(new ApexPages.StandardController(SalesOrder));

        orderpdf.orderPDFExt.acceptTerms = true;
        orderpdf.orderPDFExt.acceptedBy = 'Kiran';
        orderpdf.orderPDFExt.initialBy = 'KK';
        orderpdf.encodedSignature = 'Test Signature';

        orderpdf.AcceptAndPayOnline();

        orderpdf.Order.kugo2p__RecordStatus__c = 'Draft';
        orderpdf.checkout();

        //system.assertNotEquals(orderpdf.SignatureUrl, null);

        // Switch back to runtime context
        Test.stopTest();
    }
    
    static testMethod void test_CustomInvoicePDFExt() {

        DataSetup();

        // Switch to test context
        Test.startTest();

        CustomInvoicePDFExt invoicepdf = new CustomInvoicePDFExt();
        // invoicepdf.invoiceIdValue = Invoice.Id;
        
        // invoicepdf = new CustomInvoicePDFExt(new ApexPages.StandardSetController(new kugo2p__KugamonInvoice__c[] {Invoice}));

        // invoicepdf = new CustomInvoicePDFExt(new ApexPages.StandardController(Invoice));
        //orderpdf.orderIdValue = SalesOrder.Id;

        // system.assertEquals(invoicepdf.Invoice.Id, Invoice.Id);
        // system.assertNotEquals(invoicepdf.settings.Id, null);
        // system.assertEquals(invoicepdf.InvoiceLines.isEmpty(), false);
        // system.assertNotEquals(invoicepdf.ACCLines.isEmpty(), null);

        // system.assertNotEquals(invoicepdf.downloadPDFURL, null);
        // system.assertNotEquals(invoicepdf.getPaymentURL(), null);
        
        // invoicepdf.getAcceptAndPayOnline();

        // system.assertEquals(invoicepdf.LineRecipients.isEmpty(), true);        

        // Switch back to runtime context
        Test.stopTest();
    }
    
    static testMethod void test_CustomKontroller() {

        DataSetup();

        // Switch to test context
        Test.startTest();
        
        PageReference ref = ApexPages.CurrentPage();
        ref.getParameters().put('action', 'attachPDF');
        ref.getParameters().put('p', 'pdf');
        
        // quote
        ref.getParameters().put('object', 'quote');
        ref.getParameters().put('Id', SalesQuote.Id);
        ref.getParameters().put('pdfName', SalesQuote.Name);

        CustomKontroller ck = new CustomKontroller();
        ck.Director();
        
        // order
        ref.getParameters().put('object', 'order');
        ref.getParameters().put('Id', SalesOrder.Id);
        ref.getParameters().put('pdfName', SalesOrder.Name);
        ck.Director();
        
        // invoice
        ref.getParameters().put('object', 'invoice');
        ref.getParameters().put('Id', Invoice.Id);
        ref.getParameters().put('pdfName', Invoice.Name);
        // ck.Director();

        // Switch back to runtime context
        Test.stopTest();
    }

/*****************************************************************************************************************************************
												Setup test data
 *****************************************************************************************************************************************/

	public static boolean hasSObjectField(String objName, string fieldName) {

		boolean fieldExists = false;
        try {

            SObject so = Schema.getGlobalDescribe().get(objName).newSObject();
            fieldExists = so.getSobjectType().getDescribe().fields.getMap().containsKey(fieldName);

        } catch (Exception ex) {
        	// do nothing
        	system.debug(' ### exception in hasSObjectField ' + ex);
        }

		system.debug(' ### objName ' + objName + ' fieldName ' + fieldName + ' exists? ' + fieldExists);

        return fieldExists;
    }
 
 	public static String CurrencyIsoCodeField {
		get {
			return kugo2p.Currencies.isMultiCurrencyEnabled ? 'CurrencyIsoCode, ' : '';
		}
	}

    public static kugo2p__SalesOrder__c getSalesOrder(Id soId) {
		return Database.query('select Id, Name, ' + CurrencyIsoCodeField + 'kugo2p__Account__c, kugo2p__Account__r.Name,' + 
				                       'kugo2p__Opportunity__c, kugo2p__OrderDate__c, kugo2p__PriceBookName__c, kugo2p__DateRequired__c, kugo2p__ServiceDateRequired__c, kugo2p__PaymentTerms__c,' + 
				                       'kugo2p__BillingFrequency__c, kugo2p__RecordStatus__c, kugo2p__PaymentMethod__c, kugo2p__DiscountPercent__c, kugo2p__ShipToStreet__c ' +
                				' from kugo2p__SalesOrder__c where Id = :soId');
    }

	//@testSetup
    public static void DataSetup() {
        kugo2p.Kugamon.TestMode = true;

        // this is a workaround solution to enable Standard Price Book
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

		// create Kugamon Settings
        // system.assertNotEquals(KugamonSettings.Id, null);

        // create processor Connection and Payment Settings
        // system.assertNotEquals(ProcessorConnection.Id, null);

		// system.assertEquals(Products.isEmpty(), false);
		// system.assertEquals(APDs.isEmpty(), false);

		// system.assertEquals(tiers.isEmpty(), false);

        // create oppty and line items
        //system.assertEquals(opportunity.isEmpty(), false);
        // system.assertEquals(oppLineItems.isEmpty(), false);

        // create sales quote, product and service lines
        // system.assertEquals(QuoteProductLines.isEmpty(), false);
        // system.assertEquals(QuoteServiceLines.isEmpty(), false);
        // system.assertEquals(QuoteOptionalLines.isEmpty(), false);

        // create sales order, product and service lines
        // system.assertEquals(OrderProductLines.isEmpty(), false);
        // system.assertEquals(OrderServiceLines.isEmpty(), false);

        // create Quote and Order Acc lines 
        // system.assertEquals(QuoteACCs.isEmpty(), false);
        // system.assertEquals(OrderACCs.isEmpty(), false);
        
        // create invoice and its relationship
        // system.assertNotEquals(Invoice.Id, null);
        // system.assertEquals(InvoiceLines.isEmpty(), false);
        // system.assertEquals(InvoiceACCs.isEmpty(), false);
        
        // kugo2p__OrderInvoiceRelationship__c oir = new kugo2p__OrderInvoiceRelationship__c(kugo2p__Invoice__c=Invoice.Id, kugo2p__SalesOrder__c=SalesOrder.Id);
        // insert oir;        
    }

	public static String StandardPriceBookName = 'Standard Price Book';
	public static Id StandardPriceBookId {
	    get {
	    	if (StandardPriceBookId == null) {
	    		StandardPriceBookId = Test.getStandardPricebookId();
	    	}
	    	return StandardPriceBookId;
	    }
	}    

    private static Pricebook2 CustomPriceBook {
        get {
            if (CustomPriceBook == null) {
                CustomPriceBook = new Pricebook2(Name='Test pricebook', IsActive=true, Description='Test');
                insert CustomPriceBook;
            }
            return CustomPriceBook;
        }

        private set;
    }

	public static kugo2p__KugamonSetting__c KugamonSettings {
		get {
			if (KugamonSettings == null) {
	  			KugamonSettings = new kugo2p__KugamonSetting__c(Name = 'My Org Setting', kugo2p__PriceBookName__c = CustomPriceBook.Name, 
	  													kugo2p__PrintSpecificTextandTerms__c = false,
	  													kugo2p__UnitOfMeasure__c = 'Each', kugo2p__TaxableExcise__c = false, kugo2p__TaxableSales__c = true, 
	  													kugo2p__TaxableUsage__c = false, kugo2p__TaxableVat__c = false, kugo2p__AutoReleaseOrder__c = false, 
	  													kugo2p__CompanyTextAndTerms__c = 'This legally binding Order Form is governed by the Master Subscription Agreement between Customer and Kugamon LLC. Prices shown do not include any taxes that may apply. Any such taxes are the responsibility of Customer. Sandbox subscriptions, if ordered, are for testing and development use only and not for production use. Subscriptions are non-cancelable before their End Date.', 
	  													kugo2p__PrintCompanyTextAndTerms__c = true, kugo2p__SpecificTextandTerms__c='Specific Terms & Conditions',
	  													kugo2p__PrintInvoiceTextandTerms__c=true, kugo2p__InvoiceTextandTerms__c='Invoice Terms', 
	  													kugo2p__PaymentMethod__c='Debit/Credit Card', kugo2p__PaymentTerms__c='Due Upon Receipt', kugo2p__DaysTillPaymentDue__c=0,
	  													kugo2p__Admin_User__c=UserInfo.getUserId(), kugo2p__OnlinePaymentButton__c='Accept & Pay', kugo2p__OnlineConfirmationTextandTerms__c='Confirmation Text'); 
				insert KugamonSettings;

                KugamonSettings.kugo2p__WareHouse__c = warehouse.Id;
                update KugamonSettings;
			}
			return KugamonSettings;
		}
		private set;
	}

	public static kugo2p__Settings__c PaymentSettings {
		get {
			if (PaymentSettings == null) {
	  			PaymentSettings = new kugo2p__Settings__c(Name = 'Test Payment Settings', kugo2p__Gateway_Simulation_Mode__c = true, kugo2p__Admin_User__c = UserInfo.getUserId());
				insert PaymentSettings;
			}
			return PaymentSettings;
		}
		private set;
	}

	public static kugo2p__Processor_Connection__c ProcessorConnection {
		get {
			if (ProcessorConnection == null) {
	  			ProcessorConnection = new kugo2p__Processor_Connection__c(Name = 'Test Processor Connection', kugo2p__Account_Type__c='Website Payments Pro', kugo2p__PaymentConnect_Setup__c = PaymentSettings.Id, 
	  																kugo2p__Default_Connection__c = true, kugo2p__Assigned_To_Terminal__c = true, kugo2p__Processor_Id__c = 'PayPal',
	  																kugo2p__Enabled_Card_Types__c='Visa; Mastercard; Amex; Discover', kugo2p__Site_Checkout__c='Both', kugo2p__PDF_Checkout__c='Native', 
	  																kugo2p__Tokenized_Card_Service_Enabled__c=true, kugo2p__Test_Mode__c=true,
	  																kugo2p__Notification_Relay_Method__c='Visualforce', kugo2p__Relay_Id__c='kugo2p__PayPalRelay', 
	  																kugo2p__Relay_Script__c='https://kugamon-customdoc-developer-edition.na15.force.com/kugo2p__PayPalRelay');
				insert ProcessorConnection;
			}
			return ProcessorConnection;
		}
		private set;
	}

    public static kugo2p__WareHouse__c warehouse {
        get {
            if (warehouse == null) {
                warehouse = new kugo2p__WareHouse__c(Name = 'Test Main', kugo2p__KugamonSetting__c=KugamonSettings.Id, kugo2p__Description__c = 'Main Warehouse', kugo2p__WarehouseStreet__c = '900 Stanyan St', kugo2p__WareHouseCity__c = 'San Fransisco', kugo2p__WareHouseStateProvince__c = 'California', kugo2p__WareHouseZipPostalCode__c = '94117', kugo2p__WareHouseCountry__c = 'United States');
                insert warehouse;
            }
            return warehouse;
        }
        private set;
    }

    public static list<Product2> Products {
        get {
            if (Products == null) {

                Products = new list<Product2> {
                    new Product2(Name = 'Test GenWatt Diesel 100kW', ProductCode = 'GC1040', Family = 'Test Generator', IsActive = true),
                    new Product2(Name = 'Test GenWatt Diesel 200kW', ProductCode = 'GC1041', Family = 'Test Generator1', IsActive = true)
                };

                insert Products;

                // system.assertEquals(APDs.size() > 0, true);
                // system.assertEquals(PricebookEntries.isEmpty(), false);
            }
            return Products;
        }
        private set;
    }

    public static list<kugo2p__AdditionalProductDetail__c> APDs {
        get {
            if (APDs == null) {
                APDs = [Select Id, Name, kugo2p__ProductDescription__c, kugo2p__ProductFamily__c, kugo2p__ReferenceProduct__c, kugo2p__Service__c, kugo2p__StandardPrice__c, kugo2p__UnitCost__c, kugo2p__Active__c 
                          From kugo2p__AdditionalProductDetail__c 
                          Where kugo2p__ReferenceProduct__c in : Products];
                if ( APDs.size() > 1 ){
                    APDs[0].kugo2p__Service__c = false; 
                    APDs[0].kugo2p__PrintProductTextandTerms__c = true;
                    APDs[1].kugo2p__Service__c = true;
                    APDs[1].kugo2p__UnitofTerm__c = 'Month';
                    APDs[1].kugo2p__DefaultServiceTerm__c = 1;
                    APDs[1].kugo2p__PrintProductTextandTerms__c = true;
                }
                update APDs;
            }
            return APDs;
        }
    }
    
    public static list<PricebookEntry> PricebookEntries {
        get {
            if (PricebookEntries == null) {
                PricebookEntries = new list<PricebookEntry> {
                    new PricebookEntry(Product2Id = Products[0].Id, Pricebook2Id = StandardPriceBookId, IsActive = true, UseStandardPrice = false, UnitPrice = 10),  
                    new PricebookEntry(Product2Id = Products[1].Id, Pricebook2Id = StandardPriceBookId, IsActive = true, UseStandardPrice = false, UnitPrice = 20),
                  
                    new PricebookEntry(Product2Id = Products[0].Id, Pricebook2Id = CustomPriceBook.Id, IsActive = true, UseStandardPrice = false, UnitPrice = 100),
                    new PricebookEntry(Product2Id = Products[1].Id, Pricebook2Id = CustomPriceBook.Id, IsActive = true, UseStandardPrice = false, UnitPrice = 200)
                };
                insert PricebookEntries;
            }
            return PricebookEntries;
        }
        private set;
    }
    
    public static list<kugo2p__TieredPricing__c> tieredPricing {
        get {
            if (tieredPricing == null) {
                tieredPricing = new list<kugo2p__TieredPricing__c> {
                    new kugo2p__TieredPricing__c(Name='Summer Product pricing', kugo2p__IsActive__c=true, kugo2p__Pricebook2Id__c=CustomPriceBook.Id, kugo2p__PriceBookName__c=CustomPriceBook.Name, kugo2p__Product__c=Products[0].Id)
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
                tiers = new list<kugo2p__Tier__c> {
                    new kugo2p__Tier__c(kugo2p__TieredPricing__c=tieredPricing[0].Id, kugo2p__QuantityStart__c=10, kugo2p__TierPrice__c=10.00),
                    new kugo2p__Tier__c(kugo2p__TieredPricing__c=tieredPricing[0].Id, kugo2p__QuantityStart__c=20, kugo2p__TierPrice__c=20.00),
                    new kugo2p__Tier__c(kugo2p__TieredPricing__c=tieredPricing[0].Id, kugo2p__QuantityStart__c=30, kugo2p__TierPrice__c=30.00)
                };
                insert tiers;
            }
            return tiers;
        }
        private set;
    }

    public static Account account {
        get {
            if (account == null) {
                account = new Account(Name = 'Test Account',Type = 'Customer - Direct',BillingStreet = '3545 Ave',BillingState = 'California',
                                              BillingPostalCode = '95050',BillingCountry = 'United States',ShippingStreet = '525 Ave',ShippingCity = 'San Jose',
                                              ShippingState = 'California',ShippingPostalCode = '95050',ShippingCountry = 'United States',Phone = '(336) 222-7000',
                                              Fax ='(336) 222-8000',AccountNumber = 'Test ANo',Website = 'www.kkk.com',Industry = 'Apparel',
                                              AnnualRevenue = 350000000,NumberOfEmployees = 9000,Ownership = 'Public',TickerSymbol = 'BTXT',
                                              Description = 'Test Account',Site = '');
                insert account;
            }
            return account;
        }
    }

    public static kugo2p__AdditionalAccountDetail__c AdditionalAccountDetail {
        get {
            if (AdditionalAccountDetail == null) {
                AdditionalAccountDetail = [select Id, kugo2p__PricebookName__c, kugo2p__Warehouse__c, kugo2p__PaymentMethod__c, kugo2p__ContactBilling__c, kugo2p__ContactBuying__c from kugo2p__AdditionalAccountDetail__c where kugo2p__Account__c = :account.Id];
                AdditionalAccountDetail.kugo2p__PricebookName__c = CustomPriceBook.Name;
                AdditionalAccountDetail.kugo2p__Warehouse__c = warehouse.Id;
                AdditionalAccountDetail.kugo2p__PaymentMethod__c = 'Check';
                AdditionalAccountDetail.kugo2p__ContactBilling__c = contact.Id;
                AdditionalAccountDetail.kugo2p__ContactBuying__c = contact.Id;                

                update AdditionalAccountDetail;
            }
            return AdditionalAccountDetail;
        }
    }

    public static Contact contact {
        get {
            if (contact == null) {
                contact = new Contact(AccountId=account.Id, FirstName='Wills', LastName='Smith', Email='kiran@kugamon.com', Phone='333-333-3333', MailingStreet='1 Kugamon Street', MailingState='California', MailingCity='SF', MailingPostalCode='95050', MailingCountry='United States');
                insert contact;
            }
            return contact;
        }
    }
    
    public static Opportunity opportunity {
        get {
            if (opportunity == null) {
				OpportunityStage stage = [Select MasterLabel From OpportunityStage Where IsWon=false and IsClosed=false and isActive=true Limit 1];
                system.debug(' ### Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
                opportunity = new Opportunity(Name = 'Test Opp', AccountId = account.Id, StageName = stage.MasterLabel, CloseDate = System.today().addDays(-15), 
                PriceBook2Id = CustomPriceBook.Id,
                Market_Project__c=market.Id, Next_call_date__c=system.today());
                insert opportunity;
            }
            return opportunity;
        }
    }

    public static Market__c market {
        get {
            if (market == null) {
                market = new Market__c(Name='Test pricebook', publication_Year__c=String.valueOf(system.today().year()), Market_Close_Date__c = system.today().addDays(1) );

                insert market;
            }
            return market;
        }
       private set;
    }
    
    public static list<OpportunityLineItem> oppLineItems {
        get {
            if (oppLineItems == null) {
                oppLineItems = new list<OpportunityLineItem> {
                  new OpportunityLineItem(Description='Item 1', OpportunityId=opportunity.Id, Quantity=1, ServiceDate=System.today(), pricebookEntryId=PricebookEntries[2].Id, TotalPrice=100),  
                  new OpportunityLineItem(Description='Item 2', OpportunityId=opportunity.Id, Quantity=2, ServiceDate=System.today(), pricebookEntryId=PricebookEntries[3].Id, TotalPrice=100)
                };

                // Sub org changes - dynamically add Service fields based upon the field existence 
                if (hasSObjectField('Opportunity', 'DateServiceEnd__c')) oppLineItems[1].put('DateServiceEnd__c', system.today().addMonths(2));
                if (hasSObjectField('Opportunity', 'ServiceTerm__c')) oppLineItems[1].put('ServiceTerm__c', 2);
                if (hasSObjectField('Opportunity', 'UnitofTerm__c')) oppLineItems[1].put('UnitofTerm__c', 'Month');

                insert oppLineItems;
            }
            return oppLineItems;
        }
        private set;
    }   

    public static kugo2p__SalesOrder__c SalesOrder {
        get {
            if (SalesOrder == null) {
                SalesOrder = new kugo2p__SalesOrder__c(kugo2p__Account__c = account.Id, kugo2p__Opportunity__c = opportunity.Id, kugo2p__OrderDate__c = system.today(),
                                                kugo2p__PriceBookName__c = CustomPriceBook.Name, kugo2p__DiscountPercent__c=null, kugo2p__PaymentMethod__c='Paypal',
                                                kugo2p__ContactShipping__c=contact.Id, kugo2p__ContactBuying__c=contact.Id, kugo2p__ContactBilling__c=contact.Id, kugo2p__RecordStatus__c='Draft', 
                                                kugo2p__Warehouse__c = warehouse.Id, kugo2p__ShipToStreet__c = 'https://kugamon.com/sitesurl');
                insert SalesOrder;

                // update Sales Order to override Ship to Street address
                kugo2p__SalesOrder__c tempSO = new kugo2p__SalesOrder__c(Id=SalesOrder.Id, kugo2p__ShipToStreet__c = 'https://kugamon.com/sitesurl');
                update tempSO;
            }
            return SalesOrder;
        }
    }

    public static list<kugo2p__SalesOrderProductLine__c> OrderProductLines {
        get {
            if (OrderProductLines == null) {
                OrderProductLines = new list<kugo2p__SalesOrderProductLine__c> {
                  new kugo2p__SalesOrderProductLine__c(kugo2p__LineDescription__c = 'Item 1', kugo2p__SalesOrder__c = SalesOrder.id, kugo2p__Quantity__c = 1, kugo2p__Product__c=APDs[0].Id, 
                  										kugo2p__DateAvailableToPromise__c=System.today(), kugo2p__DateRequired__c = System.today(), kugo2p__ContactShipping__c=contact.Id, 
                  										kugo2p__OpportunityLineItemId__c=oppLineItems[0].Id, kugo2p__SalesQuoteProductLine__c=QuoteProductLines[0].Id, kugo2p__Warehouse__c = warehouse.Id)
                };
                insert OrderProductLines;

                OrderProductLines = [Select Id, Name, kugo2p__SalesOrder__c, kugo2p__LineDescription__c, kugo2p__Quantity__c, kugo2p__ListPrice__c, kugo2p__SalesPrice__c, kugo2p__Product__c, kugo2p__DateRequired__c, 
                							kugo2p__ContactShipping__c, kugo2p__OpportunityLineItemId__c, kugo2p__SalesQuoteProductLine__c, kugo2p__SalesOrder__r.kugo2p__Account__c, 
                							kugo2p__Product__r.kugo2p__ReferenceProduct__r.Name, kugo2p__SalesOrder__r.kugo2p__ContactBuying__c, kugo2p__Product__r.kugo2p__ReferenceProduct__c, kugo2p__DiscountSalesPrice__c,
                							kugo2p__DateAvailableToPromise__c, kugo2p__Warehouse__c
                					 from 	kugo2p__SalesOrderProductLine__c
                					 where 	Id in :OrderProductLines];

				boolean updateSOPLs = false;
				for (kugo2p__SalesOrderProductLine__c sopl : OrderProductLines) {
					if (sopl.kugo2p__Warehouse__c != warehouse.Id) {
						updateSOPLs = true;
						sopl.kugo2p__Warehouse__c = warehouse.Id;
					}
				}
				system.debug(' ### updateSOPLs ' + updateSOPLs);
				if (updateSOPLs) update OrderProductLines;
            }
            return OrderProductLines;
        }
        private set;
    }
    
    public static list<kugo2p__SalesOrderServiceLine__c> OrderServiceLines {
        get {
            if (OrderServiceLines == null) {
                OrderServiceLines = new list<kugo2p__SalesOrderServiceLine__c> { 
                    new kugo2p__SalesOrderServiceLine__c(kugo2p__LineDescription__c = 'Item 2', kugo2p__SalesOrder__c = SalesOrder.Id, kugo2p__Quantity__c = 2, kugo2p__Service__c=APDs[1].Id, 
                    									kugo2p__DateServiceStart__c = System.today(), kugo2p__DateServiceEnd__c = system.today().addMonths(2), kugo2p__ServiceTerm__c=2, 
                    									kugo2p__OpportunityLineItemId__c=oppLineItems[1].Id, kugo2p__SalesQuoteServiceLine__c=QuoteServiceLines[0].Id)
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
                accs = new list<kugo2p__AdditionalChargeCredit__c> {
                    new kugo2p__AdditionalChargeCredit__c(Name='Shipping Fee', kugo2p__UnitPrice__c=25, kugo2p__IsActive__c=true),
                    new kugo2p__AdditionalChargeCredit__c(Name='Late Fee', kugo2p__UnitPrice__c=50, kugo2p__IsActive__c=true)
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
                QuoteACCs = new list<kugo2p__SalesQuoteAdditionalChargeCredit__c> {
                    new kugo2p__SalesQuoteAdditionalChargeCredit__c(kugo2p__AdditionalChargeCredit__c = accs[0].Id, kugo2p__SalesQuote__c = SalesQuote.Id, kugo2p__Quantity__c = 1, kugo2p__LineDescription__c = 'Acc Desc 1'),
                    new kugo2p__SalesQuoteAdditionalChargeCredit__c(kugo2p__AdditionalChargeCredit__c = accs[1].Id, kugo2p__SalesQuote__c = SalesQuote.Id, kugo2p__Quantity__c = 2, kugo2p__LineDescription__c = 'Acc Desc 2')
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
                OrderACCs = new list<kugo2p__SalesOrderAdditionalChargeCredit__c> {
                    new kugo2p__SalesOrderAdditionalChargeCredit__c(kugo2p__AdditionalChargeCredit__c = accs[0].Id, kugo2p__SalesOrder__c = SalesOrder.Id, kugo2p__Quantity__c = 1, kugo2p__LineDescription__c = 'Acc Desc 1'),
                    new kugo2p__SalesOrderAdditionalChargeCredit__c(kugo2p__AdditionalChargeCredit__c = accs[1].Id, kugo2p__SalesOrder__c = SalesOrder.Id, kugo2p__Quantity__c = 2, kugo2p__LineDescription__c = 'Acc Desc 2')
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
                SalesQuote = new kugo2p__SalesQuote__c(kugo2p__Account__c = account.Id, kugo2p__Opportunity__c = opportunity.Id, kugo2p__PriceBookName__c = CustomPriceBook.Name, kugo2p__Warehouse__c = warehouse.Id);
                insert SalesQuote;
            }
            return SalesQuote;
        }
        private set;
    }
    
    public static list<kugo2p__SalesQuoteProductLine__c> QuoteProductLines {
        get {
            if (QuoteProductLines == null) {
                QuoteProductLines = new list<kugo2p__SalesQuoteProductLine__c> {
                    new kugo2p__SalesQuoteProductLine__c(kugo2p__LineDescription__c = 'Item 1', kugo2p__SalesQuote__c = SalesQuote.Id, kugo2p__Quantity__c = 1, kugo2p__Product__c=APDs[0].Id, 
                    									kugo2p__DateRequired__c = system.today().addMonths(2), kugo2p__OpportunityLineItemId__c=oppLineItems[0].Id)
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
                QuoteServiceLines = new list<kugo2p__SalesQuoteServiceLine__c> {
                    new kugo2p__SalesQuoteServiceLine__c(kugo2p__LineDescription__c = 'Item 2', kugo2p__SalesQuote__c = SalesQuote.Id, kugo2p__Quantity__c = 3, kugo2p__Service__c=APDs[1].Id, 
                    									kugo2p__DateServiceStart__c = system.today().addMonths(2), kugo2p__DateServiceEnd__c = System.today().addMonths(4), kugo2p__ServiceTerm__c=2, 
                    									kugo2p__OpportunityLineItemId__c=oppLineItems[1].Id)
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
                QuoteOptionalLines = new list<kugo2p__SalesQuoteOptionalLine__c> {
                    new kugo2p__SalesQuoteOptionalLine__c(kugo2p__SalesQuote__c = SalesQuote.Id, kugo2p__ProductService__c = apds[0].Id, kugo2p__ListPrice__c = 100, kugo2p__SalesPrice__c = 85, kugo2p__LineDescription__c = 'Optional product'),
                    new kugo2p__SalesQuoteOptionalLine__c(kugo2p__SalesQuote__c = SalesQuote.Id, kugo2p__ProductService__c = apds[1].Id, kugo2p__ListPrice__c = 100, kugo2p__SalesPrice__c = 85, kugo2p__LineDescription__c = 'Optional service')
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
                Invoice = new kugo2p__KugamonInvoice__c(kugo2p__Account__c=account.Id, kugo2p__InvoiceDate__c=Date.today(), kugo2p__InvoiceDueDate__c=Date.today().addDays(-4));
                // insert invoice;
            }
            return Invoice;
        }
        private set;
    }

    public static list<kugo2p__KugamonInvoiceLine__c> InvoiceLines {
        get {
            if (InvoiceLines == null) {
                InvoiceLines = new list<kugo2p__KugamonInvoiceLine__c> {
                    new kugo2p__KugamonInvoiceLine__c(kugo2p__Invoice__c = Invoice.Id, kugo2p__SalesOrder__c = SalesOrder.Id, kugo2p__SalesOrderProductLine__c = OrderProductLines[0].Id,
                                        kugo2p__ProductService__c = apds[0].Id, kugo2p__UnitOfMeasure__c = apds[0].kugo2p__UnitOfMeasure__c, kugo2p__UnitOfTerm__c = apds[0].kugo2p__UnitOfTerm__c,
                                        kugo2p__CalculatedQuantity__c = 1, kugo2p__Quantity__c = 1, kugo2p__LineDescription__c = OrderProductLines[0].kugo2p__LineDescription__c),

                    new kugo2p__KugamonInvoiceLine__c(kugo2p__Invoice__c = Invoice.Id, kugo2p__SalesOrder__c = SalesOrder.Id, kugo2p__SalesOrderServiceLine__c = OrderServiceLines[0].Id,
                                        kugo2p__ProductService__c = apds[1].Id, kugo2p__UnitOfMeasure__c = apds[1].kugo2p__UnitOfMeasure__c, kugo2p__UnitOfTerm__c = apds[1].kugo2p__UnitOfTerm__c,
                                        kugo2p__CalculatedQuantity__c = 1, kugo2p__Quantity__c = 1, kugo2p__LineDescription__c = OrderServiceLines[0].kugo2p__LineDescription__c)
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
                InvoiceACCs = new list<kugo2p__KugamonInvoiceAdditionalChargeCredit__c> {
                    new kugo2p__KugamonInvoiceAdditionalChargeCredit__c(kugo2p__AdditionalChargeCredit__c = accs[0].Id, kugo2p__Invoice__c = Invoice.Id, kugo2p__Quantity__c = 1, kugo2p__LineDescription__c = 'Acc Desc 1'),
                    new kugo2p__KugamonInvoiceAdditionalChargeCredit__c(kugo2p__AdditionalChargeCredit__c = accs[1].Id, kugo2p__Invoice__c = Invoice.Id, kugo2p__Quantity__c = 2, kugo2p__LineDescription__c = 'Acc Desc 2')
                };
                insert InvoiceACCs;
            }
            return InvoiceACCs;
        }
        private set;
    }
    
    public static kugo2p__PaymentX__c Payment {
    	get {
    		if (Payment == null) {
		 		Payment = new kugo2p__PaymentX__c(Name = 'Test Payment', kugo2p__Amount__c = 125.00, kugo2p__Status__c = 'In Process',
										kugo2p__Payment_processor__c = 'Authorize.Net');
				insert Payment;
    		}
    		return Payment;
    	}
    	private set;
    }
}