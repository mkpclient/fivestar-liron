@istest(seealldata=true)
public class SgizURLHandlerTest 
{

  @istest 
  static void test_generate_url() {
    SgizURLHandler.generateURL('Half Page');
    SgizURLHandler.generateURL('Desk');
    SgizURLHandler.generateURL('Announcement');
    SgizURLHandler.generateURL('Postcard');
    SgizURLHandler.generateURL('Ninth Page');
    SgizURLHandler.generateURL('Brochure');
    SgizURLHandler.generateURL('Full Page');
    SgizURLHandler.generateURL('Eighteenth Page');
    SgizURLHandler.generateURL('Single Wall');
    SgizURLHandler.generateURL('Double Wall');
    SgizURLHandler.generateURL('Quarter Page');
    SgizURLHandler.generateURL('Two Page');
    SgizURLHandler.generateURL('Rider Sign');
    SgizURLHandler.generateURL('Magazine Listing');
    SgizURLHandler.generateURL('WSJ Listing');  
    SgizURLHandler.generateURL('Press release');  
    SgizURLHandler.generateURL('WSJ single profile');
    SgizURLHandler.generateURL('Digital ad campaign');
    SgizURLHandler.generateURL('Forbes profile');
    SgizURLHandler.generateURL('Test');  
  }

    // @istest
	// public static void testURL()
  //   {
        
  //       Fulfillment__c f = [select Product_Name__c from Fulfillment__c limit 1];
  //       f.Product_Name__c = 'WSJ Listing';
  //       update f;
        
  //       f.Product_Name__c = 'Desk';
  //       update f;
        
  //       f.Product_Name__c = 'Announcement';
  //       update f;
        
  //       f.Product_Name__c = 'Postcard';
  //       update f;
        
  //       f.Product_Name__c = 'Ninth Page';
  //       update f;
        
  //       f.Product_Name__c = 'Brochure';
  //       update f;
        
  //       f.Product_Name__c = 'Full Page';
  //       update f;
        
  //       f.Product_Name__c = 'Eighteenth Page';
  //       update f;
        
  //       f.Product_Name__c = 'Single Wall';
  //       update f;
        
  //       f.Product_Name__c = 'Double Wall';
  //       update f;
        
  //       f.Product_Name__c = 'Quarter Page';
  //       update f;
        
  //       f.Product_Name__c = 'Two Page';
  //       update f;
        
  //       f.Product_Name__c = 'Rider Sign';
  //       update f;
        
  //       f.Product_Name__c = 'Magazine Listing';
  //       update f;
        
  //       f.Product_Name__c = 'Half Page';
  //       update f;

  //       f.Product_Name__c = 'Test';
  //       update f;
        
  //       f.Product_Name__c = 'Press release';
  //       update f;
        
  //       f.Product_Name__c = 'WSJ single profile';
  //       update f;
        
  //       f.Product_Name__c = 'WSJ double profile';
  //       update f;
        
  //       f.Product_Name__c = 'Digital ad campaign';
  //       update f;
        
  //       f.Product_Name__c = 'Forbes profile';
  //       update f;
  //   }
}