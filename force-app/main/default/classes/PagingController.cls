/**********************************************************
 * Description      : Generic Page Controller with a StandardSet Controller 
 * @author          : Kiran Kurella
 * @date            : Oct 1st, 2015
 * Copyright 2015 Kugamon LLC. All rights reserved. 
 **********************************************************/

public with sharing virtual class PagingController {

	public String sortDirection {get; set;}
	private final String baseQuery;
	private final String defaultOrderByField;
	public static boolean generateQueryError = false;

	public PagingController(String bQuery, String defOrderByField) {
		this.sortDirection = 'ASC';
		this.baseQuery = bQuery;
		this.defaultOrderByField = defOrderByField;
	}

	public Integer pageSize {
        get {
            if (pageSize == null) pageSize = 10;
            return pageSize;
        }
        //set;
        set {
        	system.debug(' ### updating pageSize to ' + value);
        	pageSize = value;
        }
    }

    private String buildQuery() {
    	system.debug(logginglevel.INFO, ' ### query: ' + baseQuery + ' order by ' + orderByField + ' ' + sortDirection + ' NULLS LAST');

    	// explicitly throw an error, if generateQueryError is true
    	return baseQuery + ' order by ' + orderByField + ' ' + sortDirection + ' NULLS LAST Limit 10000' + (test.isRunningTest() && generateQueryError ? '(' : '');
    }

    // initialize std set controller 
    public ApexPages.StandardSetController setController {
        get {
            if(setController == null) {
                try {
                    // Build the query based on the Filter type selected or not.
                    setController = new ApexPages.StandardSetController(Database.getQueryLocator(buildQuery()));
                    setController.setPageSize(pageSize);
                }
                catch(Exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Following exception occurred: ' + e.getMessage()));
                }
            }
            return setController;
        }
        set;
    }

    // indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            return setController!=null ? setController.getHasNext() : false;
        }
        //private set;
    }

    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return setController!=null ? setController.getHasPrevious() : false;
        }
        //private set;
    }

    // returns the previous page of records
    public virtual void previous() {
        if (hasPrevious) setController.previous();
    }

    // returns the next page of records
    public virtual void next() {
    	if (hasNext) setController.next();
    }

    // Total Records - AllRecordsCount
    public Integer totalRecordsCount {
        get {
        	//if (setController != null) return setController.getResultSize();
        	return setController==null ? 0 : setController.getResultSize();
        }
        //private set;
    }

    public string orderByField {
        get {
            if (orderByField == null) orderByField = defaultOrderByField;
            return orderByField;
        }
        set {
            // if the sort column is clicked, then switch between Ascending and Descending modes
            if (value == orderByField) {
                sortDirection = (sortDirection == 'ASC') ? 'DESC' : 'ASC';
            } else {
                sortDirection = 'ASC';
            }

            orderByField = value;
        }
    }

    public String getSortTitle() {
    	return sortDirection=='ASC' ? 'Sorted Ascending' : 'Sorted Descending';
    }

    public String getSortStyle() {
    	return sortDirection=='ASC' ? 'sortAsc' : 'sortDesc';
    }
}