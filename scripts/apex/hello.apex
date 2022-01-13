List<Fulfillment__c> fulfillments = [SELECT Id, Boom_Order_Product_Line__c FROM Fulfillment__c WHERE ParentFulfillment__c = null AND Boom_Order_Product_Line__c IN (SELECT OrderProductLine__c FROM Order_Line_Recipient__c WHERE Order__r.FulfillOrder__c = true AND Fulfillment__c = null AND CreatedDate > 2022-01-02T14:04:00Z) LIMIT 200];

Map<Id, Id> prodLineFulfillmentMap = new Map<Id, Id>();

for(Fulfillment__c f : fulfillments) {
    prodLineFulfillmentMap.put(f.Boom_Order_Product_Line__c, f.Id);
}

List<Order_Line_Recipient__c> olrs = [SELECT Id, OrderProductLine__c FROM Order_Line_Recipient__c WHERE OrderProductLine__c IN :prodLineFulfillmentMap.keySet() AND Fulfillment__c = null AND CreatedDate > 2022-01-02T14:04:00Z LIMIT 200];

for(Order_Line_Recipient__c olr : olrs) {
    olr.Fulfillment__c = prodLineFulfillmentMap.get(olr.OrderProductLine__c);
}


update olrs;

/** 
 * 
for i in {1..7}
do
sfdx force:apex:execute --loglevel ERROR --apexcodefile '/Volumes/LaCie/Salesforce/FIVESTAR GITTED/FIVESTAR/scripts/apex/hello.apex'
done
echo "completed"

 */