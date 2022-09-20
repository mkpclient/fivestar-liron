public with sharing class missedAddonsHelper {
  public class MissedAddonResource {
    @AuraEnabled
    public List<SalesOrder__c> salesorders { get; set; }
    @AuraEnabled
    public Subscription__c subscription { get; set; }
  }

  @AuraEnabled(cacheable=true)
  public static List<MissedAddonResource> retrieveMissingAddons() {
    try {
      Map<Id, Subscription__c> subs = new Map<Id, Subscription__c>(
        [
          SELECT
            Id,
            Renewal_Product__c,
            (
              SELECT Id, Parent_Subscription__c, Renewal_Product__c, Name, Parent_Subscription__r.Name
              FROM Subscriptions__r
              WHERE Status__c = 'Active'
            )
          FROM Subscription__c
          WHERE status__c = 'Active'
        ]
      );

      List<MissedAddonResource> retVal = new List<MissedAddonResource>();
      List<SalesOrder__c> orders = [
        SELECT
          Id,
          Subscription__c,
          Name,
          Status_Picklist__c,
          (SELECT id, product__c FROM Sales_Order_Product_Lines__r)
        FROM salesorder__c
        WHERE subscription__c IN :subs.keySet()
      ];

      for (SalesOrder__c o : orders) {
        Subscription__c s = subs.get(o.Subscription__c);
        List<SalesOrderProductLine__c> sopls = o.Sales_Order_Product_Lines__r;
        List<Id> prodIds = new List<Id>();
        List<Subscription__c> addons = s.Subscriptions__r;
        for (SalesOrderProductLine__c pl : sopls) {
          prodIds.add(pl.Product__c);
        }
        List<SalesOrder__c> relatedSos = new List<SalesOrder__c>();
        MissedAddonResource m = new MissedAddonResource();
        for (Subscription__c ao : addons) {
          if (!prodIds.contains(ao.Renewal_Product__c)) {
            relatedSos.add(o);
          } else {
            prodIds.remove(prodIds.indexOf(ao.Renewal_Product__c));
          }
          m.subscription = ao;
        }
        m.salesorders = relatedSos;
        if(m.subscription != null) {
          retVal.add(m);
        }
      }
        return retVal;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}