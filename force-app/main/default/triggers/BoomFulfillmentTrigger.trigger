trigger BoomFulfillmentTrigger on Fulfillment__c (after insert) {
  if(Trigger.isAfter && Trigger.isInsert) {
    BoomFulfillmentHelper.afterInsert(Trigger.newMap);
  }
}