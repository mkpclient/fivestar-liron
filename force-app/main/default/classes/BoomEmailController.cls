public without sharing class BoomEmailController {
    public Id orderId { get; set; }

    public SalesOrder__c Order {get {
      if(orderId != null) {
        return querySalesOrder(orderId);
      } else {
        return null;
      }
    } private set;}

    public static SalesOrder__c querySalesOrder(Id recordId) {
      DescribeSObjectResult describeResult = recordId.getSObjectType()
        .getDescribe();
      List<String> fieldNames = new List<String>(
        describeResult.fields.getMap().keySet()
      );
      fieldNames.add('Owner.Name');
      fieldNames.add('ContactBilling__r.Name');
      fieldNames.add('ContactBilling__r.Email');
      fieldNames.add('ContactBilling__r.Phone');
      fieldNames.add('ContactBilling__r.Fax');
      fieldNames.add('ContactBuying__r.Name');
      fieldNames.add('ContactBuying__r.Email');
      fieldNames.add('ContactBuying__r.Phone');
      fieldNames.add('ContactBuying__r.Fax');
      fieldNames.add('Account__r.Name');
  
      String queryString =
        ' SELECT ' +
        String.join(fieldNames, ',') +
        ' FROM ' +
        describeResult.getName() +
        ' WHERE ' +
        ' id = :recordId ' +
        ' LIMIT 1 ';
      return database.query(queryString);
    }

    public list<SalesOrderProductLine__c> ProductLines {
        get {
          if (orderId != null) {
            ProductLines = [
              SELECT
                Id,
                Display_Name_for_Invoice__c,
                Product__r.Name,
                Product__r.Product_Display_Name__c,
                ListPrice__c,
                Name,
                LineDescription__c,
                Quantity__c,
                Actual_Price__c,
                TotalAmount__c,
                DateAvailableToPromise__c,
                DiscountSalesPrice__c
              FROM SalesOrderProductLine__c
              WHERE SalesOrder__c = :orderId
            ];
          } else {
            ProductLines = new List<SalesOrderProductLine__c>();
          }
          return ProductLines;
        }
        private set;
      }

      public Integer ProductLineCount {
        get {
            return ProductLines != null && ProductLines.size() > 0 ? ProductLines.size() : 0;
         } private set;
     }

    public SalesOrderPDFExtension.SettingResource settings {
        get {
          if (settings == null) {
            settings = new SalesOrderPDFExtension.SettingResource();
          }
          return settings;
        }
        private set;
      }

    public list<SalesOrderAdditionalChargeCredit__c> ACCLines {
        get {
          if (orderId != null) {
            ACCLines = [
              SELECT
                LineDescription__c,
                Date__c,
                Quantity__c,
                SalesPrice__c,
                AdditionalChargeCreditAmount__c,
                Additional_Charge_Credit__r.Name
              FROM SalesOrderAdditionalChargeCredit__c
              WHERE SalesOrder__c = :orderId
            ];
          } else {
            ACCLines = new List<SalesOrderAdditionalChargeCredit__c>();
          }
    
          return ACCLines;
        }
        private set;
      }

      public Integer ChargeCreditLineCount {
        get {
            return ACCLines != null ? ACCLines.size() : 0;
         } private set;
      }

      public list<Payment__c> PaymentSchedules {
        get {
          if (
            orderId != null ) {
            PaymentSchedules = [
              SELECT
                Scheduled_Payment_Date__c,
                Id,
                Date__c,
                Payment_Type__c,
                Memo__c,
                Amount__c,
                Contact__r.Name,
                CardType__c,
                Last_Four_Digits__c,
                Status__c,
                Billing_Name__c
              FROM Payment__c
              WHERE Sales_Order__c = :orderId AND Status__c = 'Scheduled'
              ORDER BY Date__c
            ];
          } else {
            PaymentSchedules = new List<Payment__c>();
          }
          return PaymentSchedules;
        }
        private set;
      }

      public list<Order_Line_Recipient__c> LineRecipients {
        get {
          if (orderId != null) {
            LineRecipients = queryLineRecipients(orderId);
          } else {
            LineRecipients = new List<Order_Line_Recipient__c>();
          }
          return LineRecipients;
        }
        private set;
      }
    
  public List<Payment__c> allPayments {
    get {
      if(orderId != null && (allPayments == null || allPayments.size() < 1) && PaymentSchedules != null && Payments != null) {
        List<Payment__c> newList = new List<Payment__c>();
        newList.addAll(Payments);
        newList.addAll(PaymentSchedules);
        return newList;
      } else {
        return new List<Payment__c>();
      }
    }
    private set;
  }

  public List<Payment__c> Payments {
    get {
      if (orderId != null) {
        Payments = [
          SELECT
            Id,
            Date__c,
            Payment_Type__c,
            Memo__c,
            Amount__c,
            Contact__r.Name,
            CardType__c,
            Last_Four_Digits__c,
            Status__c,
            Billing_Name__c
          FROM Payment__c
          WHERE Sales_Order__c = :orderId AND Status__c = 'Completed'
          ORDER BY Date__c
        ];
      } else {
        Payments = new List<Payment__c>();
      }

      return Payments;
    }
    private set;
  }

      public static list<Order_Line_Recipient__c> queryLineRecipients(Id orderId) {
        return orderId == null
          ? new List<Order_Line_Recipient__c>()
          : [
              SELECT
                Id,
                OrderLine__c,
                OrderProductLine__r.Product__r.Name,
                OrderProductLine__r.Product__r.Product_Display_Name__c,
                OrderProductLine__r.Display_Name_for_Invoice__c,
                Recipient__r.Name,
                Primary__c
              FROM Order_Line_Recipient__c
              WHERE Order__c = :orderId
              ORDER BY
                OrderProductLine__r.SortOrder__c NULLS LAST,
                Recipient__r.Name
            ];
      }
}