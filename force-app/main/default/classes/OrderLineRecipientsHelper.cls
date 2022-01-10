public without sharing class OrderLineRecipientsHelper {
  public static void beforeInsert(List<Order_Line_Recipient__c> newRecipients) {
    Set<Id> salesOrderIds = new Set<Id>();
    for (Order_Line_Recipient__c r : newRecipients) {
      if (String.isEmpty(r.Legacy_Id__c)) {
        salesOrderIds.add(r.Order__c);
      }
    }

    Map<Id, SalesOrder__c> parentSalesOrders = generateSalesOrders(
      salesOrderIds
    );

    for (Order_Line_Recipient__c r : newRecipients) {
      if (String.isEmpty(r.Legacy_Id__c)) {
        if (r.Market__c == null) {
          r.Market__c = parentSalesOrders.get(r.Order__c).Market__c;
        }

        if (r.AccountManager__c == null) {
          r.AccountManager__c = parentSalesOrders.get(r.Order__c)
            .Opportunity__r.OwnerId;
        }
      }
    }
  }

  public static void afterInsert(List<Order_Line_Recipient__c> newRecipients) {
    Set<Id> orderLineIds = new Set<Id>();
    Map<Id, List<Order_Line_Recipient__c>> addToChildren = new Map<Id, List<Order_Line_Recipient__c>>();
    List<Id> referenceIds = new List<Id>();
    for (Order_Line_Recipient__c r : newRecipients) {
      if(String.isEmpty(r.Legacy_Id__c)) {
        orderLineIds.add(r.OrderProductLine__c);
        if (r.Is_Kit_Bundle__c == true) {
          referenceIds.add(r.Id);
          if (addToChildren.containsKey(r.OrderProductLine__c)) {
            List<Order_Line_Recipient__c> recips = addToChildren.get(
              r.OrderProductLine__c
            );
            recips.add(r);
            addToChildren.put(r.OrderProductLine__c, recips);
          } else {
            addToChildren.put(
              r.OrderProductLine__c,
              new List<Order_Line_Recipient__c>{ r }
            );
          }
        }
      }
      
    }

    if(orderLineIds.size() > 0){ 
      updateParentOrderLine(orderLineIds);
    }


    if (addToChildren.size() > 0) {
      updateChildrenRecipients(addToChildren, referenceIds, false);
    }
  }

  public static void afterUpdate(
    Map<Id, Order_Line_Recipient__c> oldRecipients,
    Map<Id, Order_Line_Recipient__c> newRecipients
  ) {
    Set<Id> orderLineIds = new Set<Id>();

    for (Id key : newRecipients.keySet()) {
      if (
        oldRecipients.get(key).OrderProductLine__c !=
        newRecipients.get(key).OrderProductLine__c &&
        String.isEmpty(newRecipients.get(key).Legacy_Id__c)
      ) {
        orderLineIds.add(oldRecipients.get(key).OrderProductLine__c);
        orderLineIds.add(newRecipients.get(key).OrderProductLine__c);
      }
    }

    if(orderLineIds.size() > 0){ 
      updateParentOrderLine(orderLineIds);
    }
  }

  public static void afterDelete(List<Order_Line_Recipient__c> oldList) {
    Set<Id> orderLineIds = new Set<Id>();
    Map<Id, List<Order_Line_Recipient__c>> deleteChildren = new Map<Id, List<Order_Line_Recipient__c>>();
    List<Id> referenceIds = new List<Id>();

    for (Order_Line_Recipient__c ol : oldList) {

      if(String.isEmpty(ol.Legacy_Id__c)) {
        orderLineIds.add(ol.OrderProductLine__c);
        if (ol.Is_Kit_Bundle__c == true) {
          referenceIds.add(ol.Recipient__c);
          if (deleteChildren.containsKey(ol.OrderProductLine__c)) {
            List<Order_Line_Recipient__c> recips = deleteChildren.get(
              ol.OrderProductLine__c
            );
            recips.add(ol);
            deleteChildren.put(ol.OrderProductLine__c, recips);
          } else {
            deleteChildren.put(
              ol.OrderProductLine__c,
              new List<Order_Line_Recipient__c>{ ol }
            );
          }
        }
      }
      
    }

    if(orderLineIds.size() > 0) {
      updateParentOrderLine(orderLineIds);
    }

    if (deleteChildren.size() > 0) {
      updateChildrenRecipients(deleteChildren, referenceIds, true);
    }
  }

  public static Map<Id, SalesOrder__c> generateSalesOrders(
    Set<Id> salesOrderIds
  ) {
    Map<Id, SalesOrder__c> salesOrders = new Map<Id, SalesOrder__c>(
      [
        SELECT Id, Account__r.OwnerId, Market__c, Opportunity__r.OwnerId
        FROM SalesOrder__c
        WHERE Id IN :salesOrderIds
      ]
    );

    return salesOrders;
  }

  public static Map<Id, Contact> generateOppToContactMap() {
    Map<Id, Contact> returnedMap = new Map<Id, Contact>();

    return returnedMap;
  }

  public static void updateParentOrderLine(Set<Id> orderLineIds) {
   
  List<SalesOrderProductLine__c> SOPLs = [
      SELECT Id, Recipient_Count__c, (SELECT Id FROM Order_Line_Recipients__r WHERE OrderProductLine__c != null)
      FROM SalesOrderProductLine__c
      WHERE Id IN :orderLineIds
      AND Legacy_Id__c = null
    ];

    for (SalesOrderProductLine__c sopl : SOPLs) {
      if(sopl.Order_Line_Recipients__r != null && sopl.Order_Line_Recipients__r.size() > 0) {
        sopl.Recipient_Count__c = sopl.Order_Line_Recipients__r.size();
      } else {
        sopl.Recipient_Count__c = 0;
      }
    }

    try {
      Database.update(SOPLs, false);
    } catch (DmlException err) {
      System.debug('RECIPIENT COUNT UPDATE ERROR :::' + err.getMessage());
    }
  }

  public static void updateChildrenRecipients(
    Map<Id, List<Order_Line_Recipient__c>> parentMap,
    List<Id> referenceIds,
    Boolean isDelete
  ) {
    if (isDelete) {
      List<Order_Line_Recipient__c> olrForDeletion = [
        SELECT Id, OrderProductLine__r.KitBundleLine__c
        FROM Order_Line_Recipient__c
        WHERE
          OrderProductLine__r.KitBundleLine__c IN :parentMap.keySet()
          AND Recipient__c IN :referenceIds
      ];

      if (olrForDeletion.size() > 0) {
        delete olrForDeletion;
      }

      return;
    }

    List<SalesOrderProductLine__c> childrenRecords = [
      SELECT Id, KitBundleLine__c
      FROM SalesOrderProductLine__c
      WHERE KitBundleLine__c IN :parentMap.keySet()
    ];

    List<Order_Line_Recipient__c> newRecipients = new List<Order_Line_Recipient__c>();

    for (SalesOrderProductLine__c c : childrenRecords) {
      List<Order_Line_Recipient__c> olr = parentMap.get(c.KitBundleLine__c);

      for (Order_Line_Recipient__c o : olr) {
        Order_Line_Recipient__c newRecipient = o.clone(
          false,
          true,
          false,
          false
        );
        newRecipient.OrderProductLine__c = c.Id;
        newRecipients.add(newRecipient);
      }
    }

    insert newRecipients;
  }
}