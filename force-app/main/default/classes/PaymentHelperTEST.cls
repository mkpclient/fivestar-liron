@istest(seeAllData = true)
public with sharing class PaymentHelperTEST {
    @istest
    static void creating_a_payment() {
        kugo2p__SalesOrder__c so = [SELECT Id FROM kugo2p__SalesOrder__c LIMIT 1];

        kugo2p__paymentX__c newPayment = new kugo2p__paymentX__c();
        newPayment.kugo2p__SalesOrder__c = so.Id;
        insert newPayment;

        delete newPayment;
    }
}