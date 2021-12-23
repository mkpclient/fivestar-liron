public with sharing class NextBusinessDayAction {
  @InvocableMethod(
    label='3 business days from now'
    description='Today + 3 business days away'
  )
  public static List<Date> getNextBusinessDay() {
    DateTime rightNow = System.now();

    BusinessHours hours = [SELECT Id, Name, IsActive, IsDefault FROM BusinessHours WHERE Name = 'For Flow'];
    System.debug(hours);
    DateTime target = System.now();

    for (Integer i = 0; i < 3; i++) {
      System.debug(BusinessHours.nextStartDate(hours.Id, target.addDays(1)));
      target = BusinessHours.nextStartDate(hours.Id, target.addDays(1));
    }
    
    System.debug(target);
    
    return new List<Date>{ date.newInstance(target.year(), target.month(), target.day()) };
  }
}