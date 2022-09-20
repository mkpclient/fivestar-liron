import { LightningElement } from 'lwc';

export default class MissedAddons extends LightningElement {}



/* 
    Label: Parent Sub ID / apiName: Subcription__c.Parent_Subscription__c

    Label: Parent Sub Name / apiName: Subcription__c.Parent_Subscription__r.Name

    Label: Addon Sub ID / apiName: Subscription__c.Id

    Label: Addon Sub Name / apiName: Subscription__c.Name

    Label: Boom Order / apiName: SalesOrder__c.Id;

*/

/* 
Map<Id, Subscription__c> subs = new Map<Id, Subscription__c>([
    SELECT Id, Renewal_Product__c,
    (SELECT Id, Parent_Subscription__c, Renewal_Product__c FROM Subscriptions__r WHERE Status__c= 'Active')
    FROM Subscription__c WHERE status__c = 'Active'
]);

Map<Id, List<SalesOrder__c>> missingSubAddonsMap = new Map<Id, List<SalesOrder__c>>();
List<Subscription__c> missingSubAddonsList = new List<Subscription__c>();
List<SalesOrder__c> orders = [
    SELECT Id, Subscription__C,
    (select id, product__c from Sales_Order_Product_Lines__r)
    from salesorder__c where subscription__c in :subs.keySet()
];

for(SalesOrder__c o : orders){
    Subscription__c s = subs.get(o.Subscription__c);
    List<SalesOrderProductLine__c> sopls = o.Sales_Order_Product_Lines__r;
    List<Id> prodIds = new List<Id>();
    List<Subscription__c> addons = s.Subscriptions__r;
    for(SalesOrderProductLine__c pl : sopls) {
        prodIds.add(pl.Product__c);
    }
    for(Subscription__c ao :addons) {
        List<SalesOrder__c> relatedSos = missingSubAddonsMap.containsKey(ao) ? missingSubAddonsMap.get(ao) : new List<SalesOrder__c>();
        if(!prodIds.contains(ao.Renewal_Product__c)) {
            relatedSos.add(o);
            missingSubAddonsMap.put(ao.Id, relatedSos);
            missingSubAddonsList.add(ao);
        } else {
            prodIds.remove(prodIds.indexOf(ao));
        }
    }
}

system.debug(missingSubAddons);

*/