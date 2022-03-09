global class PaymentMethodSchedule implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        PaymentMethodBatch p = new PaymentMethodBatch();
        database.executebatch(p, 100);
    }
   
}