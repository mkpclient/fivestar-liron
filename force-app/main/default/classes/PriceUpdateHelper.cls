public class PriceUpdateHelper {
    
    public static void updatePrice(list<kugo2p__SalesOrder__c> salesOrders) {
        if (salesOrders != null && !salesOrders.isEmpty()) {
            List<Id> idList = new List<Id>();
            List<kugo2p__SalesOrderProductLine__c> ordLineList = new List<kugo2p__SalesOrderProductLine__c>();
            List<kugo2p__SalesOrderAdditionalChargeCredit__c> addChargeList = new List<kugo2p__SalesOrderAdditionalChargeCredit__c>();
            System.debug('beforePayment>>>>>>>>'+salesOrders);  
            for(kugo2p__SalesOrder__c salesOrder : salesOrders){
                if(salesOrder.Payment_Status__c == 'Completed'){
                    idList.add(salesOrder.id);
                }
            }
            System.debug('beforePaymentFilter>>>>>>>>'+idList); 
            ordLineList = new List<kugo2p__SalesOrderProductLine__c>([Select id,Actual_Price__c,kugo2p__AppliedPaymentAmount__c from kugo2p__SalesOrderProductLine__c where kugo2p__SalesOrder__c IN :idList]);  
            System.debug('ordLineList>>>>>>>>'+ordLineList);  
            addChargeList = new List<kugo2p__SalesOrderAdditionalChargeCredit__c>([Select id,kugo2p__SalesPrice__c,kugo2p__AppliedPaymentAmount__c from kugo2p__SalesOrderAdditionalChargeCredit__c where kugo2p__SalesOrder__c IN :idList]);
  
           System.debug('addChargeList >>>>>>>>'+addChargeList );
            for(kugo2p__SalesOrderProductLine__c line:ordLineList){
                if(line.Actual_Price__c>=0 && line.kugo2p__AppliedPaymentAmount__c == 0){
                    line.kugo2p__AppliedPaymentAmount__c = line.Actual_Price__c;  
                }
                    
             }
            System.debug('ordLineListAfter>>>>>>>>'+ordLineList); 
            
            for(kugo2p__SalesOrderAdditionalChargeCredit__c charge:addChargeList){
                if(charge.kugo2p__SalesPrice__c>=0 && charge.kugo2p__AppliedPaymentAmount__c==0){
                    charge.kugo2p__AppliedPaymentAmount__c = charge.kugo2p__SalesPrice__c;  
                }
                    
             }
            
                        
             //Update orderList;  
             Update ordLineList; 
             Update addChargeList;
          }
    }

}