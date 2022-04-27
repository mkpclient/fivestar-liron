String SCHEDULED_SUBSCRIPTION = 'Subscription Copies';
Map<Id,Fulfillment__c> ffMap = new Map<Id,Fulfillment__c>([
    SELECT Id,Boom_Order_Product_Line__c,Boom_Order__c,Status__c,Gross_Price__c,Quantity__c,Subscription_Product__c
    FROM Fulfillment__c
    WHERE Boom_Order_Product_Line__r.Product__r.Is_Subscription_Addon__c = true
    AND Status__c NOT IN ('Closed','Closed No Response', 'Cancelled', 'Subscription Cancelled')
    AND Id NOT IN (
        SELECT Subscription_Fulfillment__c FROM Subscription__c
    )
    AND Boom_Order__c IN (SELECT Original_Subscription_Boom_Order__c FROM Subscription__c)
    FOR UPDATE
]);

Map<Id,Fulfillment__c> ffMapAnnuals = new Map<Id,Fulfillment__c>([
    SELECT Id
    FROM Fulfillment__c
    WHERE Id IN :ffMap.keySet()
    AND Boom_Order__c IN (SELECT SalesOrder__c FROM SalesOrderProductLine__c WHERE Product__r.Name LIKE '%Annual%')
]);

Set<String> subIds = new Set<String>();
System.debug(ffMapAnnuals.size());
for(Fulfillment__c f : ffMap.values()) {
    if(ffMapAnnuals.containsKey(f.Id)) {
        ffMap.remove(f.Id);
        continue;
    }
    if(String.isNotBlank(f.Subscription_Product__c)) {
        subIds.add(f.Subscription_Product__c);
    }
}

Map<Id, SalesOrderProductLine__c> prodLines = new Map<id,SalesOrderProductLine__c>([
    select id from SalesOrderProductLine__c where id in (
        select Boom_Order_Product_Line__c from fulfillment__c where id in :ffMap.keySet()
    )
]);


System.debug(ffMap.size());

BoomFulfillmentHelper.createSubscriptions(ffMap, prodLines.keySet(), subIds);



/** 
 * 
for i in {1..2}
do
sfdx force:apex:execute --loglevel ERROR --apexcodefile '/Users/lirondecastro/Salesforce/FIVESTAR GITTED/FIVESTAR/scripts/apex/hello.apex'
done
echo "completed"

 */