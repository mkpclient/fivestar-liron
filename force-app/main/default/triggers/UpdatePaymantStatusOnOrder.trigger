trigger UpdatePaymantStatusOnOrder on kugo2p__PaymentX__c(after insert,after update) {

Map<id,kugo2p__SalesOrder__c> ordermap = new Map<id,kugo2p__SalesOrder__c>();
List<kugo2p__SalesOrder__c> orderList = new List<kugo2p__SalesOrder__c>();
List<kugo2p__SalesOrderProductLine__c> ordLineList = new List<kugo2p__SalesOrderProductLine__c>();
List<Id> idList = new List<Id>();
    for(kugo2p__PaymentX__c pmt:trigger.new){
        if(pmt.kugo2p__Status__c == 'Completed'){
             idList.add(pmt.kugo2p__SalesOrder__c); 
        }
      
    }
  System.debug('idList>>>>>>>>'+idList);   
  orderList = new List<kugo2p__SalesOrder__c>([Select id,Payment_Status__c from kugo2p__SalesOrder__c where id IN :idList]);  
   List<kugo2p__PaymentX__c> pmtList = new List<kugo2p__PaymentX__c>([Select id,kugo2p__Status__c from kugo2p__PaymentX__c where kugo2p__SalesOrder__c IN :idList]);
    for(kugo2p__PaymentX__c pay:pmtList){
      orderList[0].Payment_Status__c = pay.kugo2p__Status__c;
    }
    
    /*
 ordLineList = new List<kugo2p__SalesOrderProductLine__c>([Select id,kugo2p__SalesPrice__c,kugo2p__AppliedPaymentAmount__c from kugo2p__SalesOrderProductLine__c where kugo2p__SalesOrder__c IN :idList]);  
 System.debug('ordLineList>>>>>>>>'+ordLineList);  
 
  for(kugo2p__SalesOrderProductLine__c line:ordLineList){
      if(line.kugo2p__SalesPrice__c>=0 && line.kugo2p__AppliedPaymentAmount__c==0){
        line.kugo2p__AppliedPaymentAmount__c = line.kugo2p__SalesPrice__c*2;  
      }
        
    }*/
    
 Update orderList;  
 //Update ordLineList;  
     
    
    
}