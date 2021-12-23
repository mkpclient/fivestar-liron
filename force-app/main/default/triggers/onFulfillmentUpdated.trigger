trigger onFulfillmentUpdated on Fulfillment__c (after update) {

    // if(Test.isRunningTest() ||( Limits.getFutureCalls() >= Limits.getLimitFutureCalls())){
	if(( Limits.getFutureCalls() >= Limits.getLimitFutureCalls())){
   		system.debug(LoggingLevel.Error, 'Future method limit reached. Skipping WebappNotifyService');
        return;
    }

    system.debug('onFulfillmentUpdated:');
    // system.debug(Trigger.newMap.keySet());

    List<String> ids = new List<String>();

    Map<Id, Fulfillment__c> newMap = Trigger.newMap;
    Map<Id, Fulfillment__c> oldMap = Trigger.oldMap;

    for (String key: newMap.keySet()){
        if(newMap.get(key).Boom_Order__c == null && oldMap.get(key).Boom_Order__c == null){
            ids.add(key);
        }
    }    
    
    if(ids.size() > 0) {
        WebappNotifyService.notifyFulfillmentUpdated(ids);
    }
}