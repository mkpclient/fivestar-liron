public without sharing class missedAddonsHelper {
  public class MissedAddonResource {
    @AuraEnabled
    public List<SalesOrder__c> salesorders { get; set; }
    @AuraEnabled
    public Subscription__c subscription { get; set; }
  }

  @AuraEnabled
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

      Map<Subscription__c, List<SalesOrder__c>> orderMap = new Map<Subscription__c, List<SalesOrder__c>>();

      for (SalesOrder__c o : orders) {
        Subscription__c s = subs.get(o.Subscription__c);
        List<SalesOrderProductLine__c> sopls = o.Sales_Order_Product_Lines__r;
        List<Id> prodIds = new List<Id>();
        List<Subscription__c> addons = s.Subscriptions__r;
        for (SalesOrderProductLine__c pl : sopls) {
          prodIds.add(pl.Product__c);
        }
        for (Subscription__c ao : addons) {
          List<SalesOrder__c> aos = orderMap.containsKey(ao) ? orderMap.get(ao) : new List<SalesOrder__c>();
          if (!prodIds.contains(ao.Renewal_Product__c)) {
            aos.add(o);
            orderMap.put(ao, aos);
          } else {
            prodIds.remove(prodIds.indexOf(ao.Renewal_Product__c));
          }
        }
      }
      for(Subscription__c s : orderMap.keySet()) {
        MissedAddonResource m = new MissedAddonResource();
        m.subscription = s;
        m.salesorders = orderMap.get(s);
        retVal.add(m);
      }
      return retVal;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
