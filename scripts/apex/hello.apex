List<SalesOrderProductLine__c> sopls = [SELECT Id, SalesOrder__c, SalesOrder__r.Status_Picklist__c FROM SalesOrderProductLine__c WHERE CreatedDate > 2022-01-02T14:04:00Z AND SalesOrder__r.FulfillOrder__c = true AND Product__r.CreateOrderFulfillment__c = TRUE AND Quantity__c >0 AND SalesOrder__r.Status_Picklist__c = 'Released' AND Id NOT IN (SELECT Boom_Order_Product_Line__c
          FROM Fulfillment__c WHERE CreatedDate > 2022-01-02T14:04:00Z AND Boom_Order__r.FulfillOrder__c = true)];

Map<Id, SalesOrder__c> soMap = new Map<Id, SalesOrder__c>();

for(SalesOrderProductLine__c pl : sopls) {
  SalesOrder__c salesOrder = new SalesOrder__c();
  if(!soMap.containsKey(pl.SalesOrder__c)) {
    salesOrder.Id = pl.SalesOrder__c;
    salesOrder.Status_Picklist__c = 'Unreleased';
    soMap.put(pl.SalesOrder__c, salesOrder);
  }
}

update soMap.values();

for(SalesOrder__c so : soMap.values()) {
  so.Status_Picklist__c = 'Released';
  soMap.put(so.Id, so);
}

update soMap.values();

/** 
 * 
for i in {1..10}
do
sfdx force:apex:execute --loglevel ERROR --apexcodefile '/Volumes/LaCie/Salesforce/FIVESTAR GITTED/FIVESTAR/scripts/apex/hello.apex'
done
echo "completed"

 */