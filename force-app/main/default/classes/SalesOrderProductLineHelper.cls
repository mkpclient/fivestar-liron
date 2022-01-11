public without sharing class SalesOrderProductLineHelper {

  /**
   * *************************************************************************
   * * uncomment everything below if I leave anything out *
   * *************************************************************************
   */

  public static void beforeInsert(List<SalesOrderProductLine__c> newObjs) {
    for (SalesOrderProductLine__c sopl : newObjs) {

      if (sopl.Kit_Bundle_Product__c == true) {
        sopl.KitBundle__c = true;
      }

      if (sopl.DateRequired__c == null) {
        sopl.DateRequired__c = System.today();
      }
      
    }

    System.debug('BEFORE INSERT');
  }

  public static void afterInsert(Map<Id, SalesOrderProductLine__c> newLines) {
    Map<Id, SalesOrderProductLine__c> parentLines = new Map<Id, SalesOrderProductLine__c>();
    List<SalesOrderProductLine__c> nonBundles = new List<SalesOrderProductLine__c>();
    Set<Id> orderIds = new Set<Id>();
    List<SalesOrderProductLine__c> taxableLines = new List<SalesOrderProductLine__c>();
    Set<Id> sampleOrders = new Set<Id>();
    Set<Id> desampleOrders = new Set<Id>();

    for (SalesOrderProductLine__c sopl : newLines.values()) {

      if (
        String.isNotEmpty(sopl.ShipToStateProvince__c) &&
        Sales_Tax__mdt.getInstance(sopl.ShipToStateProvince__c) != null
      ) {
        SalesOrderProductLine__c taxSopl = new SalesOrderProductLine__c();
        taxSopl.Id = sopl.Id;
        taxSopl.State_Tax_Rate__c = Sales_Tax__mdt.getInstance(
            sopl.ShipToStateProvince__c
          )
          .Rate__c;
        taxableLines.add(taxSopl);
      }

      if(sopl.Sample_Product__c == true) {
        sampleOrders.add(sopl.SalesOrder__c);
      }

      if(sopl.Sample_Parent_Order__c == true && sopl.Sample_Product__c != true && sopl.ListPrice__c != 0) {
        desampleOrders.add(sopl.SalesOrder__c);
      }

      if (sopl.Kit_Bundle_Product__c == true) {
        parentLines.put(sopl.Id, sopl);
      } else if (sopl.Kit_Bundle_Member__c != true) {
        nonBundles.add(sopl);
      }
      if (sopl.DiscountAmount__c != null && sopl.DiscountAmount__c > 0) {
        orderIds.add(sopl.SalesOrder__c);
      }
      
    }

    if (parentLines.size() > 0) {
      generateBundleMembers(parentLines);
    }

    if (nonBundles.size() > 0) {
      generateInitialRecipients(nonBundles);
    }

    if (taxableLines.size() > 0) {
      update taxableLines;
    }

    if(sampleOrders.size() > 0) {
      updateSampleOrders(sampleOrders);
    }

    if(desampleOrders.size() > 0) {
      unsetSampleOrders(desampleOrders);
    }
  }

  public static void beforeUpdate(
    List<SalesOrderProductLine__c> oldList,
    List<SalesOrderProductLine__c> newList
  ) {
    for (Integer i = 0; i < newList.size(); i++) {
      if (newList[i].TaxAmount__c != newList[i].Tax_Amount_Hidden__c) {
        newList[i].Tax_Amount_Hidden__c = newList[i].TaxAmount__c;
      }

      if(newList[i].Kit_Bundle_Product__c == true && newList[i].KitBundle__c != true) {
        newList[i].KitBundle__c = true;
      }
    }

    System.debug('BEFORE UPDATE');
  }

  public static void afterUpdate(
    List<SalesOrderProductLine__c> oldList,
    List<SalesOrderProductLine__c> newList
  ) {
    List<SalesOrderProductLine__c> taxUpdated = new List<SalesOrderProductLine__c>();
    Map<Id,SalesOrderProductLine__c> updChildren = new Map<Id,SalesOrderProductLine__c>();

    for (Integer i = 0; i < newList.size(); i++) {
      if (
        String.isNotEmpty(newList[i].ShipToStateProvince__c) &&
        Sales_Tax__mdt.getInstance(newList[i].ShipToStateProvince__c) != null &&
        (newList[i].ShipToStateProvince__c !=
        oldList[i].ShipToStateProvince__c ||
        newList[i].State_Tax_Rate__c !=
        Sales_Tax__mdt.getInstance(newList[i].ShipToStateProvince__c).Rate__c)
      ) {
        SalesOrderProductLine__c taxSopl = new SalesOrderProductLine__c();
        taxSopl.Id = newList[i].Id;
        taxSopl.State_Tax_Rate__c = Sales_Tax__mdt.getInstance(
            newList[i].ShipToStateProvince__c
          )
          .Rate__c;
        taxUpdated.add(taxSopl);
      }

      if((newList[i].Quantity__c != oldList[i].Quantity__c || newList[i].DateRequired__c != oldList[i].DateRequired__c) && newList[i].Kit_Bundle_Product__c == true) {
        updChildren.put(newList[i].Id, newList[i]);
      }

    }

    if (taxUpdated.size() > 0) {
      update taxUpdated;
    }

    if (updChildren.size() > 0) {
      updateChildren(updChildren);
    }
  }

  public static void beforeDelete(Map<Id, SalesOrderProductLine__c> oldMap) {
    Set<Id> kitBundles = new Set<Id>();
    Set<Id> withRecipients = new Set<Id>();

    Set<Id> forFulfillments = new Set<Id>();
    Map<Id, Id> sampleMap = new Map<Id, Id>();

    for (Id id : oldMap.keySet()) {

      forFulfillments.add(id);

      if (oldMap.get(id).Kit_Bundle_Product__c == true) {
        kitBundles.add(id);
      }

      if (oldMap.get(id).Recipient_Count__c > 0) {
        withRecipients.add(id);
      }

      if(oldMap.get(id).Sample_Product__c == true && oldMap.get(id).Sample_Parent_Order__c == true) {
        sampleMap.put(id, oldMap.get(id).SalesOrder__c);
      }
      
    }

    if (kitBundles.size() > 0) {
      deleteChildren(kitBundles);
    }
    if (withRecipients.size() > 0) {
      deleteRecipients(withRecipients);
    }

    if(sampleMap.size() > 0) {
      unsetDeletedSampleOrders(sampleMap);
    }

    if (forFulfillments.size() > 0) {
      deleteFulfillments(forFulfillments);
    }
  }

  public static void deleteChildren(Set<Id> kitBundles) {
    List<SalesOrderProductLine__c> rec = [
      SELECT Id, KitBundleLine__c
      FROM SalesOrderProductLine__c
      WHERE KitBundleLine__c IN :kitBundles
    ];

    try {
      System.debug(rec);

      delete rec;
    } catch (DmlException err) {
      System.debug('ON DELETE CHILDREN OF SALES ORDER PROD LINES ERROR ::: ');
      System.debug(err.getMessage());
    }
  }

  public static void updateChildren(Map<Id, SalesOrderProductLine__c> soplMap) {
    List<SalesOrderProductLine__c> recs = [
      SELECT Id, Quantity__c, KitBundleLine__c, DateRequired__c
      FROM SalesOrderProductLine__c 
      WHERE KitBundleLine__c IN :soplMap.keySet()
    ];

    for(SalesOrderProductLine__c r : recs) {
      r.Quantity__c = soplMap.get(r.KitBundleLine__c).Quantity__c;
      r.DateRequired__c = soplMap.get(r.KitBundleLine__c).DateRequired__c;
    }

    update recs;
    
  }

  public static void deleteRecipients(Set<Id> withRecipients) {
    List<Order_Line_Recipient__c> rec = [
      SELECT Id, OrderProductLine__c
      FROM Order_Line_Recipient__c
      WHERE OrderProductLine__c IN :withRecipients
    ];

    try {
      delete rec;
    } catch (DmlException err) {
      System.debug('ON DELETE RECIPIENTS OF SALES ORDER PROD LINES ERROR ::: ');
      System.debug(err.getMessage());
    }
  }

  public static void generateBundleMembers(
    Map<Id, SalesOrderProductLine__c> parentLines
  ) {
    List<Kit_Bundle_Member__c> kitMembers = [
      SELECT
        Id,
        Quantity__c,
        AllowQuantityChange__c,
        ReferenceKitBundle__c,
        ReferenceMemberProduct__c,
        Required__c
      FROM Kit_Bundle_Member__c
      WHERE
        ReferenceKitBundle__c IN (
          SELECT Product__c
          FROM SalesOrderProductLine__c
          WHERE Id IN :parentLines.keySet() AND Product__c != NULL
        )
    ];

    if (kitMembers.size() > 0) {
      Map<Id, List<Kit_Bundle_Member__c>> bundleMap = new Map<Id, List<Kit_Bundle_Member__c>>();

      for (Kit_Bundle_Member__c m : kitMembers) {
        List<Kit_Bundle_Member__c> mList = new List<Kit_Bundle_Member__c>();
        if (bundleMap.containsKey(m.ReferenceKitBundle__c)) {
          mList = bundleMap.get(m.ReferenceKitBundle__c);
        }
        mList.add(m);
        bundleMap.put(m.ReferenceKitBundle__c, mList);
      }

      List<SalesOrderProductLine__c> newOPLs = new List<SalesOrderProductLine__c>();
      for (Id key : parentLines.keySet()) {
        List<Kit_Bundle_Member__c> memberProds = bundleMap.get(
          parentLines.get(key).Product__c
        );

        for (Kit_Bundle_Member__c p : memberProds) {
         
          Decimal price = 0;
          newOPLs.add(
            new SalesOrderProductLine__c(
              AllowQuantityChange__c = p.AllowQuantityChange__c,
              KitBundle__c = false,
              KitBundleMemberRequired__c = p.Required__c,
              Product__c = p.ReferenceMemberProduct__c,
              SalesPrice__c = price,
              ListPrice__c = price,
              ContactShipping__c = parentLines.get(key).ContactShipping__c,
              SalesOrder__c = parentLines.get(key).SalesOrder__c,
              Quantity__c = parentLines.get(key).Quantity__c,
              DateRequired__c = parentLines.get(key).DateRequired__c,
              LineDiscountPercent__c = parentLines.get(key)
                .LineDiscountPercent__c,
              KitBundleLine__c = key
            )
          );
        }
      }

      try {
        insert newOPLs;
      } catch (DmlException err) {
        System.debug(
          'SALES ORDER PRODUCT LINES AFTER INSERT ERROR ON ADDING BUNDLE MEMBERS ::: '
        );
        System.debug(err.getMessage());
      }
      
    }
    generateInitialRecipients(
      (List<SalesOrderProductLine__c>) parentLines.values()
    );
  }

  public static void generateInitialRecipients(
    List<SalesOrderProductLine__c> prodLines
  ) {
    List<Order_Line_Recipient__c> newOLRs = new List<Order_Line_Recipient__c>();
    for (SalesOrderProductLine__c p : prodLines) {
      Order_Line_Recipient__c olr = new Order_Line_Recipient__c();
      olr.Order__c = p.SalesOrder__c;
      olr.OrderProductLine__c = p.Id;
      olr.Recipient__c = p.Order_Contact__c;
      olr.Primary__c = true;
      newOLRs.add(olr);
    }

    try {
      insert newOLRs;
    } catch (DmlException err) {
      System.debug('INITIAL RECIPIENT INSERT ERROR FROM SOPL TRIGGER ::: ');
      System.debug(err.getMessage());
    }
  }

  public static void updateSampleOrders(Set<Id> soIds) {
    List<SalesOrder__c> sampleOrders = [
      SELECT Id
      FROM SalesOrder__c
      WHERE Id IN :soIds
      AND Id NOT IN (
        SELECT SalesOrder__c
        FROM SalesOrderProductLine__c
        WHERE SalesOrder__c IN :soIds
        AND Sample_Product__c != true
      )
      AND Sample_ELM_Copy__c != true
    ];

    if (sampleOrders.size() > 0) {
      for (SalesOrder__c so : sampleOrders) {
        so.Sample_ELM_Copy__c = true;
      }

      try {
        update sampleOrders;
      } catch(DmlException err) {
        System.debug('UPDATE SAMPLE ORDERS ERROR ::: ');
        System.debug(err.getMessage());
      }
    }

  }

  public static void unsetSampleOrders(Set<Id> soIds) {
    List<SalesOrder__c> sampleOrders = [
      SELECT Id
      FROM SalesOrder__c
      WHERE Id IN :soIds
    ];
    
    if (sampleOrders.size() > 0) {
      for (SalesOrder__c so : sampleOrders) {
        so.Sample_ELM_Copy__c = false;
      }

      try {
        update sampleOrders;
      } catch(DmlException err) {
        System.debug('UPDATE SAMPLE ORDERS ERROR ::: ');
        System.debug(err.getMessage());
      }
    }
  }


  public static void unsetDeletedSampleOrders(Map<Id,Id> sampleMap) {
    List<SalesOrder__c> sampleOrders = [
      SELECT Id
      FROM SalesOrder__c
      WHERE Id IN :sampleMap.values()
      AND Id NOT IN (
        SELECT SalesOrder__c
        FROM SalesOrderProductLine__c
        WHERE SalesOrder__c IN :sampleMap.values()
        AND Sample_Product__c = true
        AND Id NOT IN :sampleMap.keySet()
      )
    ];

    if (sampleOrders.size() > 0) {
      for (SalesOrder__c so : sampleOrders) {
        so.Sample_ELM_Copy__c = false;
      }

      try {
        update sampleOrders;
      } catch(DmlException err) {
        System.debug('UPDATE SAMPLE ORDERS ERROR ::: ');
        System.debug(err.getMessage());
      }
    }
  }

  public static void deleteFulfillments(Set<Id> soplIds) {
    List<Fulfillment__c> fulfillments = [
      SELECT Id
      FROM Fulfillment__c
      WHERE Boom_Order_Product_Line__c IN :soplIds
    ];

    if (fulfillments.size() > 0) {
      delete fulfillments;
    }
  }
}