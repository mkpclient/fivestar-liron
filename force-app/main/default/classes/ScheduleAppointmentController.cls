public class ScheduleAppointmentController {
    public string IdOpp {get;set;}
    public string fullInk;
    private final Opportunity o;
    
    public ScheduleAppointmentController(ApexPages.StandardController stdController) {
        this.o = (Opportunity)stdController.getRecord();
    }

    public PageReference btnRedirection()
    {
        Opportunity opp = [select Full_Ink__c from Opportunity where Id =: ApexPages.currentPage().getParameters().get('id')];
        PageReference retURL = new PageReference(opp.Full_Ink__c);
        retURL.setRedirect(true);
        
       	return opp.Full_Ink__c.tolowercase().startsWith('http') ?  retURL : null ;
       
    }
}