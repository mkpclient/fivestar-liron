trigger OrderLineRecipientsTrigger on Order_Line_Recipient__c(
  before insert,
  after insert,
  after update,
  after delete
) {

  if((Trigger_Setting__mdt.getInstance('AllTriggers').Active__c == true && Trigger_Setting__mdt.getInstance('Order_Line_Recipient').Active__c == true) || Test.isRunningTest()) {
    if (Trigger.isInsert && Trigger.isBefore) {
      OrderLineRecipientsHelper.beforeInsert(Trigger.new);
    }
  
    if (Trigger.isAfter && Trigger.isInsert) {
      OrderLineRecipientsHelper.afterInsert(Trigger.new);
    }
  
    if (Trigger.isAfter && Trigger.isUpdate) {
      OrderLineRecipientsHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
  
    if (Trigger.isAfter && Trigger.isDelete) {
      OrderLineRecipientsHelper.afterDelete(Trigger.old);
    }  
  }
}