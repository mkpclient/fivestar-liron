public without sharing class SalesOrderHelper {
  static final String RELEASED_STATUS = 'Released';
  static final String UNRELEASED_STATUS = 'Unreleased';
  static final String CANCELLED_STATUS = 'Cancelled';
  static final String APPROVED_STATUS = 'Approved';
  static final String DRAFT_STATUS = 'Draft';

  public static void beforeUpdate(
    Map<Id, SalesOrder__c> oldMap,
    Map<Id, SalesOrder__c> newMap
  ) {

    Approval.unlock(newMap.values());

    for (Id key : newMap.keySet()) {
      SalesOrder__c oldSO = oldMap.get(key);
      SalesOrder__c newSO = newMap.get(key);
      
      // if(newSo.Legacy_Id__c != null) {
      //   continue;
      // }
      // skipping legacy orders
        // when SO meets all release criteria

      if (
        newSO.Status_Picklist__c == APPROVED_STATUS &&
        newSO.ExistingPayments__c == newSO.NetAmount__c &&
        newSO.Status_Picklist__c != RELEASED_STATUS &&
        (newSO.NetAmount__c != 0 ||
        (newSO.Approved_Complimentary_Order__c == true ||
        newSO.Complaint_Order__c == true ||
        newSO.Sample_ELM_Copy__c == true))
      ) {

        newSO.DateReleased__c = System.today();
        newSO.Release_Date__c = System.today();
        newSO.Status_Picklist__c = RELEASED_STATUS;
        newSO.Released__c = System.now();
        newSO.FulfillOrder__c = true;
        newSO.Email_To_Send__c = true;
      }
      
    }
  }

  public static void afterUpdate(
    List<SalesOrder__c> newList,
    List<SalesOrder__c> oldList
  ) {
    Map<Id, SalesOrder__c> salesOrderMap = new Map<Id, SalesOrder__c>();
    Set<Id> salesOrderIds = new Set<Id>();
    List<Id> salesOrderIdsList = new List<Id>();
    List<Id> recordsToLock = new List<Id>();
    Set<Id> paymentsToCancel = new Set<Id>();
    Set<Id> cancelledOrderIds = new Set<Id>();
    Set<Id> fulfillmentsToDelete = new Set<Id>();

    for (Integer i = 0; i < newList.size(); i++) {
      // we do not want legacy orders running through the triggers

      // if(newList[i].Legacy_Id__c != null) {
      //   continue;
      // }
    
      if (orderNeedsFulfillmentsCreated(newList[i], oldList[i])) {
        salesOrderMap.put(newList[i].Id, newList[i]);
      } else if (orderWasCancelled(newList[i], oldList[i])) {
        cancelledOrderIds.add(newList[i].Id);
      }

      if (
        oldList[i].BalanceDueAmount__c != newList[i].BalanceDueAmount__c &&
        newList[i].BalanceDueAmount__c == 0 &&
        newList[i].NetAmount__c != null &&
        newList[i].NetAmount__c != 0
      ) {
        paymentsToCancel.add(newList[i].Id);
      }

      if (
        newList[i].Initial_Invoice_Sent__c != true &&
        newList[i].Email_To_Send__c == true &&
        newList[i].Status_Picklist__c == RELEASED_STATUS
      ) {
        salesOrderIdsList.add(newList[i].Id);
      }

      if (oldList[i].Price_Book__c != newList[i].Price_Book__c) {
        salesOrderIds.add(newList[i].Id);
      }

      if (
        !Approval.isLocked(newList[i].Id) &&
        (newList[i].Status_Picklist__c == 'Released' ||
        newList[i].Status_Picklist__c == 'Approved')
      ) {
        recordsToLock.add(newList[i].Id);
      }

      if (
        newList[i].FulfillOrder__c != oldList[i].FulfillOrder__c &&
        !newList[i].FulfillOrder__c
      ) {
        fulfillmentsToDelete.add(newList[i].Id);
      }
    
    }

    if (fulfillmentsToDelete.size() > 0) {
      deleteFulfillments(fulfillmentsToDelete);
    }

    if (salesOrderMap.size() > 0) {
    createfulfillments(salesOrderMap.keySet());
    }

    if (salesOrderIdsList.size() > 0) {
      BoomOrderInvoiceWithAttachment.sendEmailWithAttachment(salesOrderIdsList);
      if ( !Test.isRunningTest() ) {
        // System.scheduleBatch(new BoomPDFOneHourBatch(salesOrderIdsList), 'BoomPDFOneHourBatch' + System.today(), 60);
      }
    }


    

    if (salesOrderIds.size() > 0) {
      // ? : all order product lines are deleted when price book is changed
      deleteOrderProductLines(salesOrderIds);
    }

    if (paymentsToCancel.size() > 0) {
      cancelScheduledPayments(paymentsToCancel);
    }

    if (cancelledOrderIds.size() > 0) {
      cancelFulfillments(cancelledOrderIds);
    }

    if(recordsToLock.size() > 0) {
      Approval.lock(recordsToLock);
    }
  }

  public static void beforeDelete(List<SalesOrder__c> oldList) {
    for (Integer i = 0; i < oldList.size(); i++) {
      if (
        (oldList[i].Status_Picklist__c != DRAFT_STATUS ||
        oldList[i].ExistingPayments__c > 0)
      ) {
        oldList[i]
          .addError(
            'Cannot delete sales orders that aren\'t in draft and has payments.'
          );
      }
    }
  }

  public static void deleteOrderProductLines(Set<Id> salesOrderIds) {
    List<Order_Line_Recipient__c> lineRecips = [
      SELECT Id
      FROM Order_Line_Recipient__c
      WHERE Order__c IN :salesOrderIds
    ];

    List<SalesOrderProductLine__c> prodLines = [
      SELECT Id
      FROM SalesOrderProductLine__c
      WHERE SalesOrder__c IN :salesOrderIds
    ];

    if (lineRecips.size() > 0) {
      Database.delete(lineRecips, false);
    }

    if (prodLines.size() > 0) {
      Database.delete(prodLines, false);
    }

    System.debug(
      'Deleted ' +
      lineRecips.size() +
      ' line recipients' +
      ' and ' +
      prodLines.size() +
      ' product lines'
    );
  }

  public static Boolean orderNeedsFulfillmentsCreated(
    SalesOrder__c newRecord,
    SalesOrder__c oldRecord
  ) {
    return ((newRecord.FulfillOrder__c == true &&
    oldRecord.FulfillOrder__c == false) || (newRecord.FulfillOrder__c == true && oldRecord.Status_Picklist__c == 'Unreleased' && newRecord.Status_Picklist__c == 'Released'));
  }

  public static Boolean orderWasCancelled(
    SalesOrder__c newRecord,
    SalesOrder__c oldRecord
  ) {
    return (newRecord.Status_Picklist__c == CANCELLED_STATUS &&
    newRecord.Status_Picklist__c != oldRecord.Status_Picklist__c);
  }

  public static void createfulfillments(Set<Id> orderIds) {
    List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();
    Map<Id, Integer> childFulfillmentsCountMap = new Map<Id, Integer>();
    List<Fulfillment__c> childFulfillments = new List<Fulfillment__c>();
    Map<Id, Id> mapLineIdToFulfillmentId = new Map<Id, Id>();

    for (SalesOrderProductLine__c l : queryOrderProductLines(orderIDs)) {

      if(l.Order_Line_Recipients__r !=null && l.Order_Line_Recipients__r.size() > 0) {
        fulfillments.add(constructFulfillment(l));
      

        String numberOfFulfillments = l.Product__r.Name.substringBetween(
          '- ',
          'X'
        );

        if (
          numberOfFulfillments != null &&
          numberOfFulfillments.isNumeric() &&
          Integer.valueOf(numberOfFulfillments) > 1
        ) {
          childFulfillmentsCountMap.put(
            l.Id,
            (Integer.valueOf(numberOfFulfillments) - 1)
          );
        }
      }
    }

    insert fulfillments;

    for (Fulfillment__c f : fulfillments) {

      mapLineIdToFulfillmentId.put(f.Boom_Order_Product_Line__c, f.Id);

      if (childFulfillmentsCountMap.containsKey(f.Boom_Order_Product_Line__c)) {
        for (
          Integer i = 0;
          i < childFulfillmentsCountMap.get(f.Boom_Order_Product_Line__c);
          i++
        ) {
          Fulfillment__c nf = f.clone(false, true);
          nf.ParentFulfillment__c = f.Id;
          childFulfillments.add(nf);
        }
      }
    }

    insert childFulfillments;

    List<Order_Line_Recipient__c> recipientsToUpdate = [SELECT Id, OrderProductLine__c FROM Order_Line_Recipient__c WHERE OrderProductLine__c IN :mapLineIdToFulfillmentId.keySet()];

    if(recipientsToUpdate.size() > 0) {
      for (Order_Line_Recipient__c r : recipientsToUpdate) {
        r.Fulfillment__c = mapLineIdToFulfillmentId.get(r.OrderProductLine__c);
      }
      update recipientsToUpdate;
    }


  }

  public static List<SalesOrderProductLine__c> queryOrderProductLines(
    Set<Id> orderIds
  ) {
    return [
      SELECT
        Id,
        ContactShipping__c,
        Product__r.Name,
        SalesOrder__c,
        SalesOrder__r.Market__c,
        SalesOrder__r.Opportunity__r.Owner.Email,
        (
          SELECT Id, Recipient__c, Primary__c
          FROM Order_Line_Recipients__r
          WHERE Primary__c = TRUE
          LIMIT 1
        )
      FROM SalesOrderProductLine__c
      WHERE
        SalesOrder__c IN :orderIds
        AND Product__r.CreateOrderFulfillment__c = TRUE
        AND Quantity__c > 0
        AND CreatedDate > 2022-01-02T14:04:00Z 
        AND Id NOT IN (
          SELECT
          Boom_Order_Product_Line__c
          FROM Fulfillment__c
          WHERE
          Boom_Order__c IN :orderIds
        )
    ];
  }

  public static void cancelScheduledPayments(Set<Id> orderIds) {
    List<Payment__c> payments = [
      SELECT Id
      FROM Payment__c
      WHERE Status__c = 'Scheduled' AND Sales_Order__c IN :orderIds
    ];

    if (payments.size() > 0) {
      for (Payment__c p : payments) {
        p.Date__c = null;
        p.Status__c = 'Cancelled';
      }

      update payments;
    }
  }


  public static Fulfillment__c constructFulfillment(
    SalesOrderProductLine__c l
  ) {
    Fulfillment__c f = new Fulfillment__c();
    f.Contact__c = l.ContactShipping__c;
    f.Boom_Order_Product_Line__c = l.Id;
    f.Status__c = 'New Profile';
    f.PrimaryRecipient__c = l.Order_Line_Recipients__r[0].Recipient__c;
    f.Product_Name__c = l.Product__r.Name;
    f.Market__c = l.SalesOrder__r.Market__c;
    f.Boom_Order__c = l.SalesOrder__c;
    f.Order_Creator_Email__c = l.SalesOrder__r.Opportunity__r.Owner.Email;
    return f;
  }

  public static void cancelFulfillments(Set<Id> cancelledOrderIds) {
    list<Fulfillment__c> fulfillments_To_Update = [
      SELECT Id, Status__c
      FROM Fulfillment__c
      WHERE Boom_Order__c IN :cancelledOrderIds
    ];

    for (Fulfillment__c ff : fulfillments_To_Update) {
      ff.Status__c = 'Cancelled';
    }

    System.debug('running test? ' + Test.isRunningTest());

    update fulfillments_To_Update;
  }

  public static void deleteFulfillments(Set<Id> orderIds) {
    delete [SELECT Id FROM Fulfillment__c WHERE Boom_Order__c IN :orderIds];
  }
}