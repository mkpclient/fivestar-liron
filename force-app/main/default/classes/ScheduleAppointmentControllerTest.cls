@isTest
public class ScheduleAppointmentControllerTest {
  static testMethod void schedule() {
    test.startTest();

    Account acc = new Account();
    acc.Name = 'testContact';
    insert acc;

    Contact con = new Contact();
    con.AccountId = acc.Id;
    con.FirstName = 'Test Name';
    con.LastName = 'Test Last';
    insert con;

    Market__c mark = new Market__c();
    mark.Name = 'Test';
    mark.Market_Close_Date__c = System.today().addDays(30);
    insert mark;

    Opportunity testOppty = new Opportunity();
    testOppty.name = 'testOppty';
    testOppty.AccountId = acc.id;
    testOppty.Contact__c = con.id;
    testOppty.StageName = 'Open';
    testOppty.CloseDate = System.today();
    testOppty.Market_Project__c = mark.Id;
    insert testOppty;

    PageReference pageRef = Page.ScheduleAppointment;
    Test.setCurrentPage(pageRef);
    pageRef.getParameters().put('id', testOppty.id);
    ApexPages.StandardController sc = new ApexPages.standardController(
      testOppty
    );

    ScheduleAppointmentController controller = new ScheduleAppointmentController(
      sc
    );
    controller.btnRedirection();
  }
}