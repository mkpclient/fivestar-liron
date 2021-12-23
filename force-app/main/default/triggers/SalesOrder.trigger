trigger SalesOrder on kugo2p__SalesOrder__c (before insert, before update, after update) {

  // if (trigger.isBefore && trigger.isInsert) {
  //   // Five Star changes - FS04
  //   FiveStarHelper.resetOrderFinanceTerm(trigger.new);
  //   FiveStarHelper.resetOrderReleaseDates(trigger.new);

  //   FiveStarHelper.assignMarket(trigger.new);
  // }

  // /**
  //  * @author MK Partners
  //  * @description Fix auto release issue
  //  */ 
  // if ( trigger.isBefore && trigger.isUpdate ){
  //   FiveStarHelper.beforeUpdate(Trigger.new, Trigger.old);
  // }

  // if (trigger.isAfter && trigger.isUpdate) {
  //   if(!FiveStarHelper.processingOrderInvoiceEmailSchedule || Test.isRunningTest()) {
  //     FiveStarHelper.scheduleSendEmailClass(trigger.new, trigger.oldMap);
  //   }         
  //   System.debug('before calling auto release order');
  //   // FiveStarHelper.autoReleaseOrder(trigger.new);
  //   System.debug('after executing the auto release order');

  //   FiveStarHelper.updateLockedPriceLineDiscount(trigger.newMap, trigger.oldMap);

  //   FiveStarHelper.fulFillOrders(trigger.newMap, trigger.oldMap);
    
  //   // Rollback changes from production by Parvathi Chunduri 11/5/2020
  //   // PriceUpdateHelper.updatePrice(trigger.new);
  // }
}