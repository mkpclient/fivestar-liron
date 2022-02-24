List<Payment_Method__c> pms = [SELECT Id FROM Payment_Method__c WHERE Active__c != true AND Inactive__c != true LIMIT 200];

for(Payment_Method__c p : pms) {
    p.Inactive__c = true;
}

update pms;
/** 
 * 
for i in {1..5}
do
sfdx force:apex:execute --loglevel ERROR --apexcodefile '/Users/lirondecastro/Salesforce/FIVESTAR GITTED/FIVESTAR/scripts/apex/hello.apex'
done
echo "completed"

 */