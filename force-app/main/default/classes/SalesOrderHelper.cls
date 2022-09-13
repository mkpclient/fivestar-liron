public without sharing class SalesOrderHelper {
  static final String RELEASED_STATUS = 'Released';
  static final String UNRELEASED_STATUS = 'Unreleased';
  static final String CANCELLED_STATUS = 'Cancelled';
  static final String APPROVED_STATUS = 'Approved';
  static final String DRAFT_STATUS = 'Draft';
  static final String RENEWAL_STATUS = 'Pending Renewal';
  static final String UPDATE_NEEDED = 'Payment Update Needed';
  static final String SUB_CANCELLED = 'Subscription Cancelled';

  public static void beforeUpdate(
    Map<Id, SalesOrder__c> oldMap,
    Map<Id, SalesOrder__c> newMap
  ) {
    Approval.unlock(newMap.values());
    List<Subscription__c> subsForQueue = new List<Subscription__c>();

    for (Id key : newMap.keySet()) {
      SalesOrder__c oldSO = oldMap.get(key);
      SalesOrder__c newSO = newMap.get(key);

      // if(newSo.Legacy_Id__c != null) {
      //   continue;
      // }
      // skipping legacy orders
      // when SO meets all release criteria

      if (orderCanBeReleased(oldSO, newSO)) {
        if (
          newSO.Status_Picklist__c == RENEWAL_STATUS &&
          newSO.Subscription__c != null &&
          ((FivestarSetting__mdt.getInstance('Universal') != null &&
          FivestarSetting__mdt.getInstance('Universal')
            .Allow_Subscriptions__c) || test.isRunningTest())
        ) {
          newSO.Initial_Invoice_Sent__c = false;
          newSO.Email_To_Send__c = true;
          subsForQueue.add(
            new Subscription__c(
              Id = newSO.Subscription__c,
              Create_Next_Subscription__c = true
            )
          );
        }
        newSO.DateReleased__c = System.today();
        newSO.Release_Date__c = System.today();
        newSO.Status_Picklist__c = RELEASED_STATUS;
        newSO.Released__c = System.now();
        newSO.FulfillOrder__c = true;
        newSO.Email_To_Send__c = true;
      } else if (
        newSO.Status_Picklist__c == UPDATE_NEEDED &&
        newSO.Subscription__c != null &&
        oldSO.Status_Picklist__c != UPDATE_NEEDED &&
        ((FivestarSetting__mdt.getInstance('Universal') != null &&
        FivestarSetting__mdt.getInstance('Universal').Allow_Subscriptions__c) ||
        test.isRunningTest())
      ) {
        newSO.Initial_Invoice_Sent__c = false;
        newSO.Email_To_Send__c = true;

        subsForQueue.add(
          new Subscription__c(
            Id = newSO.Subscription__c,
            Create_Next_Subscription__c = true
          )
        );
      }
    }

    if (subsForQueue.size() > 0) {
      processSubscriptions(subsForQueue);
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
    Set<Id> cancelledSubs = new Set<Id>();
    Map<Id, SalesOrder__c> discountSalesOrderMap = new Map<Id, SalesOrder__c>();

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
        newList[i].Status_Picklist__c == SUB_CANCELLED &&
        oldList[i].Status_Picklist__c != SUB_CANCELLED &&
        newList[i].Subscription__c != null
      ) {
        cancelledSubs.add(newList[i].Subscription__c);
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
        newList[i].Status_Picklist__c == RELEASED_STATUS &&
        (oldList[i].Status_Picklist__c != RENEWAL_STATUS ||
        oldList[i].Status_Picklist__c != UPDATE_NEEDED)
      ) {
        salesOrderIdsList.add(newList[i].Id);
      }

      if (
        oldList[i].Price_Book__c != newList[i].Price_Book__c &&
        newList[i].Subscription__c == null
      ) {
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

      // newList[i].Status_Picklist__c != oldList[i].Status_Picklist__c && newList[i].Status_Picklist__c == 'Released' && (oldList[i] != 'Pending Renewal' || oldList[i] != 'Payment Update Needed')
      // create a new method to check if there are existing parent subscriptions already created for the salesorder (pass Map<Id,SalesOrder__c>() of salesorders collected from above)
      if (
        newList[i].Status_Picklist__c != oldList[i].Status_Picklist__c &&
        newList[i].Status_Picklist__c == 'Released' &&
        oldList[i].Status_Picklist__c != 'Pending Renewal' &&
        oldList[i].Status_Picklist__c != 'Payment Update Needed'
      ) {
        discountSalesOrderMap.put(newList[i].Id, newList[i]);
      }
    }

    if (discountSalesOrderMap.size() > 0) {
      addDiscountSubscriptions(discountSalesOrderMap);
    }

    if (fulfillmentsToDelete.size() > 0) {
      deleteFulfillments(fulfillmentsToDelete);
    }

    if (salesOrderMap.size() > 0) {
      createfulfillments(salesOrderMap.keySet());
    }

    if (cancelledSubs.size() > 0) {
      cancelSubscriptions(cancelledSubs);
    }

    if (salesOrderIdsList.size() > 0) {
      if (!Test.isRunningTest()) {
        BoomOrderInvoiceWithAttachment.sendEmailWithAttachment(
          salesOrderIdsList
        );
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

    if (recordsToLock.size() > 0) {
      Approval.lock(recordsToLock);
    }
  }

  // SELECT Id,Original_Subscription_Boom_Order__c FORM Subscription__c WHERE Original_Subscription_Boom_Order__c IN :salesOrderMap.keySet()
  // * QUERY ALL FIELDS FROM SUBSCRIPTION IN SOQL ABOVE *
  // loop through the subscriptions and do a salesOrderMap.remove(sub.Original_Subscription_Boom_Order__c);

  // if any subscription is returned, we create the new discount product SubscriptionHelper.createRecurringAddon(subscriptions);

  // In SubscriptionHelper, check if an addon was already created for the product line. Comment already made in "createRecurringAddon"

  // if salesOrderMap.size() > 0, we go loop through the salesOrderMap.values()
  // set<id> collect a set of id for so.Opportunity__c;

  // SELECT Id,Original_Subscription_Boom_Order__c,Original_Subscription_Boom_Order__r.Opportunity__c FROM Subscription__c WHERE Parent_Subscription__c = NULL AND (NOT Name LIKE '%-disc-%') AND (NOT Name LIKE '%-addon-%') AND Original_Subscription_Boom_Order__c IN ( SELECT Id FROM SalesOrder__c WHERE Opportunity__c IN :oppIds);

  // set<id> existingOppIds;
  // loop through the subscriptions that we queried and add Original_Subscription_Boom_Order__r.Opportunity__c to new set of Ids.

  // List<SalesOrder__c> soListForDisc = new List<SalesOrder__c>();
  // loop through our salesOrderMap.values() and check if existingOppIds.contains(so.Opportunity__c)
  // if true, we add the salesorder__c to a new list of salesorder__c
  // we create a new discount subscription but without details from parent
  //  Naming convention: SalesOrder__c.Name + '-DISC-' + SalesOrderProductLine__c.Name;
  // Original_Subscription_Boom_Order__c = SalesOrder__c.Id

  public static void addDiscountSubscriptions(
    Map<Id, SalesOrder__c> discountSalesOrderMap
  ) {
    List<Subscription__c> subscriptions = [
      SELECT
        Id,
        Original_Subscription_Boom_Order__c,
        Original_Subscription_Boom_Order__r.Opportunity__c,
        Contact__c,
        Create_Next_Subscription__c,
        Pause_Date__c,
        End_Date__c,
        Name,
        Parent_Subscription__c,
        Renewal_Date_Day_of_Month__c,
        Renewal_Frequency__c,
        Renewal_Price__c,
        Start_Date__c,
        Status__c
      FROM Subscription__c
      WHERE
        Original_Subscription_Boom_Order__c IN :discountSalesOrderMap.keySet()
    ];

    for (Integer i = 0; i < subscriptions.size(); i++) {
      discountSalesOrderMap.remove(
        subscriptions[i].Original_Subscription_Boom_Order__c
      );
    }

    // if (subscriptions.size() > 0) {
    //   SubscriptionHelper.createRecurringAddon(subscriptions);
    // }

    Set<Id> oppIds = new Set<Id>();
    if (discountSalesOrderMap.size() > 0) {
      for (SalesOrder__c discountSalesOrder : discountSalesOrderMap.values()) {
        oppIds.add(discountSalesOrder.Opportunity__c);
      }
    }

    List<Subscription__c> parentDiscountSubscriptions = [
      SELECT
        Id,
        Original_Subscription_Boom_Order__c,
        Original_Subscription_Boom_Order__r.Opportunity__c
      FROM Subscription__c
      WHERE
        Parent_Subscription__c = NULL
        AND (NOT Name LIKE '%-disc-%')
        AND (NOT Name LIKE '%-addon-%')
        AND Original_Subscription_Boom_Order__c IN (
          SELECT Id
          FROM SalesOrder__c
          WHERE Opportunity__c IN :oppIds
        )
    ];

    Set<Id> existingOppIds = new Set<Id>();
    for (Subscription__c parentDiscSub : parentDiscountSubscriptions) {
      existingOppIds.add(
        parentDiscSub.Original_Subscription_Boom_Order__r.Opportunity__c
      );
    }

    Map<Id, SalesOrder__c> addSubSO = new Map<Id, SalesOrder__c>();
    for (SalesOrder__c discountSO : discountSalesOrderMap.values()) {
      if (existingOppIds.contains(discountSO.Opportunity__c)) {
        addSubSO.put(discountSO.Id, discountSO);
      }
    }

    List<SalesOrderProductLine__c> prodLines = [
      SELECT
        Id,
        ListPrice__c,
        Quantity__c,
        Name,
        SalesOrder__c,
        SalesOrder__r.Release_Date__c,
        Product__c,
        SalesOrder__r.ContactBilling__c,
        SalesOrder__r.Name,
        Product__r.Recurring_Discount__c,
        Product__r.Discount_Frequency__c,
        Product__r.Discount_Occurences__c,
        (
          SELECT Id, AccountManager__c, Recipient__c
          FROM Order_Line_Recipients__r
          WHERE Primary__c = TRUE
          LIMIT 1
        )
      FROM SalesOrderProductLine__c
      WHERE
        SalesOrder__c IN :addSubSO.keySet()
        AND Product__r.Recurring_Discount__c = TRUE
    ];

    List<Subscription__c> addonSubs = new List<Subscription__c>();
    for (SalesOrderProductLine__c line : prodLines) {
      addonSubs.add(generateDiscAddon(line));
    }

    insert addonSubs;
  }

  public static Subscription__c generateDiscAddon(
    SalesOrderProductLine__c line
  ) {
    Subscription__c newAddonSub = new Subscription__c();
    Integer numOccurences = Integer.valueOf(
      line.Product__r.Discount_Occurences__c
    );
    Date currDate = System.today();
    Date endDate = Date.newInstance(
        currDate.year(),
        currDate.month(),
        currDate.day()
      )
      .addMonths(numOccurences - 1)
      .addDays(-1);
    newAddonSub.End_Date__c = endDate;
    newAddonSub.Start_Date__c = System.today();
    String subName =
      line.SalesOrder__r.Name.replace('SO', 'SUB') +
      '-DISC-' +
      line.Name;
    newAddonSub.Name = subName;
    newAddonSub.status__c = 'Active';
    // newAddonSub.Payment_Method__c = sub.Payment_Method__c;
    newAddonSub.Account_Manager__c = line.Order_Line_Recipients__r[0]
      .AccountManager__c;
    newAddonSub.Contact__c = line.Order_Line_Recipients__r[0].Recipient__c;
    newAddonSub.Renewal_Product__c = line.Product__c;
    newAddonSub.Renewal_Price__c = line.ListPrice__c;
    // newAddonSub.Renewal_Frequency__c = sub.Renewal_Frequency__c;
    newAddonSub.Renewal_Quantity__c = line.Quantity__c;
    // newAddonSub.Renewal_Date_Day_of_Month__c = sub.Renewal_Date_Day_of_Month__c;
    newAddonSub.Original_Subscription_Boom_Order__c = line.SalesOrder__c;
    return newAddonSub;
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

  //

  public static void cancelSubscriptions(Set<Id> subIds) {
    List<Subscription__c> subs = [
      SELECT Id
      FROM Subscription__c
      WHERE Id IN :subIds AND Status__c != 'Cancelled'
      FOR UPDATE
    ];
    if (subs.size() > 0) {
      for (Subscription__c s : subs) {
        s.Status__c = 'Cancelled';
      }
      update subs;
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

  public static Boolean orderCanBeReleased(
    SalesOrder__c oldSO,
    SalesOrder__c newSO
  ) {
    return ((newSO.Status_Picklist__c == APPROVED_STATUS ||
    ((newSO.Status_Picklist__c == RENEWAL_STATUS ||
    newSO.Status_Picklist__c == UPDATE_NEEDED) &&
    newSO.OrderDate__c <= System.today() &&
    ((FivestarSetting__mdt.getInstance('Universal') != null &&
    FivestarSetting__mdt.getInstance('Universal').Allow_Subscriptions__c) ||
    test.isRunningTest()))) &&
    newSO.ExistingPayments__c == newSO.NetAmount__c &&
    newSO.Status_Picklist__c != RELEASED_STATUS &&
    (newSO.NetAmount__c != 0 ||
    (newSO.Approved_Complimentary_Order__c == true ||
    newSO.Complaint_Order__c == true ||
    newSO.Sample_ELM_Copy__c == true)));
  }

  public static Boolean orderNeedsFulfillmentsCreated(
    SalesOrder__c newRecord,
    SalesOrder__c oldRecord
  ) {
    return ((newRecord.FulfillOrder__c == true &&
    oldRecord.FulfillOrder__c == false) ||
    (newRecord.FulfillOrder__c == true &&
    oldRecord.Status_Picklist__c == 'Unreleased' &&
    newRecord.Status_Picklist__c == 'Released'));
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
      if (
        l.Order_Line_Recipients__r != null &&
        l.Order_Line_Recipients__r.size() > 0
      ) {
        fulfillments.add(constructFulfillment(l));

        String numberOfFulfillments = String.isNotEmpty(l.Product__r.Name) && l.Product__r.Name.contains('- ') && l.Product__r.Name.contains('X') ? l.Product__r.Name.substringBetween(
          '- ',
          'X'
        ) : null;


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

    List<Order_Line_Recipient__c> recipientsToUpdate = [
      SELECT Id, OrderProductLine__c
      FROM Order_Line_Recipient__c
      WHERE OrderProductLine__c IN :mapLineIdToFulfillmentId.keySet()
    ];

    if (recipientsToUpdate.size() > 0) {
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
          SELECT Boom_Order_Product_Line__c
          FROM Fulfillment__c
          WHERE Boom_Order__c IN :orderIds
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

  public static void processSubscriptions(List<Subscription__c> subs) {
    List<Subscription__c> childrenSubs = [
      SELECT Id
      FROM Subscription__c
      WHERE Parent_Subscription__c IN :subs
    ];
    List<Subscription__c> subsLocal = new List<Subscription__c>();
    subsLocal.addAll(subs);
    if (childrenSubs.size() > 0) {
      for (Subscription__c s : childrenSubs) {
        s.Create_Next_Subscription__c = true;
        subsLocal.add(s);
      }
    }
    update subsLocal;
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