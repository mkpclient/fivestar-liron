public without sharing class kugo2p_AppliedPayment_Queueable implements Queueable {
  public List<kugo2p__AppliedPayment__c> appliedPayments;

  public void execute(QueueableContext context) {
    touchAppliedPaymentsToStartLogic(appliedPayments);
  }

  public static void touchAppliedPaymentsToStartLogic(List<kugo2p__AppliedPayment__c> appliedPayments){
    List<kugo2p__AppliedPayment__c> updateFirst = new List<kugo2p__AppliedPayment__c>();
    List<kugo2p__AppliedPayment__c> updateSecond = new List<kugo2p__AppliedPayment__c>();
    for ( Integer i=0;i<appliedPayments.size();i++){
      kugo2p__AppliedPayment__c p1 = new kugo2p__AppliedPayment__c(
        Id=appliedPayments[i].Id,
        kugo2p__SalesOrder__c = null
      );
      updateFirst.add(p1);
      kugo2p__AppliedPayment__c p2 = new kugo2p__AppliedPayment__c(
        Id=appliedPayments[i].Id,
        kugo2p__SalesOrder__c = appliedPayments[i].kugo2p__SalesOrder__c
      );
      updateSecond.add(p2);
    }
    update updateFirst;
    update updateSecond;
  }

}