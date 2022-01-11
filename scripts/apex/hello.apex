
List<SalesOrder__c> orders = [SELECT Opportunity__r.Name, PriceBookName__c , Price_Book__c, Id from salesorder__c where Price_Book__c = null AND Status_Picklist__c != 'Released' AND Status_Picklist__c!='Approved' LIMIT 200 FOR UPDATE];
Map<String, Id> pricebookMap = new Map<String,Id>();

for(SalesOrder__c o : orders) {
  if(!pricebookMap.containsKey(o.PriceBookName__c)) {
    pricebookMap.put(o.PriceBookName__c, null);
  }
}

List<Pricebook2> pbs = [
        SELECT Id, Name
        FROM Pricebook2
        WHERE Name IN :pricebookMap.keySet()
      ];

for(Pricebook2 pb : pbs) {
  pricebookMap.put(pb.Name, pb.Id);
}

for(SalesOrder__c o : orders) {
  if(pricebookMap.containsKey(o.PriceBookName__c) && pricebookMap.get(o.PriceBookName__c) != null) {
    o.Price_Book__c = pricebookMap.get(o.PriceBookName__c);
  }
}

update orders;


/** 
 * 
for i in {1..1}
do
sfdx force:apex:execute --loglevel ERROR --apexcodefile '/Volumes/LaCie/Salesforce/FIVESTAR GITTED/FIVESTAR/scripts/apex/hello.apex'
done
echo "completed"

 */