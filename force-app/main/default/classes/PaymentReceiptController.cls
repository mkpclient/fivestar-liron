public class PaymentReceiptController {
    
    //public kugo2p__SalesOrder__c Order{ get; set; }
    
    //public list<kugo2p__PaymentX__c> OrderPayments { get; set; }
    public kugo2p__SalesOrder__c getSalesOrder()
    {     
        List<kugo2p__SalesOrder__c> resultsList = [select id,name,kugo2p__ContactBuying__c,kugo2p__ShipToName__c,kugo2p__ShipToStreetLong__c,kugo2p__ShipToCity__c,kugo2p__ShipToStateProvince__c,kugo2p__ShipToZipPostalCode__c,Shipping_Phone__c,
                                                   kugo2p__SalesOrder__c.kugo2p__ContactBilling__r.name, kugo2p__SalesOrder__c.kugo2p__ContactShipping__r.name,kugo2p__SalesOrder__c.kugo2p__ContactBuying__r.ACDF_Branch_Office__c, released__c, billing_email__c,kugo2p__billToStreetLong__c,kugo2p__billToCity__c,kugo2p__billToStateProvince__c,
                                                   kugo2p__billToZipPostalCode__c, kugo2p__ProductAmount__c, kugo2p__BalanceDueAmount__c, kugo2p__AppliedPaymentAmount__c, kugo2p__AdditionalChargeCreditAmount__c, kugo2p__NetAmount__c, kugo2p__SalesOrder__c.kugo2p__Opportunity__r.account_manager_name__c,
                                                   kugo2p__SalesOrder__c.kugo2p__Opportunity__r.account_manager_email__c, kugo2p__SalesOrder__c.kugo2p__Opportunity__r.FSP_Sales_Rep__r.phone, kugo2p__SalesOrder__c.Market__r.Market_Upload_Date__c  
                                                   from kugo2p__SalesOrder__c
                                                   where id = :ApexPages.currentPage().getParameters().get('orderId')
                                                   //where id = :'a1O0W000005TFjrUAG'
                                                  ];

        return resultsList.isEmpty() == false ? resultsList.get(0) : null;
    }
    
    public list<kugo2p__PaymentX__c> getOrderPayments()
    {
        /*kugo2p__SalesOrder__c  SalesOrder = [select id, name, (select id, name, kugo2p__Amount__c, kugo2p__Card_Type__c, kugo2p__Last_4_Digits__c, kugo2p__Date__c, kugo2p__Status__c from kugo2p__Payments__r)
        FROM kugo2p__SalesOrder__c
        where id = :ApexPages.currentPage().getParameters().get('id')];*/
        String paymentId = ApexPages.currentPage().getParameters().get('paymentId');
        //String paymentId = 'a1F0W000006bAaxUAE';
        
        list<kugo2p__PaymentX__c> OrderPayments = [select id, name, kugo2p__Amount__c, kugo2p__Card_Type__c, kugo2p__Last_4_Digits__c, kugo2p__Date__c, kugo2p__Status__c,
                                                          kugo2p__Authorization_Id__c, kugo2p__Transaction_Id__c, kugo2p__Transaction_Type__c
                                                   from kugo2p__PaymentX__c 
                                                   Where Id = :paymentId];
        OrderPayments.sort();
        return OrderPayments;
    }

}