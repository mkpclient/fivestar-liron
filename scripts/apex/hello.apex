String SCHEDULED_SUBSCRIPTION = 'Subscription Copies';
Map<Id,Fulfillment__c> ffMap = new Map<Id,Fulfillment__c>([
    SELECT Id,Boom_Order_Product_Line__c,Boom_Order__c,Status__c,Gross_Price__c,Quantity__c
    FROM Fulfillment__c
    WHERE Boom_Order_Product_Line__r.Product__r.Is_Subscription_Addon__c = true
    AND Status__c NOT IN ('Closed','Closed No Response', 'Cancelled', 'Subscription Cancelled')
    AND Id NOT IN (
        SELECT Subscription_Fulfillment__c FROM Subscription__c
    )
    LIMIT 1
    FOR UPDATE
]);

Map<Id, SalesOrderProductLine__c> prodLines = new Map<id,SalesOrderProductLine__c>([
    select id from SalesOrderProductLine__c where id in (
        select Boom_Order_Product_Line__c from fulfillment__c where id in :ffMap.keySet()
    )
]);

Map<Id,Subscription__c> soMap = new Map<Id,Subscription__c>();

List<Subscription__c> subs = [
    SELECT Id, Original_Subscription_Boom_Order__c
    FROM Subscription__c
    WHERE Original_Subscription_Boom_Order__c IN (SELECT Boom_Order__c FROM Fulfillment__c WHERE Id IN :ffMap.keySet())
];

for(Subscription__c s : subs) {
    soMap.put(s.Original_Subscription_Boom_Order__c, s);
}

Set<Id> prodLineIds = prodLines.keySet();

Map<Id, SalesOrderProductLine__c> prodLineMap = new Map<Id, SalesOrderProductLine__c>([
            SELECT Id,Name,SalesOrder__r.Release_Date__c, SalesOrder__r.Subscription__c,SalesOrder__r.Subscription__r.Name,SalesOrder__r.Subscription__r.Original_Subscription_Boom_Order__c,Product__c,Product__r.Renewal_Product__c,Product__r.Renewal_Frequency__c,
            SalesOrder__r.ContactBilling__c,SalesOrder__r.Name,Product__r.Base_Product__c,Product__r.Is_Subscription_Addon__c,
            (SELECT Id, AccountManager__c,Recipient__c FROM Order_Line_Recipients__r WHERE Primary__c = true LIMIT 1)
            FROM SalesOrderProductLine__c
            WHERE Id IN :prodLineIds
        ]);



        Map<Id, Id> paymentMethodMap = BoomFulfillmentHelper.generatePaymentMethodMap(ffMap);

        List<Subscription__c> newSubscriptions = new List<Subscription__c>();
        Integer dayOfMonth = (System.today()).day();

        for(Fulfillment__c ff : ffMap.values()) {
            SalesOrderProductLine__c prodLine = prodLineMap.get(ff.Boom_Order_Product_Line__c);

            if(prodLine != null && prodLine.Order_Line_Recipients__r.size() > 0) {
                Boolean hasSpecialSchedule = prodLine.Product__r.Base_Product__c == SCHEDULED_SUBSCRIPTION;

                // add logic to determine if the subscription is a special schedule
        
                if(hasSpecialSchedule && Order_Renewal_Schedule__mdt.getInstance('Universal_Renewal_date') != null) {
                    dayOfMonth = Integer.valueOf(Order_Renewal_Schedule__mdt.getInstance('Universal_Renewal_date').Renewal_Date__c);
                }
                
                Subscription__c sub = new Subscription__c();
                
                String subName = prodLine.SalesOrder__r.Name.replace('SO', 'SUB');

                if(prodLine.Product__r.Is_Subscription_Addon__c == true) {
                    subName = subName + '-ADDON-' + prodLine.Name;
                } 

                if(prodLine.SalesOrder__r.Subscription__c != null) {
                    sub.Original_Subscription_Boom_Order__c = prodLine.SalesOrder__r.Subscription__r.Original_Subscription_Boom_Order__c;
                    subName = prodLine.SalesOrder__r.Subscription__r.Name + '-ADDON-' + prodLine.Name;
                    sub.Parent_Subscription__c = prodLine.SalesOrder__r.Subscription__c;
                } else if (soMap.containsKey(ff.Boom_Order__c)) {
                    sub.Original_Subscription_Boom_Order__c = ff.Boom_Order__c;        
                    sub.Parent_Subscription__c = soMap.get(ff.Boom_Order__c).Id;
                } 
                else {
                    sub.Original_Subscription_Boom_Order__c = ff.Boom_Order__c;
                }

                switch on ff.Status__c {
                    when 'On Hold', 'Subscription Paused' {
                        sub.Status__c = 'Paused';
                    }
                    when else {
                        sub.Status__c = 'Active';
                    }
                }

                sub.Name = subName;
                sub.Account_Manager__c = prodLine.Order_Line_Recipients__r[0].AccountManager__c;
                sub.Contact__c = prodLine.Order_Line_Recipients__r[0].Recipient__c;

                sub.Payment_Method__c = paymentMethodMap.get(ff.Boom_Order__c);
                sub.Renewal_Date_Day_of_Month__c = '' + dayOfMonth;
                sub.Renewal_Frequency__c = prodLine.Product__r.Renewal_Frequency__c;
                sub.Renewal_Price__c = ff.Gross_Price__c;
                sub.Renewal_Product__c = prodLine.Product__r.Renewal_Product__c;
                sub.Renewal_Quantity__c = ff.Quantity__c;
                sub.Start_Date__c = prodLine.SalesOrder__r.Release_Date__c;
                sub.Subscription_Fulfillment__c = ff.Id;
                newSubscriptions.add(sub);
            }
        }

        if(newSubscriptions.size() > 0) {
            // insert newSubscriptions;
            // System.enqueueJob(new BoomSubscriptionsQueuable(newSubscriptions, true, false));
            insert newSubscriptions;
        }
// BoomFulfillmentHelper.createSubscriptions(fMap, prodLines.keySet());



/** 
 * 
for i in {1..2}
do
sfdx force:apex:execute --loglevel ERROR --apexcodefile '/Users/lirondecastro/Salesforce/FIVESTAR GITTED/FIVESTAR/scripts/apex/hello.apex'
done
echo "completed"

 */