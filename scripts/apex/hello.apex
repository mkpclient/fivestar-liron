
List<SalesOrder__c> orders = [SELECT Id FROM SalesOrder__c WHERE Net_Due__c = -14];


List<SalesOrderAdditionalChargeCredit__c> soaccs = new List<SalesOrderAdditionalChargeCredit__c>();
String shippingId = 'a5X6T00000IrsqK';

for(SalesOrder__c s : orders) {
  SalesOrderAdditionalChargeCredit__c oc = new SalesOrderAdditionalChargeCredit__c();
  oc.SalesOrder__c = s.Id;
  oc.Quantity__c = 1;
  oc.SalesPrice__c = 14;
  oc.Additional_Charge_Credit__c = shippingId;
  soaccs.add(oc);
}

update soaccs;

/** 
 * 
for i in {1..22}
do
sfdx force:apex:execute --loglevel ERROR --apexcodefile '/Volumes/LaCie/Salesforce/FIVESTAR GITTED/FIVESTAR/scripts/apex/hello.apex'
done
echo "completed"

 */