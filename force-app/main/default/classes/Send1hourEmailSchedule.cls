global class Send1hourEmailSchedule implements Schedulable {
   global void execute(SchedulableContext sc) {
      ProcessOppNextcallDateAndEmail b = new ProcessOppNextcallDateAndEmail(); 
      database.executebatch(b);
   }
}