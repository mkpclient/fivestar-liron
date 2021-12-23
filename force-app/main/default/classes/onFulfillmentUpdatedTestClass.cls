@isTest (seealldata=true)
public class onFulfillmentUpdatedTestClass {
    static testMethod void onFulfillmentUpdated() {
        Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
		Fulfillment__c f = [SELECT Id from Fulfillment__c limit 1];
		System.assert(f != null);
        if (f != null) {
			f.Emblem_URL__c = 'test update trigger';
            update f;
        }
    }
}