trigger MarketNewTrigger on Market__c (after insert, after update) {
  if(Trigger.isAfter && Trigger.isInsert) {
    MarketNewTriggerHelper.afterInsert(Trigger.newMap);
  }
  if(Trigger.isAfter && Trigger.isUpdate) {
    MarketNewTriggerHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
  }
}