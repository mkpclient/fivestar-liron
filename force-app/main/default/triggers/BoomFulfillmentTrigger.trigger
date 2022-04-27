trigger BoomFulfillmentTrigger on Fulfillment__c (after insert) {
  if((FivestarSetting__mdt.getInstance('Universal') != null && FivestarSetting__mdt.getInstance('Universal').Allow_Subscriptions__c) || test.isRunningTest()) {
    if(Trigger.isAfter && Trigger.isInsert) {
      BoomFulfillmentHelper.afterInsert(Trigger.newMap);
    }
  }
}