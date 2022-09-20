trigger SubscriptionTrigger on Subscription__c (before insert, before update, after insert, after update) {
  
  if((FivestarSetting__mdt.getInstance('Universal') != null && FivestarSetting__mdt.getInstance('Universal').Allow_Subscriptions__c) || test.isRunningTest()) {
    if(Trigger.isBefore && Trigger.isInsert) {
      SubscriptionHelper.beforeInsert(Trigger.new);
    }
    
    if(Trigger.isAfter && Trigger.isInsert) {
      SubscriptionHelper.afterInsert(Trigger.newMap);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate) {
      SubscriptionHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
  
    if(Trigger.isBefore && Trigger.isUpdate) {
      SubscriptionHelper.beforeUpdate(Trigger.oldMap, Trigger.newMap);
    }  
  }
}