global class PaymentBatchSchedule implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        PaymentBatchable p = new PaymentBatchable();
        database.executebatch(p, 100);
    }
   
}