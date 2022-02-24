public without sharing class PaymentConversionTriggerHelper {
    
    public static void afterInsert(Map<Id, kugo2p__PaymentX__c> newMap) {
        Set<String> orderLegacyIds = new Set<String>();
        Set<String> recurringIds = new Set<String>();
        Set<String> orderNames = new Set<String>();
        Set<String> subscriptionIds = new Set<String>();
        Map<Id, kugo2p__Payment_Profile__c> paymentProfileMap = new Map<Id, kugo2p__Payment_Profile__c>();

        for (kugo2p__PaymentX__c p : newMap.values()) {
            if(p.kugo2p__SalesOrder__c != null) {
                orderLegacyIds.add(p.kugo2p__SalesOrder__c);
            } else if (p.kugo2p__Payment_Profile__c != null) {
                recurringIds.add(p.kugo2p__Payment_Profile__c);
            } else if (String.isNotEmpty(p.kugo2p__Invoice_Number__c)) {
                orderNames.add(p.kugo2p__Invoice_Number__c);
            } else if (String.isNotEmpty(p.kugo2p__Subscription_Id__c)) {
                subscriptionIds.add(p.kugo2p__Subscription_Id__c);
            }
        }

        if(recurringIds.size() > 0) {
            paymentProfileMap = queryOrdersWithProfiles(recurringIds);
        }

        if(orderLegacyIds.size() > 0 || paymentProfileMap.size() > 0 || orderNames.size() > 0 || subscriptionIds.size() > 0) {
            createBoomPayments(orderLegacyIds, paymentProfileMap, newMap, orderNames, subscriptionIds, false);
        }


    }

    public static void afterUpdate(Map<Id, kugo2p__PaymentX__c> oldMap, Map<Id, kugo2p__PaymentX__c> newMap) {
        Set<String> orderLegacyIds = new Set<String>();
        Set<String> recurringIds = new Set<String>();
        Set<String> orderNames = new Set<String>();
        Set<String> subscriptionIds = new Set<String>();
        Map<Id, kugo2p__Payment_Profile__c> paymentProfileMap = new Map<Id, kugo2p__Payment_Profile__c>();

        for (kugo2p__PaymentX__c p : newMap.values()) {
            if(p.kugo2p__SalesOrder__c != null) {
                orderLegacyIds.add(p.kugo2p__SalesOrder__c);
            } else if (p.kugo2p__Payment_Profile__c != null) {
                recurringIds.add(p.kugo2p__Payment_Profile__c);
            } else if (String.isNotEmpty(p.kugo2p__Invoice_Number__c)) {
                orderNames.add(p.kugo2p__Invoice_Number__c);
            } else if (String.isNotEmpty(p.kugo2p__Subscription_Id__c)) {
                subscriptionIds.add(p.kugo2p__Subscription_Id__c);
            }
        }

        if(recurringIds.size() > 0) {
            paymentProfileMap = queryOrdersWithProfiles(recurringIds);
        }

        if(orderLegacyIds.size() > 0 || paymentProfileMap.size() > 0 || orderNames.size() > 0 || subscriptionIds.size() > 0) {
            createBoomPayments(orderLegacyIds, paymentProfileMap, newMap, orderNames, subscriptionIds, true);
        }


    }


    public static Map<Id, kugo2p__Payment_Profile__c> queryOrdersWithProfiles(Set<String> recurringIds) {
        Map<Id, kugo2p__Payment_Profile__c> orderMap = new Map<Id, kugo2p__Payment_Profile__c>([
              SELECT kugo2p__SalesOrder__c
              FROM kugo2p__Payment_Profile__c
              WHERE Id IN :recurringIds
              AND kugo2p__SalesOrder__c != null
        ]);

        
        return orderMap;
    }

    public static void createBoomPayments(Set<String> orderIds, Map<Id, kugo2p__Payment_Profile__c> profileMap, Map<Id, kugo2p__PaymentX__c> payments, Set<String> boomOrderNames, Set<String> subscriptionIds, Boolean isUpdate) {
        Map<String, SalesOrder__c> boomOrderMap = generateBoomOrderMap(subscriptionIds, boomOrderNames, orderIds, profileMap.keySet());
        List<Payment__c> boomPayments = new List<Payment__c>();
        Map<String, Id> boomPaymentMap = new Map<String, Id>();

        if(isUpdate) {
            boomPaymentMap = generateBoomPaymentMap((List<String>) new List<Id>(payments.keySet()));
        }
        
        for(kugo2p__PaymentX__c k : payments.values()) {
            Payment__c bp = generateBoomPayment(k);
            SalesOrder__c bso = new SalesOrder__c();

            if(k.kugo2p__SalesOrder__c != null && boomOrderMap.containsKey(k.kugo2p__SalesOrder__c)) {
                bso = boomOrderMap.get(k.kugo2p__SalesOrder__c);
            } else if(k.kugo2p__Payment_Profile__c != null && profileMap.containsKey(k.kugo2p__Payment_Profile__c)) {
                kugo2p__Payment_Profile__c prof = profileMap.get(k.kugo2p__Payment_Profile__c);
                if(prof.kugo2p__SalesOrder__c != null && boomOrderMap.get(prof.kugo2p__SalesOrder__c) != null) {
                    bso = boomOrderMap.get(prof.kugo2p__SalesOrder__c);
                }
            } else if (String.isNotEmpty(k.kugo2p__Invoice_Number__c) && boomOrderMap.containsKey(k.kugo2p__Invoice_Number__c)) {
                bso = boomOrderMap.get(k.kugo2p__Invoice_Number__c);
            } else if(String.isNotEmpty(k.kugo2p__Subscription_Id__c) && boomOrderMap.containsKey(k.kugo2p__Subscription_Id__c)) { 
                bso = boomOrderMap.get(k.kugo2p__Subscription_Id__c);
            } else {
                continue;
            }

            bp.Sales_Order__c = bso.Id;

            if(!bp.Name.contains(bso.Name)) {
                if(bp.Name.contains('Recurring')) {
                    bp.Name = 'Recurring Payment for ' + bso.Name;
                } else {
                    bp.Name = 'Payment for ' + bso.Name;
                }
            }

            if(bp.Contact__c == null && bso.ContactBilling__c != null) {
                bp.Contact__c = bso.ContactBilling__c;
                bp.Billing_Name__c = bso.ContactBilling__r.FirstName + ' ' + bso.ContactBilling__r.LastName;
            }

            if(bp.Account__c == null && bso.Account__c != null) {
                bp.Account__c = bso.Account__c;
            }

            if(isUpdate && boomPaymentMap.containsKey((String) k.Id)) {
                bp.Id = boomPaymentMap.get((String) k.Id);
            }

            boomPayments.add(bp);
        }

        if(boomPayments.size() > 0) {
            upsert boomPayments;
        }
    }


    public static Map<String, Id> generateBoomPaymentMap(List<String> payments) {
        Map<Id, Payment__c> boomPayments = new Map<Id, Payment__c>([
            SELECT Id,Legacy_Id__c FROM Payment__c WHERE Legacy_Id__c IN :payments
        ]);

        Map<String, Id> boomPaymentMap = new Map<String, Id>();
        for(Payment__c bp : boomPayments.values()) {
            boomPaymentMap.put(bp.Legacy_Id__c, bp.Id);
        }

        return boomPaymentMap;
    }



    public static Map<String, SalesOrder__c> generateBoomOrderMap(Set<String> subscriptionIds, Set<String> boomOrderNames, Set<String> orderIds, Set<Id> profileIds) {

        if(profileIds.size() > 0) {
            Map<Id, kugo2p__SalesOrder__c> kugoOrderMap = new Map<Id, kugo2p__SalesOrder__c>([
                SELECT Id
                FROM kugo2p__SalesOrder__c
                WHERE Id IN (
                    SELECT kugo2p__SalesOrder__c
                    FROM kugo2p__Payment_Profile__c
                    WHERE Id IN :profileIds
                    AND kugo2p__SalesOrder__c != null
                )
            ]);

            orderIds.addAll(new Set<String>( (List<String>) new LIst<Id> (kugoOrderMap.keySet())));
        }

        List<SalesOrder__c> boomOrders = [
            SELECT Id,Legacy_Id__c,Name,ContactBilling__c,Account__c,ContactBilling__r.FirstName,ContactBilling__r.LastName,Subscription_Id__c
            FROM SalesOrder__c
            WHERE Legacy_Id__c IN :orderIds
            OR Name IN :boomOrderNames
            OR Subscription_Id__c IN :subscriptionIds
        ];

        Map<String, SalesOrder__c> boomOrderMap = new Map<String, SalesOrder__c>();
        for(SalesOrder__c order : boomOrders) {
            if(String.isNotEmpty(order.Legacy_Id__c)) {
                boomOrderMap.put(order.Legacy_Id__c, order);
            } else if(String.isNotEmpty(order.Subscription_Id__c)) {
                boomOrderMap.put(order.Subscription_Id__c, order);
            } else {
                boomOrderMap.put(order.Name, order);
            }
        }

        return boomOrderMap;
    }

    public static Payment__c generateBoomPayment(kugo2p__PaymentX__c k) {
        Payment__c p = new Payment__c(
            Legacy_Id__c = k.Id,
            Name = k.Name,
            Memo__c = 'Subscription Id:' + k.kugo2p__Subscription_Id__c + '\n\n' + k.kugo2p__Memo__c,
            Ship_To_State__c = k.kugo2p__Ship_To_State__c,
            Ship_To_Country__c = k.kugo2p__Ship_To_Country__c,
            Ship_To_City__c = k.kugo2p__Ship_To_City__c,
            Legacy_Last_Four__c = k.kugo2p__Last_4_Digits__c,
            Transaction_Id__c = k.kugo2p__Transaction_Id__c,
            Tax_Calc_Result__c = k.kugo2p__Tax_Calc_Result__c,
            Shipping_Calc_Result__c= k.kugo2p__Shipping_Calc_Result__c,
            Invoice_Number__c = k.kugo2p__Invoice_Number__c,
            Batch_Processing_Result__c = k.kugo2p__Batch_Processing_Result__c,
            Authorization_Id__c = k.kugo2p__Authorization_Id__c,
            Ship_To_Postal_Code__c = k.kugo2p__Ship_To_Postal_Code__c,
            Last_Response_Status__c = k.kugo2p__Last_Response_Status__c,
            Check_Number__c = k.kugo2p__Check_Number__c,
            Ship_To_Name__c = k.kugo2p__Ship_To_Name__c,
            Ship_To_Company__c = k.kugo2p__Ship_To_Company__c,
            Ship_To_Street__c = k.kugo2p__Ship_To_Street__c,
            Transaction_Type__c = k.kugo2p__Transaction_Type__c == 'Credit' ? 'Refund' : k.kugo2p__Transaction_Type__c,
            Tax_Method__c = k.kugo2p__Tax_Method__c,
            Status__c = k.kugo2p__Status__c,
            Shipping_Method__c = k.kugo2p__Shipping_Method__c,
            Payment_Type__c = k.kugo2p__Payment_Type__c,
            Payment_Processor__c = k.kugo2p__Payment_Processor__c,
            Currency_ISO_Code__c = k.kugo2p__Currency_ISO_Code__c,
            Legacy_Card_Type__c = k.kugo2p__Card_Type__c,
            Batch_Processing_Action__c = k.kugo2p__Batch_Processing_Action__c,
            Ship_To_Phone__c = k.kugo2p__Ship_To_Phone__c,
            Scheduled_Payment_Number__c = k.kugo2p__Scheduled_Payment_Number__c,
            Processing_Action_Lead_Time__c = k.kugo2p__Processing_Action_Lead_Time__c,
            Shipping__c = k.kugo2p__Shipping__c,
            Contact__c = k.kugo2p__Contact__c,
            Account__c = k.kugo2p__Account__c,
            Merchant_Custom_Data__c = k.kugo2p__Merchant_Custom_Data__c,
            Log__c = k.kugo2p__Log__c,
            Auth_Expiration__c = k.kugo2p__Auth_Expiration__c,
            Deposit_Date__c = k.Deposit_Date__c,
            Scheduled_Payment_Date__c = k.kugo2p__Scheduled_Payment_Date__c,
            Date__c = k.kugo2p__Date__c,
            Transaction_Fee__c = k.kugo2p__Transaction_Fee__c,
            Tax__c = k.kugo2p__Tax__c,
            Discount__c = k.kugo2p__Discount__c,
            Auth_Amount__c = k.kugo2p__Auth_Amount__c,
            Amount__c = k.kugo2p__Amount__c,
            Activity_Created__c = k.Activity_Created__c,
            Reschedule__c= k.kugo2p__Reschedule__c,
            Is_Test_Transaction__c = k.kugo2p__Is_Test_Transaction__c,
            Connection_Error__c = k.kugo2p__Connection_Error__c
        );

        return p;
        
    }



    


}