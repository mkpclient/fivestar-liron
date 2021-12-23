trigger kugo2p_AppliedPaymentTrigger on kugo2p__AppliedPayment__c (after insert) {
  kugo2p_AppliedPayment_Queueable q = new kugo2p_AppliedPayment_Queueable();
  q.appliedPayments = Trigger.new;
  ID jobID = System.enqueueJob(q);
}