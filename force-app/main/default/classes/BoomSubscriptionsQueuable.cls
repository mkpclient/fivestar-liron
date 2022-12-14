global class BoomSubscriptionsQueuable implements Queueable {
  private List<Subscription__c> subscriptions = new List<Subscription__c>();
  private Boolean isInsert;
  private Boolean isAddon = false;
  private List<Subscription__c> addonSubs = new List<Subscription__c>();
  public static String SCHEDULED_SUBSCRIPTION = 'Subscription Copies';

  public static String MAG_TYPE_ESSENTIAL_LIVING = 'Essential Living';

  global BoomSubscriptionsQueuable(
    List<Subscription__c> subscriptions,
    Boolean isInsert,
    Boolean isAddon
  ) {
    this.subscriptions = subscriptions;
    this.isInsert = isInsert;
    this.isAddon = isAddon;
  }
  global BoomSubscriptionsQueuable(
    List<Subscription__c> subscriptions,
    Boolean isInsert,
    List<Subscription__c> addonSubs
  ) {
    this.subscriptions = subscriptions;
    this.isInsert = isInsert;
    this.addonSubs = addonSubs;
  }

  global void execute(QueueableContext qCntxt) {
    if (this.subscriptions.size() > 0) {
      if (this.isInsert) {
        // createNewSubscriptions(this.subscriptions);
      } else if (this.isAddon) {
        updateSubscriptionOrders(this.subscriptions, new List<SalesOrder__c>());
      } else {
        createSubscriptionOrders(this.subscriptions, this.addonSubs);
      }
    } else {
      updateSubscriptionOrders(this.addonSubs, new List<SalesOrder__c>());
    }
  }

  public static void updateSubscriptionOrders(
    List<Subscription__c> subscriptions,
    List<SalesOrder__c> salesOrders
  ) {
    List<SalesOrder__c> existingOrders = salesOrders;

      existingOrders = [
        SELECT Id, Market__c, ContactShipping__c, Subscription__c, OrderDate__c
        FROM SalesOrder__c
        WHERE
          Status_Picklist__c = 'Pending Renewal'
          AND Subscription__c IN (
            SELECT Parent_Subscription__c
            FROM Subscription__c
            WHERE Id IN :subscriptions
          )
        FOR UPDATE
      ];
    

    Map<Id, Subscription__c> updatedSubs = new Map<Id, Subscription__c>(
      [
        SELECT Id, Parent_Subscription__c
        FROM Subscription__c
        WHERE Id IN :subscriptions
        FOR UPDATE
      ]
    );
    // getting them from trigger because the passed value for some reason sometimes does not have Parent_Subscription__c
    System.debug(existingOrders);

    Map<Id, SalesOrder__c> existingOrdersMap = new Map<Id, SalesOrder__c>();
    List<SalesOrderProductLine__c> prodLines = new List<SalesOrderProductLine__c>();
    List<Order_Line_Recipient__c> recipients = new List< Order_Line_Recipient__c>();
    Map<Id,Order_Line_Recipient__c> recipientMap = new Map<Id,Order_Line_Recipient__c>();
    for (SalesOrder__c order : existingOrders) {
      existingOrdersMap.put(order.Subscription__c, order);
    }
    Map<Id, Subscription__c> subWithSopls = new Map<Id,Subscription__c>([SELECT Id FROM Subscription__c WHERE Id IN (SELECT Related_Subscription__c FROM SalesOrderProductLine__c WHERE SalesOrder__c IN :existingOrders AND Related_Subscription__c IN :subscriptions)]);


    for (Subscription__c s : subscriptions) {
      if(s.Status__c != 'Active') {
        continue;
      }
      Id key = updatedSubs.get(s.Id).Parent_Subscription__c;
      if(existingOrdersMap.containsKey(key) && !subWithSopls.containsKey(s.Id)) {
        SalesOrder__c so = existingOrdersMap.get(key);
        SalesOrderProductLine__c sopl = new SalesOrderProductLine__c();
        sopl = generateSubscriptionProductLine(
          s,
          so.OrderDate__c,
          so
        );
        
        sopl.SalesOrder__c = so.Id;
        Order_Line_Recipient__c recipient = generateSubscriptionLineRecipient(
          s,
          so
        );
        recipient.OrderProductLine__r = sopl;
        prodLines.add(sopl);
        recipients.add(recipient);
        subWithSopls.put(s.id, s);
      }
      
    }

    if (prodLines.size() > 0) {
      insert prodLines;
      for(Order_Line_Recipient__c r : recipients) {
        recipientMap.put(r.OrderProductLine__r.Id, r);
      }
      List<Order_Line_Recipient__c> defaultRecipients = [
        SELECT Id, Order__c,OrderProductLine__c
        FROM Order_Line_Recipient__c
        WHERE OrderProductLine__c IN :prodLines
        FOR UPDATE
      ];

      for (Order_Line_Recipient__c r : defaultRecipients) {
        String key = r.OrderProductLine__c;
        Order_Line_Recipient__c olr = recipientMap.get(key);
        olr.OrderProductLine__r = null;
        olr.Id = r.Id;
        recipientMap.put(key, olr);
      }

      if (recipientMap.size() > 0) {
        update recipientMap.values();
      }
    }
  }

  public static void createSubscriptionOrders(
    List<Subscription__c> subscriptions,
    List<Subscription__c> addonSubs
  ) {
    String soFields = 'OrderDate__c,OrderName__c,Market__c,Opportunity__c,Account__c,Price_Book__c,ContactBilling__c,ContactBuying__c,ContactShipping__c,BillToName__c,BillToCity__c,BillToCountry__c,BillToStateProvince__c,BillToStreetLong__c,BillToZipPostalCode__c,ShipToCity__c,ShipToCountry__c,ShipToName__c,ShipToStateProvince__c,ShipToStreetLong__c,ShipToZipPostalCode__c';
    String queryString =
      'SELECT ' +
      soFields +
      ' FROM SalesOrder__c WHERE Id IN (SELECT Original_Subscription_Boom_Order__c FROM Subscription__c WHERE Id IN :subscriptions) FOR UPDATE';
    Map<Id, SalesOrder__c> salesOrderMap = new Map<Id, SalesOrder__c>(
      (List<SalesOrder__c>) Database.query(queryString)
    );

    Map<Id,Subscription__c> existingSubMap = new Map<Id, Subscription__c>([
      SELECT Id, (SELECT Id, Market__c, Opportunity__c, Price_Book__c, Opportunity__r.Name FROM Boom_Orders__r ORDER BY OrderDate__c Desc LIMIT 1)
      FROM Subscription__c
      WHERE Id IN :subscriptions
    ]);

    Map<Id, SalesOrder__c> newSalesOrders = new Map<Id, SalesOrder__c>();
    Map<Id, SalesOrderProductLine__c> newSalesOrderProductLines = new Map<Id, SalesOrderProductLine__c>();
    Map<Id, Order_Line_Recipient__c> newOrderLineRecipients = new Map<Id, Order_Line_Recipient__c>();

    for (Subscription__c sub : subscriptions) {
      if(sub.Status__c != 'Active') {
        continue;
      }
      Integer day = Integer.valueOf(sub.Renewal_Date_Day_of_Month__c);
      
      Integer month = System.today().addMonths(1).month();
      Integer year = System.today().year();

      if(day > System.today().day()) {
        month = System.today().month();
      }

      Boolean hasSpecialSchedule =
        sub.Base_Product__c == SCHEDULED_SUBSCRIPTION &&
        ((sub.Start_Date__c.month() == System.today().month() && 
        sub.Start_Date__c.year() == System.today().year()));

      Boolean isEssentialLiving = sub.Magazine_Type__c == MAG_TYPE_ESSENTIAL_LIVING;
      // add logic to determine if the subscription is a special schedule
      Date startFullDate =  sub.Start_Date__c;
      Integer startMonth = startFullDate.month();
      Integer startDate = startFullDate.day();
      Integer startYear = startFullDate.year();

      if (hasSpecialSchedule && isEssentialLiving) {
        Map<String,Order_Renewal_Schedule__mdt> schedules = Order_Renewal_Schedule__mdt.getAll();

        for(Order_Renewal_Schedule__mdt sched : schedules.values()) {
          Date schedStartDate = Date.newInstance(startYear, Integer.valueOf(sched.Start_Month__c), Integer.valueOf(sched.Start_Date__c));
          Date schedEndDate = Date.newInstance(startYear, Integer.valueOf(sched.End_Month__c), Integer.valueOf(sched.End_Date__c));
          if(sched.End_Month__c < sched.Start_Month__c) {
            schedEndDate.addYears(1);
          }
          System.debug(sched);
          if(schedStartDate <= startFullDate && schedEndDate >= startFullDate) {
            day = Integer.valueOf(sched.Renewal_Date__c);
            month = Integer.valueOf(sched.Renewal_Month__c);
          }
        }
      } else if (hasSpecialSchedule && !isEssentialLiving) {
        Map<String, BiMonthly_Renewal_Schedule__mdt> schedules = BiMonthly_Renewal_Schedule__mdt.getAll();
        // Map<DeveloperName, metadata values> 
        for(BiMonthly_Renewal_Schedule__mdt sched : schedules.values()) {
          Date schedStartDate = Date.newInstance(startYear, Integer.valueOf(sched.Start_Month__c), Integer.valueOf(sched.Start_Date__c));
          Date schedEndDate = Date.newInstance(startYear, Integer.valueOf(sched.End_Month__c), Integer.valueOf(sched.End_Date__c));
          if(sched.End_Month__c < sched.Start_Month__c) {
            schedEndDate.addYears(1);
          }
          System.debug(sched);
          if(schedStartDate <= startFullDate && schedEndDate >= startFullDate) {
            day = Integer.valueOf(sched.Renewal_Date__c);
            month = Integer.valueOf(sched.Renewal_Month__c);
          }

        }
      } else if (sub.Renewal_Frequency__c == 'Annual') {
        month = System.today().month();
        year = System.today().year() + 1;
      } else if (sub.Renewal_Frequency__c == 'Bi-Monthly') {
        month = System.today().addMonths(2).month();
      }
      // month = Integer.valueOf(Order_Renewal_Schedule__mdt.getInstance('Universal_Renewal_date').Renewal_Month__c);
      if(month < System.today().month()) {
        year = year + 1;
      }
        

      Date orderDate = date.newInstance(year, month, day);
      
      SalesOrder__c newSo = generateSubscriptionOrder(
        salesOrderMap.get(sub.Original_Subscription_Boom_Order__c),
        sub,
        orderDate
      );
      SalesOrderProductLine__c sopl = generateSubscriptionProductLine(
        sub,
        orderDate,
        newSo
      );
      Order_Line_Recipient__c recipient = generateSubscriptionLineRecipient(
        sub,
        newSo
      );
      
      if(existingSubMap.containsKey(sub.Id) 
        && existingSubMap.get(sub.Id).Boom_Orders__r != null 
        && existingSubMap.get(sub.Id).Boom_Orders__r.size() > 0) {
          SalesOrder__c existingSo = existingSubMap.get(sub.Id).Boom_Orders__r[0];
          newSo.Market__c = existingSo.Market__c;
          newSo.Opportunity__c = existingSo.Opportunity__c;
          newSo.Price_Book__c = existingSo.Price_Book__c;
          newSo.OrderName__c = existingSo.Opportunity__r.Name;
      }

      newSalesOrders.put(sub.Id, newSo);
      newSalesOrderProductLines.put(sub.Id, sopl);
      newOrderLineRecipients.put(sub.Id, recipient);
    }

    insert newSalesOrders.values();

    for (Id subId : newSalesOrders.keySet()) {
      SalesOrder__c so = newSalesOrders.get(subId);
      SalesOrderProductLine__c sopl = newSalesOrderProductLines.get(subId);
      Order_Line_Recipient__c olr = newOrderLineRecipients.get(subId);
      sopl.SalesOrder__c = so.Id;
      newSalesOrderProductLines.put(subId, sopl);
      newOrderLineRecipients.put(subId, olr);
    }

    insert newSalesOrderProductLines.values();

    List<Order_Line_Recipient__c> recipients = [
      SELECT Id, Order__r.Subscription__c
      FROM Order_Line_Recipient__c
      WHERE Order__r.Subscription__c IN :subscriptions
      FOR UPDATE
    ];

    for (Order_Line_Recipient__c r : recipients) {
      String key = r.Order__r.Subscription__c;
      Order_Line_Recipient__c olr = newOrderLineRecipients.get(key);
      olr.Id = r.Id;
      newOrderLineRecipients.put(key, olr);
    }

    update newOrderLineRecipients.values();

    if (addonSubs.size() > 0) {
      updateSubscriptionOrders(addonSubs, newSalesOrders.values());
    }
  }

  public static SalesOrder__c generateSubscriptionOrder(
    SalesOrder__c so,
    Subscription__c sub,
    Date orderDate
  ) {
    SalesOrder__c newSo = so.clone(false, true, false, false);
    newSo.Id = null;
    newSo.Subscription__c = sub.Id;
    newSo.OrderDate__c = orderDate;
    newSo.Status_Picklist__c = 'Pending Renewal';
    return newSo;
  }

  public static SalesOrderProductLine__c generateSubscriptionProductLine(
    Subscription__c sub,
    Date orderDate,
    SalesOrder__c so
  ) {
    SalesOrderProductLine__c sopl = new SalesOrderProductLine__c();
    sopl.Quantity__c = sub.Renewal_Quantity__c;
    sopl.SalesPrice__c = sub.Renewal_Price__c;
    sopl.ListPrice__c = sub.Renewal_Price__c;
    sopl.DateRequired__c = orderDate;
    sopl.Product__c = sub.Renewal_Product__c;
    sopl.ContactShipping__c = so.ContactShipping__c;
    sopl.DateAvailableToPromise__c = orderDate;
    sopl.Related_Subscription__c = sub.Id;
    return sopl;
  }

  public static Order_Line_Recipient__c generateSubscriptionLineRecipient(
    Subscription__c sub,
    SalesOrder__c so
  ) {
    Order_Line_Recipient__c olr = new Order_Line_Recipient__c();
    olr.AccountManager__c = sub.Account_Manager__c;
    olr.Market__c = so.Market__c;
    olr.Primary__c = true;
    olr.Recipient__c = sub.Contact__c;
    return olr;
  }

  //   public static void createNewSubscriptions(List<Subscription__c> subs) {
  //     Map<Id, Subscription__c> addonSubs = new Map<Id, Subscription__c>();
  //     Map<Id, Subscription__c> subMap = new Map<Id, Subscription__c>();
  //     List<Subscription__c> existingRenewals = new List<Subscription__c>();

  //     for (Subscription__c s : subs) {
  //       if (s.Name.contains('-ADDON-') && s.Parent_Subscription__c == null) {
  //         addonSubs.put(s.Original_Subscription_Boom_Order__c, s);
  //       } else if (
  //         s.Name.contains('-ADDON-') && s.Parent_Subscription__c != null
  //       ) {
  //         existingRenewals.add(s);
  //       } else {
  //         subMap.put(s.Original_Subscription_Boom_Order__c, s);
  //       }
  //     }

  //     if (subMap.size() > 0) {
  //       insert subMap.values();
  //     }

  //     if (addonSubs.size() > 0) {
  //       for (Id key : addonSubs.keySet()) {
  //         Subscription__c addon = addonSubs.get(key);
  //         Subscription__c sub = subMap.get(key);
  //         addon.Parent_Subscription__c = sub.Id;
  //         addonSubs.put(key, addon);
  //       }
  //       insert addonSubs.values();
  //     }

  //     if (existingRenewals.size() > 0) {
  //       insert existingRenewals;
  //     }
  //   }
}