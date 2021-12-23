// Author   : Henry Caballero - hdcaballero@gmail.com
// Date     : 4/18/2017
trigger FulfillmentTrigger on Fulfillment__c (before insert, before update) 
{
    if (trigger.isUpdate && trigger.isBefore)
    {
        SgizURLHandler.updateURL(trigger.new);
    }
}