global with sharing class ScheduleBatchApex implements Schedulable {
global void execute(SchedulableContext sc) {
  // ID BatchId = Database.executeBatch(new ScheduledOrderMaintenance(), 200);
}
 
Public static void SchedulerMethod() {
  string timeinterval = '0 15 * * * ?';
  System.schedule('ReleaseOrders-Every15mins',timeinterval, new ScheduleBatchApex());
  }
}