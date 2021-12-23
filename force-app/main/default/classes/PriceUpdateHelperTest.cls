@isTest(seeAllData = true)
public class PriceUpdateHelperTest {
    public static testmethod void updatePriceTest(){
        kugo2p__SalesOrder__c salesOrder = new kugo2p__SalesOrder__c();
        kugo2p__SalesOrderProductLine__c prodLine = [Select id,kugo2p__SalesPrice__c,kugo2p__AppliedPaymentAmount__c, kugo2p__SalesOrder__c
                                                                  from kugo2p__SalesOrderProductLine__c limit 1];
        salesOrder.id = prodLine.kugo2p__SalesOrder__c;
        salesOrder.Payment_Status__c = 'Completed';
        upsert salesOrder;
        PriceUpdateHelper.updatePrice(new List<kugo2p__SalesOrder__c>{salesOrder});
        kugo2p__PaymentX__c payObj = [Select id,kugo2p__Status__c,kugo2p__SalesOrder__c
                                                                  from kugo2p__PaymentX__c limit 1];
        payObj.kugo2p__Status__c = 'Completed';
        payObj.kugo2p__SalesOrder__c = salesOrder.id;
        Test.StartTest();
        try{
        upsert payObj;
        }catch(exception e){system.debug('error');}
        Account account = new Account(Name = 'Test Account',Type = 'Customer - Direct',BillingStreet = '3545 Ave',BillingState = 'California',
                                              BillingPostalCode = '95050',BillingCountry = 'United States',ShippingStreet = '525 Ave',ShippingCity = 'San Jose',
                                              ShippingState = 'California',ShippingPostalCode = '95050',ShippingCountry = 'United States',Phone = '(336) 222-7000',
                                              Fax ='(336) 222-8000',AccountNumber = 'Test ANo',Website = 'www.kkk.com',Industry = 'Apparel',
                                              AnnualRevenue = 350000000,NumberOfEmployees = 9000,Ownership = 'Public',TickerSymbol = 'BTXT',
                                              Description = 'Test Account',Site = '');
        insert account;
        Contact contact = new Contact(AccountId=account.Id, FirstName='Will', LastName='Smith', Phone='333-333-3333', MailingStreet='1 Kugamon Street', MailingState='California', MailingCity='SF', MailingPostalCode='95050', MailingCountry='United States');
                insert contact;
        Pricebook2 StandardPriceBook = [Select p.Name, p.IsActive, p.Id, p.Description From Pricebook2 p Where isStandard=true];
        OpportunityStage stage = [Select MasterLabel From OpportunityStage Where isActive=true Limit 1];
                System.debug('\n ### Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
                opportunity opp = new Opportunity(Name = 'Test Opp', AccountId = account.Id, StageName = stage.MasterLabel, CloseDate = System.today().addDays(-15), PriceBook2Id = StandardPriceBook.Id, Market_Project__c=ManageLinesTests.market.Id, Next_call_date__c=system.today());
                insert opp;
        kugo2p__SalesOrder__c SalesOrder2 = new kugo2p__SalesOrder__c(kugo2p__Account__c = account.Id, kugo2p__Opportunity__c = opp.Id, kugo2p__OrderDate__c = system.today(),
                                                kugo2p__PriceBookName__c = StandardPriceBook.Name, kugo2p__DiscountPercent__c=null, kugo2p__PaymentMethod__c='Invoice',
                                                kugo2p__ContactShipping__c=contact.Id, kugo2p__ContactBuying__c=contact.Id, //kugo2p__ContactBilling__c=contact.Id, 
                                                                                                        kugo2p__RecordStatus__c='Draft', kugo2p__PrintSpecificTextandTerms__c = true);
        
        try{
        insert SalesOrder2;
        }catch(exception e){}
         OrderInvoiceWithAttachment.sendEmailWithAttachment(new List<ID>{SalesOrder.Id});
        Test.StopTest();
    }
    
}