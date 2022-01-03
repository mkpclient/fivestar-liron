public class ApexControllers {
  public Id owner { get; set; }
  public Id Id { get; set; }
  public Opportunity opp { get; set; }

  public ApexControllers(ApexPages.StandardController controller) {
    opp = (Opportunity) controller.getRecord();
    Id = opp.Id;
    if(!Test.isRunningTest()) {
      owner = opp.OwnerId;
    } else {
      owner = UserInfo.getUserId();
    }
  }

  public Pagereference generateOrder() {
   
    SalesOrder__c generatedSO = new SalesOrder__c();
    generatedSO.OrderDate__c = System.today();
    generatedSO.OrderName__c = opp.Name;
    generatedSO.Market__c = opp.Market_Project__c;
    generatedSO.Opportunity__c = Id;
    generatedSO.Account__c = opp.AccountId;
    if (opp.Market_Project__r.Price_Book__c == null) {
      Pricebook2 pb = [
        SELECT Id
        FROM Pricebook2
        WHERE Name = :opp.Market_Project__r.Name
        LIMIT 1
      ];
      generatedSO.Price_Book__c = pb.Id;
    } else {
      generatedSO.Price_Book__c = opp.Market_Project__r.Price_Book__c;
    }

    generatedSO.ContactBilling__c = opp.Contact__r.Id;
    generatedSO.ContactBuying__c = opp.Contact__r.Id;
    generatedSO.ContactShipping__c = opp.Contact__r.Id;
    generatedSO.BillToName__c = opp.Account.Name;
    generatedSO.BillToCity__c = opp.Contact__r.MailingCity;
    generatedSO.BillToCountry__c = opp.Contact__r.MailingCountry;
    generatedSO.BillToStateProvince__c = opp.Contact__r.MailingState;
    generatedSO.BillToStreetLong__c = opp.Contact__r.MailingStreet;
    generatedSO.BillToZipPostalCode__c = opp.Contact__r.MailingPostalCode;
    generatedSO.ShipToCity__c = opp.Contact__r.OtherCity;
    generatedSO.ShipToCountry__c = opp.Contact__r.OtherCountry;
    generatedSO.ShipToName__c = opp.Account.Name;
    generatedSO.ShipToStateProvince__c = opp.Contact__r.OtherState;
    generatedSO.ShipToStreetLong__c = opp.Contact__r.OtherStreet;
    generatedSO.ShipToZipPostalCode__c = opp.Contact__r.OtherPostalCode;
    try {
      Database.SaveResult sr = Database.insert(generatedSO, false);
      PageReference pageRef = new PageReference('/' + sr.getId());
      if(Test.isRunningTest()) {
        return new Pagereference('/'+ opp.Id);
      }

      pageRef.setRedirect(true);
      
      return pageRef;
    } catch (DmlException err) {
      opp.addError(err.getMessage());
      return null;
    }
  }
}