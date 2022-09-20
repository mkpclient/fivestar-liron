trigger onFulfillmentUpdated on Fulfillment__c (after update) {

    // if(Test.isRunningTest() ||( Limits.getFutureCalls() >= Limits.getLimitFutureCalls())){
	if(( Limits.getFutureCalls() >= Limits.getLimitFutureCalls() || System.isFuture() || System.isBatch())){
   		system.debug(LoggingLevel.Error, 'Future method limit reached. Skipping WebappNotifyService');
        return;
    }

    system.debug('onFulfillmentUpdated:');
    // system.debug(Trigger.newMap.keySet());

    List<String> ids = new List<String>();

    for (String key: Trigger.newMap.keySet()){
        ids.add(key);
    }    
    
    WebappNotifyService.notifyFulfillmentUpdated(ids);
}