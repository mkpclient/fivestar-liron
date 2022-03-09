public without sharing class SubscriptionHelper {
    public static final String SO_FIELDS = 'OrderDate__c,OrderName__c,Market__c,Opportunity__c,Account__c,Price_Book__c,ContactBilling__c,ContactBuying__c,ContactShipping__c,BillToName__c,BillToCity__c,BillToCountry__c,BillToStateProvince__c,BillToStreetLong__c,BillToZipPostalCode__c,ShipToCity__c,ShipToCountry__c,ShipToName__c,ShipToStateProvince__c,ShipToStreetLong__c,ShipToZipPostalCode__c';
    public static void afterInsert(Map<Id, Subscription__c> newMap) {
        createSubscriptionOrders(newMap.values());
    }

    public static void createSubscriptionOrders(List<Subscription__c> subscriptions) {
        String queryString = 'SELECT ' + SO_FIELDS + ' FROM SalesOrder__c WHERE Id IN (SELECT Original_Subscription_Boom_Order__c FROM Subscription__c WHERE Id IN :subscriptions)';
        Map<Id, SalesOrder__c> salesOrderMap = new Map<Id, SalesOrder__c>((List<SalesOrder__c>) Database.query(queryString));
        Map<Id, SalesOrder__c> newSalesOrders = new Map<Id, SalesOrder__c>();
        Map<Id, SalesOrderProductLine__c> newSalesOrderProductLines = new Map<Id, SalesOrderProductLine__c>();
        Map<Id, Order_Line_Recipient__c> newOrderLineRecipients = new Map<Id, Order_Line_Recipient__c>();

        for(Subscription__c sub : subscriptions) {
            Integer day = Integer.valueOf(sub.Renewal_Date_Day_of_Month__c);
            Integer month = System.today().month() + 1;
            Integer year = System.today().year();
            if(sub.Renewal_Frequency__c == 'Annual') {
                month = System.today().month();
                year = System.today().year() + 1;
            }
            Date orderDate = date.newInstance(year, month, day);
            SalesOrder__c newSo = generateSubscriptionOrder(salesOrderMap.get(sub.Original_Subscription_Boom_Order__c), sub, orderDate);
            SalesOrderProductLine__c sopl = generateSubscriptionProductLine(sub,orderDate,newSo);
            Order_Line_Recipient__c recipient = generateSubscriptionLineRecipient(sub, newSo);
            newSalesOrders.put(sub.Id, newSo);
            newSalesOrderProductLines.put(sub.Id, sopl);
            newOrderLineRecipients.put(sub.Id, recipient);
        }

        insert newSalesOrders.values();

        for(Id subId : newSalesOrders.keySet()) {
            SalesOrder__c so = newSalesOrders.get(subId);
            SalesOrderProductLine__c sopl = newSalesOrderProductLines.get(subId);
            Order_Line_Recipient__c olr = newOrderLineRecipients.get(subId);
            sopl.SalesOrder__c = so.Id;
            newSalesOrderProductLines.put(subId, sopl);
            newOrderLineRecipients.put(subId, olr);
        }

        insert newSalesOrderProductLines.values();

        List<Order_Line_Recipient__c> recipients = [
            SELECT Id, Order__r.Subscription__c FROM Order_Line_Recipient__c WHERE Order__r.Subscription__c IN :subscriptions
        ];

        for(Order_Line_Recipient__c r : recipients) {
            String key = r.Order__r.Subscription__c;
            Order_Line_Recipient__c olr = newOrderLineRecipients.get(key);
            olr.Id = r.Id;
            newOrderLineRecipients.put(key, olr);
        }

        update newOrderLineRecipients.values();
    }

    public static SalesOrder__c generateSubscriptionOrder(SalesOrder__c so, Subscription__c sub, Date orderDate) {
        SalesOrder__c newSo = so.clone(false, true, false, false);
        newSo.Id = null;
        newSo.Subscription__c = sub.Id;
        newSo.OrderDate__c = orderDate;
        newSo.Status_Picklist__c = 'Pending Renewal';
        return newSo;
    }

    public static SalesOrderProductLine__c generateSubscriptionProductLine(Subscription__c sub, Date orderDate, SalesOrder__c so) {
        SalesOrderProductLine__c sopl = new SalesOrderProductLine__c();
        sopl.Quantity__c = sub.Renewal_Quantity__c;
        sopl.SalesPrice__c = sub.Renewal_Price__c;
        sopl.ListPrice__c = sub.Renewal_Price__c;
        sopl.DateRequired__c = orderDate;
        sopl.Product__c = sub.Renewal_Product__c;
        sopl.ContactShipping__c = so.ContactShipping__c;
        sopl.DateAvailableToPromise__c = orderDate;
        return sopl;
    }

    public static Order_Line_Recipient__c generateSubscriptionLineRecipient(Subscription__c sub, SalesOrder__c so) {
        Order_Line_Recipient__c olr = new Order_Line_Recipient__c();
        olr.AccountManager__c = sub.Account_Manager__c;
        olr.Market__c = so.Market__c;
        olr.Primary__c = true;
        olr.Recipient__c = sub.Contact__c;
        return olr;
    }
    
}