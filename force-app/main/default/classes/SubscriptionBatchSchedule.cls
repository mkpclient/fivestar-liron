global class SubscriptionBatchSchedule implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        if((FivestarSetting__mdt.getInstance('Universal') != null 
        && FivestarSetting__mdt.getInstance('Universal').Allow_Subscription_Payments__c) 
        || test.isRunningTest()) {
            SubscriptionOrdersBatch batch = new SubscriptionOrdersBatch();
            database.executebatch(batch, 1);
        }

        if((
            FivestarSetting__mdt.getInstance('Universal') != null
            && FivestarSetting__mdt.getInstance('Universal').Allow_Subscriptions__c
        ) || test.isRunningTest()) {
            database.executeBatch(new SubscriptionStatusBatch(), 100);
        }
    }
   
}