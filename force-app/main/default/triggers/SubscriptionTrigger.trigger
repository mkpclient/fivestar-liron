trigger SubscriptionTrigger on Subscription__c (before insert, before update, after insert, after update) {
  if(Trigger.isAfter && Trigger.isInsert) {
    SubscriptionHelper.afterInsert(Trigger.newMap);
  }
}