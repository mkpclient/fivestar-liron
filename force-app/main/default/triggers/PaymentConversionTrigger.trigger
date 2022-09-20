trigger PaymentConversionTrigger on kugo2p__PaymentX__c (after insert, after update) {

  if(Trigger.isAfter && Trigger.isInsert) {
    PaymentConversionTriggerHelper.afterInsert(Trigger.newMap);
  }

  if(Trigger.isAfter && Trigger.isUpdate) {
    PaymentConversionTriggerHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
  }

}