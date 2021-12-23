public with sharing class ManageRecipientController {

	private Id marketId;
	private String publicationYear = '';
	private String recipientLimit;
	private decimal quantity;

	public boolean isSuccess {get; set;}
	public String productName{get; set;}
	public String selectedPrimaryRecipientId {get; set;}
	public String selectedPrimaryRecipientIdInitial;
	public String QueryKey {get; set;}
	public ManageRecipientController manageRecipientCon { get { return this; } }
    public transient map<String, String> mapAutoCompleteSourceRecipients {get; set;}
    {
        mapAutoCompleteSourceRecipients = new map<String, String>{};
    }
    public String pcodeSeparator {get; set;}
    {
        pcodeSeparator = ' ~ ';
    }

	public ManageRecipientController(Id pMarketId, String pPublicationYear, String pProductName, String pRecipientLimit, decimal pQuantity, map<Id, String> pMapSelectedRecipients, set<Id> pSetUnselectedRecipients, map<String, String> pmapAutoCompleteSourceRecipients) {
		this.isSuccess = false;
		this.marketId = pMarketId;
		this.publicationYear = pPublicationYear==null ? '' : pPublicationYear;
		this.productName = pProductName;
		this.recipientLimit = pRecipientLimit;
		this.quantity = pQuantity==null ? 0 : pQuantity;
		this.mapSelectedRecipients = pMapSelectedRecipients;
		this.setUnselectedRecipients = pSetUnselectedRecipients;
		this.mapAutoCompleteSourceRecipients = pmapAutoCompleteSourceRecipients;

		copyMap(this.mapSelectedRecipients, mapSelectedRecipientsInitial);

		system.debug(' ### pMapSelectedRecipients in ManageRecipientController constructor ' + pMapSelectedRecipients);
	}

    public list<SelectOption> recipientOptions {
        get {
            if (recipientOptions == null) {
                recipientOptions = new list<SelectOption>();

				//recipientOptions.add(new SelectOption('', '-- None --'));
				if (mapSelectedRecipients != null && !mapSelectedRecipients.isEmpty()) {
					for (Id rid : mapSelectedRecipients.keySet()) {
						recipientOptions.add(new SelectOption(rid, mapSelectedRecipients.get(rid)));
					}
				}
            }
            return recipientOptions;
        }
        set;
    }

	public String selectedItem {get; set;}
	public String selectedValue {get; set;}

    public void addRecipientOption() {
    	system.debug(' ### selectedValue in addRecipientOption ' + selectedValue + ' selectItem ' + selectedItem);
    	recipientOptions.add(new SelectOption(selectedValue, selectedItem));
    	if (String.isBlank(selectedPrimaryRecipientId)) selectedPrimaryRecipientId = selectedValue;	//recipientOptions.size() == 1
    }

    public void removeRecipientOption() {
    	system.debug(' ### selectedValue in removeRecipientOption ' + selectedValue);
    	//recipientOptions.remove(selectedValue);
    	list<SelectOption> recipientOptionsTemp = new list<SelectOption>();

    	for (SelectOption so : recipientOptions) {
    		if (so.getValue() != selectedValue) {
    			recipientOptionsTemp.add(new SelectOption(so.getValue(), so.getLabel()));
    		}
    	}

    	recipientOptions = recipientOptionsTemp;
    }

/*****************************************************************************************************************************************
												Recipient paging functionality
 *****************************************************************************************************************************************/

	public map<Id, String> mapSelectedRecipients {get; set;}
	{
		mapSelectedRecipients = new map<Id, String>{};
	}	
	public set<Id> setUnselectedRecipients = new set<Id>();

	private map<Id, String> mapSelectedRecipientsInitial = new map<Id, String>{};

    public void updateSelectedItems() {

    	if (RecipientWrapperList != null) {

	        for (RecipientWrapper cw : RecipientWrapperList) {
	            if (cw.isSelected) {
	                mapSelectedRecipients.put(cw.Recipient.Id, cw.Recipient.Name);
	                if (setUnselectedRecipients.contains(cw.Recipient.Id)) setUnselectedRecipients.remove(cw.Recipient.Id);
	            } else if (mapSelectedRecipients.containsKey(cw.Recipient.Id)) {
	            	system.debug(' ### adding to setUnselectedRecipients ' + cw.Recipient.Id + ' - ');
	                mapSelectedRecipients.remove(cw.Recipient.Id);
	                setUnselectedRecipients.add(cw.Recipient.Id);
	            }
	        }

	        system.debug(' ### mapSelectedRecipients ' + mapSelectedRecipients.size() + ' => ' + mapSelectedRecipients);
	        system.debug(' ### setUnselectedRecipients ' + setUnselectedRecipients.size() + ' => ' + setUnselectedRecipients);
    	}
    }

    public static String getQuery(Id marketId, String publicationYear, String queryKey) {
		//String query = 'Select Id, Name, Account.Name, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Email from Contact where Awarded_Years__c INCLUDES( \'' + String.escapeSingleQuotes(publicationYear) + '\') and Market_Project__c = \'' + marketId + '\'' + (String.isBlank(queryKey) ? '' : (' and Name like \'%' + String.escapeSingleQuotes(queryKey) + '%\''));
		String query = 'Select Id, Name, Account.Name, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Email from Contact where Awarded_Years__c INCLUDES( \'' + String.escapeSingleQuotes(publicationYear) + '\') and ' + (marketId==null ? 'Market_Project__c = null ' : 'Market_Project__c = \'' + marketId + '\'') + (String.isBlank(queryKey) ? '' : (' and Name like \'%' + String.escapeSingleQuotes(queryKey) + '%\''));
        system.debug(logginglevel.INFO, ' ### query: ' + query);
        return query;
    }

	public PagingController RecipientPageController {
		get {
			if (RecipientPageController == null) {
				RecipientPageController = new PagingController(getQuery(marketId, publicationYear, queryKey), 'Name');
			}
			return RecipientPageController;
		}
		set;
	}

	public list<RecipientWrapper> RecipientWrapperList {
        get {
            if (RecipientWrapperList == null) {
            	RecipientWrapperList = new list<RecipientWrapper>{};

                for (Contact con : (list<Contact>) RecipientPageController.setController.getRecords()) {
                	RecipientWrapperList.add((new RecipientWrapper(mapSelectedRecipients.containsKey(con.Id), con)));
                }
            }
            return RecipientWrapperList;
        }
        set;
	}

	public void next() {
		updateSelectedItems();
		RecipientPageController.next();
		RecipientWrapperList = null;
	}

	public void previous() {
		updateSelectedItems();
		RecipientPageController.previous();
		RecipientWrapperList = null;
	}

    public void updatePageSize() {
    	updateSelectedItems();
        RecipientWrapperList = null;
        RecipientPageController.setController = null;
    }

	public Integer selectedRecipientsCount {
		get {
	    	Integer counter = 0;
	    	if (RecipientWrapperList != null) {
	    		for (RecipientWrapper cw : RecipientWrapperList) {
	    			if (cw.isSelected) counter++;
	    		}
	    	}
    		return counter;
		}
		private set;
    }

	public Integer RecipientsCount {
		get {
			return RecipientWrapperList==null ? 0 : RecipientWrapperList.size();
		}
		private set;	
	}
	
    public Boolean allSelected {
    	get {
    		Integer selectedCount = selectedRecipientsCount;
    		return (selectedCount == RecipientsCount && selectedCount > 0);
    	}
    	set;
    }

    public void sortResults() {
    	system.debug(' ### entering sortResults');
    	updateSelectedItems();
    	if (RecipientPageController != null) RecipientPageController.setController = null;
    	RecipientWrapperList = null;
    }

	public void doSearch() {
        RecipientPageController = null;
        RecipientWrapperList = null;
		setUnselectedRecipients = new set<Id>();

        if (RecipientPageController != null) system.debug(' ### RecipientPageController.totalRecordsCount ' + RecipientPageController.totalRecordsCount);
        if (RecipientPageController.totalRecordsCount == 0) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'No Recipients available.'));
    }
    
    public String getRecipientLimitDisplay() {
    	//return
    	String maxRecipients = recipientLimit;
    	//if (recipientLimit == 'Line Quantity' && quantity != null && quantity > 0) maxRecipients = String.valueOf(quantity);
    	if (recipientLimit == 'Line Quantity' && quantity != null && quantity > 0) maxRecipients = String.valueOf(quantity.intValue());

    	return maxRecipients;
    }

    public pageReference assignRecipients() {

		updateSelectedItems();

    	if (recipientLimit == '1' || recipientLimit == 'Line Quantity') {	//String.isBlank(recipientLimit) ||

    		decimal maxRecipients = recipientLimit == '1' ? 1 : quantity;
    		if (mapSelectedRecipients.size() > maxRecipients) {
    			this.isSuccess = false;
    			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'The number of selected Recipients must be equal to ' + maxRecipients));
    			return null;
    		}
    	}
    	system.debug(' ### selectedPrimaryRecipientId in assignRecipients ' + selectedPrimaryRecipientId);

		this.isSuccess = true;
    	return null;
    }

    private void copyMap(map<Id, String> source, map<Id, String> destination) {
    	destination.clear();

    	if (source != null) {
    		for (Id sid : source.keySet()) {
    			destination.put(sid, source.get(sid));
    		}
    	}
    }

    public void resetRecipients() {
    	system.debug(' ### selectedPrimaryRecipientId in resetRecipients ' + selectedPrimaryRecipientId + ' selectedPrimaryRecipientIdInitial ' + selectedPrimaryRecipientIdInitial);
    	selectedPrimaryRecipientId = selectedPrimaryRecipientIdInitial;
    	copyMap(this.mapSelectedRecipientsInitial, this.mapSelectedRecipients);
    }

/*****************************************************************************************************************************************
												Wrapper class
 *****************************************************************************************************************************************/

    public class RecipientWrapper {
    	public boolean isSelected 	{get; set;}
    	public Contact recipient 	{get; set;}

    	public RecipientWrapper(boolean pisSelected, Contact pRecipient) {
    		this.isSelected = pisSelected;
    		this.recipient = pRecipient;
    	}

    	public String getAddress() {
    		return recipient == null ? '' : (kugo2p.Util.assignIfNotEmpty(recipient.MailingStreet, '') + ', ' + kugo2p.Util.assignIfNotEmpty(recipient.MailingCity, '') + ' ' + kugo2p.Util.assignIfNotEmpty(recipient.MailingState, '') + ' ' + kugo2p.Util.assignIfNotEmpty(recipient.MailingPostalCode, '') + ' ' + kugo2p.Util.assignIfNotEmpty(recipient.MailingCountry, ''));
    	}
    }
}