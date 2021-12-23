public class OppContactDataTriggerHelper {
  public static void updateContactFromOpp(List<Opportunity> lstOpportunity) {
    List<Contact> lstContactToUpdate = new List<Contact>();
    // for (Opportunity opp : lstOpportunity) {
    //   if (opp.Pardot_Campaign_Type__c == 'Post-market')
    //     lstContactToUpdate.add(PopulatePostDetails(opp));
    //   if (opp.Pardot_Campaign_Type__c == 'Core')
    //     lstContactToUpdate.add(PopulateCoreDetails(opp));
    // }
    // if (lstContactToUpdate.size() > 0)
    //   update lstContactToUpdate;
  }
  private static Contact PopulateCoreDetails(Opportunity opp) {
    Contact con = new Contact();
    con.Id = opp.Contact__c;
    con.Core_AG_link_NP_MS__c = opp.AG_link_no_price_MS__c;
    con.Core_AG_link_NP_WF__c = opp.AG_link_no_price_WF__c;
    con.Core_AG_link_NP__c = opp.AG_link_no_price__c;
    con.Core_AG_link__c = opp.Company_Specific_AG__c;
    con.Core_Alternative_segment__c = opp.Alternative_Segment__c;
    con.Core_Client_type__c = opp.Client_Type__c;
    con.Core_Close_date__c = getFormattedDate(opp.Market_Close_Date__c);
    con.Core_Issue_s__c = opp.Email_Templates_Issue_s__c;
    con.Core_Last_year_link__c = opp.Email_Templates_Magazine_Section__c;
    con.Core_Magazine_name__c = opp.Email_Templates_Magazine__c;
    con.Core_Magazine_readership__c = string.ValueOf(
      opp.Magazine_Readership__c
    );
    con.Core_Magazine_website__c = opp.Magazine_Website__c;
    con.Core_Market_Sales_Stop_Date__c = getFormattedDate(
      opp.Market_Sales_Stop_Date__c
    ); //string.ValueOf(opp.Market_Sales_Stop_Date__c);
    con.Core_Market_city__c = opp.Email_Templates_Market_City__c;
    con.Core_Market_project__c = opp.Market_Name__c;
    con.Core_Opp_stage_comments__c = opp.Stage_Comment__c;
    con.Core_Opportunity_owner_full_name__c = opp.Opportunity_Owner_Full_Name__c;
    con.Core_Opportunity_owner_email__c = opp.Opportunity_Owner_Email__c;
    con.Core_Opportunity_owner_phone__c = opp.Opportunity_Owner_Phone__c;
    con.Core_Opportunity_stage__c = opp.StageName;
    con.Core_Profession__c = opp.Email_Templates_Profession__c;
    con.Core_Publication_month__c = opp.Publication_Month__c;
    con.Core_Publication_year__c = opp.Email_Templates_Publication_Year__c;

    return con;
  }
  private static Contact PopulatePostDetails(Opportunity opp) {
    Contact con = new Contact();
    con.Id = opp.Contact__c;
    con.Post_market_AG_link_NP_MS__c = opp.AG_link_no_price_MS__c;
    con.Post_market_AG_link_NP_WF__c = opp.AG_link_no_price_WF__c;
    con.Post_market_AG_link_NP__c = opp.AG_link_no_price__c;
    con.Post_market_AG_link__c = opp.Company_Specific_AG__c;
    con.Post_market_Alternative_segment__c = opp.Alternative_Segment__c;
    con.Post_market_Client_type__c = opp.Client_Type__c;
    con.Post_market_Close_date__c = string.ValueOf(opp.Market_Close_Date__c);
    con.Post_market_Issue_s__c = opp.Email_Templates_Issue_s__c;
    con.Post_market_Last_year_link__c = opp.Email_Templates_Magazine_Section__c;
    con.Post_market_Magazine_name__c = opp.Email_Templates_Magazine__c;
    con.Post_market_Magazine_readership__c = string.ValueOf(
      opp.Magazine_Readership__c
    );
    con.Post_market_Magazine_website__c = opp.Magazine_Website__c;
    //con.Core_Market_Sales_Stop_Date__c= string.ValueOf(opp.Market_Sales_Stop_Date__c);
    con.Post_market_Market_city__c = opp.Email_Templates_Market_City__c;
    con.Post_market_Market_project__c = opp.Market_Name__c;
    con.Post_market_Opp_stage_comments__c = opp.Stage_Comment__c;
    con.Post_market_Opportunity_owner_name__c = opp.Opportunity_Owner_Full_Name__c;
    con.Post_market_Opportunity_owner_email__c = opp.Opportunity_Owner_Email__c;
    con.Post_market_Opportunity_owner_name__c = opp.Opportunity_Owner_Full_Name__c;
    con.Post_market_Opportunity_owner_phone__c = opp.Opportunity_Owner_Phone__c;
    con.Post_market_Opportunity_stage__c = opp.StageName;
    con.Post_market_Profession__c = opp.Email_Templates_Profession__c;
    con.Post_market_Publication_month__c = opp.Publication_Month__c;
    con.Post_market_Publication_year__c = opp.Email_Templates_Publication_Year__c;
    con.amreg_code__c = opp.amreg_code__c;
    return con;
  }

  private static String getFormattedDate(Date datefield) {
    if (datefield == null)
      return '';
    Map<Integer, String> monthNameMap = new Map<Integer, String>{
      1 => 'January',
      2 => 'February',
      3 => 'March',
      4 => 'April',
      5 => 'May',
      6 => 'June',
      7 => 'July',
      8 => 'August',
      9 => 'September',
      10 => 'October',
      11 => 'November',
      12 => 'December'
    };
    Datetime dt = DateTime.newInstance(datefield, Time.newInstance(0, 0, 0, 0));
    String dayOfWeek = dt.format('EEEE');
    String monthName = dt.format('MMMMM');
    integer Day = datefield.day();
    integer year = datefield.Year();

    return dayOfWeek + ', ' + monthName + ' ' + Day + ', ' + year;
  }
  /*  public static void sendEmail(List < Opportunity > lstOppsToSendEmail) {

      List < EmailTemplate > et = new List < EmailTemplate > ();
      if (Schema.sObjectType.EmailTemplate.isAccessible()) {
       et = [
        SELECT Id, HTMLValue
        FROM EmailTemplate
        WHERE DeveloperName = 'Buyer_No_Interest_Survey'
       ];
      }
    
      //loop through and build emails for the orders
      List < Messaging.SingleEmailMessage > emailList = new List < Messaging.SingleEmailMessage > ();
    
      for (Opportunity opp: lstOppsToSendEmail) {
    
       //otherwise send 1 email per order
       Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    
       List < String > recipients = new List < String > ();
       recipients.add('sakethasfmc@gmail.com');
       recipients.add('greg.thatcher@fivestarprofessional.com');
       recipients.add('mdazer@salesforce.com');
       
       email.setToAddresses(recipients);
       system.debug('To addresses are ' + recipients);
       if(!Test.isRunningTest())
            email.setTemplateId(et[0].Id);
       else
       {
           email.setHtmlBody('Test');
       }
       email.setWhatId(opp.Id);
       //email.RelatedToId= anOrder.Id;
       email.setTreatTargetObjectAsRecipient(false);
       if (opp.Contact__c != null) {
    
        email.setTargetObjectId(opp.Contact__c);
    
       }
    
       emailList.add(email);
      }
      system.debug('Emails==='+emailList);
      Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
    
    system.debug('results ==='+results );
    
    
     } */
}