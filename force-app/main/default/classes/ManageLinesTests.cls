@isTest
public class ManageLinesTests {
  @TestSetup
  static void makeData() {
    DataSetup();
  }

  @isTest
  static void test_ManageLinesOrderExt() {
    // Switch to test context
    Test.startTest();

    // Five Star changes - set mock callout class
    Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());

    ManageLinesOrderExt mloExt = new ManageLinesOrderExt(
      new ApexPages.StandardController(SalesOrder)
    );

    system.assertNotEquals(mloExt.manageLinesOrderCon, null);
    system.assertEquals(mloExt.hasTieredPricingProducts, false);

    system.assertNotEquals(mloExt.getPageTitle(), null);
    // system.assertEquals(mloExt.PageCounts > 0, true);

    mloExt.clearSearch();
    // system.assertEquals(mloExt.getTotalProductsCount() > 0, true);
    system.assertNotEquals(mloExt.getTotalFavorites(), null);
    mloExt.PageSize = 1;
    mloExt.ResetPagesize();

    mloExt.QueryKey = 'abcd1234';
    mloExt.Search();

    mloExt.exactMatch = true;
    mloExt.QueryKey = '';
    mloExt.Search();

    mloExt.QueryKey = 'GC1010,GC1010+a,GC1040+2,abcd1234';
    mloExt.Search();

    mloExt.ResetPaging();
    Integer maxPage = ((Decimal) mloExt.ProductLines.size() / mloExt.PageSize)
      .round(system.RoundingMode.UP)
      .intValue();
    //Integer maxPage = controller.ProductLines.size();
    system.assertEquals(maxPage, mloExt.PageCounts);
    mloExt.nextPage();
    if (maxPage > 1) {
      system.assertEquals(2, mloExt.CurrentPage);
      mloExt.CurrentPage = maxPage;
      mloExt.nextPage();
    }
    mloExt.previousPage();
    if (maxPage > 1) {
      mloExt.StartIndex = 0;
      mloExt.previousPage();
    }

    mloExt.headerDiscount = 'abcd';
    mloExt.headerDiscount = '10';
    system.assertEquals(mloExt.headerDiscount, '10.00');
    system.assertEquals(mloExt.headerDiscountValue, 10.00);

    system.assertEquals(mloExt.sortExpression, 'ProductName');
    mloExt.sortExpression = 'ProductName';
    system.assertEquals(mloExt.sortExpression, 'ProductName');
    system.assertEquals(mloExt.sortDirection, 'desc');
    mloExt.sortResults();

    mloExt.sortExpression = 'Service';
    /* reducing queries
        ManageLinesController.sortProducts('Service', 'Desc', mloExt.productLines);
        ManageLinesController.sortProducts('ProductCode', 'Desc', mloExt.productLines);
        ManageLinesController.sortProducts('Description', 'Desc', mloExt.productLines);
        ManageLinesController.sortProducts('ListPrice', 'Asc', mloExt.productLines);
        ManageLinesController.sortProducts('ListPrice', 'Desc', mloExt.productLines);
        ManageLinesController.sortProducts('KitBundle', 'Asc', mloExt.productLines);
        */

    //ManageLinesController.sortProducts('ProductName', 'Asc', maqExt.productLines);
    //ManageLinesController.sortProducts('ProductName', 'Desc', maqExt.productLines);
    //ManageLinesController.sortProducts('ProductDescription', 'Asc', maqExt.productLines);
    //ManageLinesController.sortProducts('ProductFamily', 'Desc', maqExt.productLines);

    system.assertEquals(ManageLinesController.getPageParameter('test'), null);
    ApexPages.CurrentPage().getParameters().put('test', '1');
    system.assertEquals(ManageLinesController.getPageParameter('test'), '1');

    ApexPages.currentPage().getParameters().put('uindex', '0');
    ApexPages.currentPage().getParameters().put('cindex', '0');
    ApexPages.currentPage().getParameters().put('headerDiscount', '0');
    ApexPages.currentPage().getParameters().put('lineType', 'All');
    System.debug('MANAGE LINES TESTS');
    System.debug(mloExt.ProductLines);
    System.debug(mloExt.SelectedLines);
    mloExt.addLine();
    mloExt.cloneLine();

    // add the same line again
    mloExt.addLine();

    // system.assertEquals(mloExt.SelectedLines[0].tiersWrapper, null);
    // system.assertNotEquals(mloExt.SelectedLines[0].getTiersJSON(), null);

    mloExt.addAll();

    // User Favorites
    ApexPages.currentPage().getParameters().put('uProductId', Products[0].Id);
    ApexPages.currentPage().getParameters().put('uindex', '0');
    // mloExt.addFavorite();
    mloExt.initFavorites(new Set<Id>{ Products[0].Id });
    // mloExt.removeFavorite();
    mloExt.displayAllFilters();
    system.assertEquals(mloExt.showMoreFilters, true);
    mloExt.hideAllFilters();
    system.assertEquals(mloExt.showMoreFilters, false);

    ApexPages.currentPage().getParameters().put('sindex', '0');
    mloExt.dummyStartDate.ServiceDate = system.today().addDays(-200);
    mloExt.updateheaderStartDate();
    mloExt.calculateServiceEndDate();
    mloExt.updateKitMemberStartDate();

    mloExt.updateSalesPriceAndKitMemberDtls();

    if (!mloExt.SelectedLines.isEmpty()) {
      mloExt.SelectedLines[0].salesPrice = 'abcd';
      mloExt.save();

      mloExt.SelectedLines[0].salesPrice = '';
      mloExt.save();

      mloExt.SelectedLines[0].salesPrice = '1';
    }

    mloExt.updateheaderDiscount();
    //mloExt.calculateTotal();
    mloExt.getProductIdToTiers();
    mloExt.getSelectedProducts();
    mloExt.getSelectedServices();
    system.assertNotEquals(ManageLinesController.Settings.Id, null);
    system.assertNotEquals(mloExt.allowOverrideServiceDateUpdate, null);
    system.assertNotEquals(mloExt.disableQuoteOptionalManagedLines, null);
    ManageLinesController.escapeSingleQuotes(null);
    //system.assertNotEquals(mloExt.ProductFamilyOptions.isEmpty(), null);
    //system.assertNotEquals(mloExt.ProductFamilies.isEmpty(), null);

    //mloExt.sortLines(mloExt.SelectedLines);

    for (ManageLinesController.LineItemInfo lineItem : mloExt.SelectedLines) {
      lineItem.Discount = '10';
      lineItem.salesPrice = '1';
      lineItem.quantity = '1';
      lineItem.startDate = system.today().format();
      lineItem.EndDate = system.today().addYears(1).format();
    }

    mloExt.save();
    //mloExt.updates();

    // Five Star changes - assign Line Recipients
    ApexPages.currentPage().getParameters().put('sindex', '0');
    mloExt.marketId = market.Id;
    // mloExt.manageRecipients();

    ManageRecipientController mrCon = mloExt.manageRecipientCon;

    // system.assertNotEquals(mrCon.manageRecipientCon, null);

    // system.assertEquals(mrCon.recipientOptions.isEmpty(), true);
    // mrCon.mapSelectedRecipients = new Map<Id, String>{
    //   contacts[0].Id => contacts[0].FirstName
    // };
    // mrCon.recipientOptions = null;
    // system.assertEquals(mrCon.recipientOptions.isEmpty(), false);
    // mrCon.mapSelectedRecipients = new Map<Id, String>{};

    //mrCon.doSearch();

    // make sure there are two Recipients
    // system.assertEquals(mrCon.RecipientsCount, 2);
    // system.assertEquals(mrCon.RecipientPageController.totalRecordsCount, 2);

    // set the page size to 1
    // mrCon.RecipientPageController.PageSize = 1;
    // system.assertEquals(mrCon.RecipientPageController.PageSize, 1);

    //reset the page size
    // mrCon.updatePageSize();
    // system.assertEquals(mrCon.RecipientPageController.hasNext, true);

    // Five Star changes - raise an error, as there are no selected items
    // mrCon.assignRecipients();

    //no previous page on the first page
    // system.assertEquals(mrCon.RecipientPageController.hasPrevious, false);
    // Five Star changes - select the first Recipient
    // mrCon.RecipientWrapperList[0].isSelected = true;
    // mrCon.next();

    //system.assertEquals(mrCon.RecipientPageController.hasPrevious, true);
    // Five Star changes - go back to the first page
    // mrCon.previous();

    // Five Star changes - un-select the first Recipient
    // mrCon.RecipientWrapperList[0].isSelected = false;
    // mrCon.updateSelectedItems();
    /*
        // Five Star changes - sort the results
        system.assertEquals(mrCon.RecipientPageController.totalRecordsCount, 2);
        system.assertEquals(mrCon.RecipientPageController.orderByField, 'Name');
        system.assertEquals(mrCon.RecipientPageController.sortDirection, 'ASC');
        system.assertEquals(mrCon.RecipientPageController.getSortTitle(), 'Sorted Ascending');
        mrCon.RecipientPageController.orderByField = 'Name';
        system.assertEquals(mrCon.RecipientPageController.sortDirection, 'DESC');
        system.assertEquals(mrCon.RecipientPageController.getSortStyle(), 'sortDesc');
        mrCon.RecipientPageController.orderByField = 'Email';
        system.assertEquals(mrCon.RecipientPageController.sortDirection, 'ASC');
        mrCon.sortResults();

        system.assertEquals(mrCon.selectedRecipientsCount, 0);
        system.assertEquals(mrCon.allSelected, false);

        // explicitly throw a query error
        PagingController.generateQueryError = true;
        try {
            mrCon.doSearch();
            system.assertEquals(mrCon.RecipientPageController.totalRecordsCount == 0, true);
        } catch (exception ex) {

        }
        PagingController.generateQueryError = false;

        // Five Star changes - select the first two Recipients
        mrCon.RecipientWrapperList[0].isSelected = true;
        mrCon.RecipientWrapperList[1].isSelected = true;
        mrCon.RecipientWrapperList[0].getAddress();
        mrCon.assignRecipients();

        mrCon.selectedItem = contacts[0].FirstName;
        mrCon.selectedValue = contacts[0].Id;
        mrCon.addRecipientOption();

        mrCon.removeRecipientOption();
        mrCon.getRecipientLimitDisplay();
        mrCon.resetRecipients();

        // Five Star changes - explicitly throw an error and rollback changes
        try {
            mrCon.RecipientWrapperList[0].isSelected = true;
            mrCon.RecipientWrapperList[0].recipient = null;

            mrCon.assignRecipients();

        } catch (exception ex) {

        }
               
        mrCon.RecipientWrapperList[1].isSelected = false;
        mrCon.RecipientWrapperList[0].recipient = contacts[0];
        mrCon.selectedPrimaryRecipientId = contacts[0].Id;
        mrCon.assignRecipients();

        //mloExt.manageRecipientCon.assignRecipients();
        mloExt.hideRecipient();

        mloExt.headerDiscountValue = 10;
        mloExt.salesOrder.FulfillOrder__c = true;

        for (ManageLinesController.LineItemInfo lineItem : mloExt.SelectedLines) {
            lineItem.Discount = '10';
            lineItem.salesPrice = '1';
            lineItem.quantity = '1';
            lineItem.startDate = system.today().format();
            lineItem.EndDate = system.today().addYears(1).format();
        }

        mloExt.save();
        //mloExt.save();

        system.assertEquals(LineRecipients.isEmpty(), false);

        ApexPages.currentPage().getParameters().put('sindex', '0');
        mloExt.delLine();
        mloExt.save();
        mloExt.cancel();

        salesOrder.kugo2p__ContactShipping__c = contacts[0].Id;
        salesOrder.kugo2p__ShipToName__c = 'Will Smith';
        salesOrder.kugo2p__ShipToStreetLong__c = '1 Kugamon Street';
        salesOrder.kugo2p__ShipToCity__c = 'San Francisco';
        salesOrder.kugo2p__ShipToStateProvince__c = 'California';
        salesOrder.kugo2p__ShipToZipPostalCode__c = '95050';
        salesOrder.Release_Date__c = system.today();
        salesOrder.kugo2p__Warehouse__c =warehouses[0].Id;
        salesOrder.kugo2p__ContactBuying__c = contacts[0].Id;
        salesOrder.kugo2p__ContactBilling__c = contacts[0].Id;


        SalesOrder.kugo2p__RecordStatus__c = 'Cancelled';
        update SalesOrder;
        mloExt = new ManageLinesOrderExt(new ApexPages.StandardController(SalesOrder));

        ManageLinesController.LineItemInfo liinfo = new ManageLinesController.LineItemInfo();

        liinfo.AvailableQuantity = 100;
        system.assertEquals(liinfo.isNewKitBundleMember, false);

        liinfo.Quantity = 'abcd';
        system.assertEquals(liinfo.Quantity, 'abcd');

        liinfo.SalesPrice = 'abcd';
        system.assertEquals(liinfo.SalesPrice, 'abcd');

        liinfo.Discount = 'abcd';
        system.assertEquals(liinfo.Discount, 'abcd');

        liinfo.StartDate = 'abcd';
        system.assertEquals(liinfo.StartDate, 'abcd');

        system.assertEquals(liinfo.isNewItem, true);

        system.assertEquals(liinfo.isKitBundleMember, false);
        
        system.assertNotEquals(liinfo.getHasTieredPricing(), null);

        liinfo.getKitMembers();
        system.assertNotEquals(liinfo.hasRecommendedProducts, null);
        system.assertEquals(liinfo.tiersWrapper, null);
        system.assertNotEquals(liinfo.getTiersJSON(), null);
        system.assertNotEquals(liinfo.TotalAmount, null);

        system.assertEquals(liinfo.AssignedRecipientsCount, 0);
        system.assertEquals(liinfo.hasAssignedRecipients, false);

        system.assertNotEquals(liinfo.TotalDiscount, null);

        mloExt.cancel();

        ManageLinesController.TierWrapper tw = new ManageLinesController.TierWrapper(10, new kugo2p__Tier__c(kugo2p__QuantityStart__c=10, kugo2p__TierPrice__c=10.00));
        tw.discountValue = 10;
        tw.tier.kugo2p__QuantityStart__c = 10;
        tw.tier.kugo2p__TierPrice__c = 100;
        tw.getQuantityStart();
        tw.getDiscount();
        tw.getTierPrice();
                
        //reset pricebook
        if(mloExt.PricebookOptions.size() > 0) {
            //mloExt.PricebookId = mloExt.PricebookOptions[0].getValue();
            mloExt.resetPricebook();
            //system.assertEquals(0, mloExt.SelectedLines.size());
        }
*/
    // Switch back to runtime context
    Test.stopTest();
  }

  @isTest
  static void test_ManageLinesOrderExt2() {
    // Switch to test context
    Test.startTest();

    // Five Star changes - set mock callout class
    Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());

    ManageLinesOrderExt mloExt = new ManageLinesOrderExt(
      new ApexPages.StandardController(SalesOrder)
    );

    /*system.assertNotEquals(mloExt.manageLinesOrderCon, null);
        system.assertEquals(mloExt.hasTieredPricingProducts, false);

        system.assertNotEquals(mloExt.getPageTitle(), null);
        system.assertEquals(mloExt.PageCounts > 0, true);

        mloExt.clearSearch();
        system.assertEquals(mloExt.getTotalProductsCount() > 0, true);
        system.assertNotEquals(mloExt.getTotalFavorites(), null);
        mloExt.PageSize = 1;
        mloExt.ResetPagesize();     

        mloExt.QueryKey = 'abcd1234';
        mloExt.Search();

        mloExt.exactMatch = true;
        mloExt.QueryKey = '';
        mloExt.Search();

        mloExt.QueryKey = 'GC1010,GC1010+a,GC1040+2,abcd1234';
        mloExt.Search();

        mloExt.ResetPaging();
        Integer maxPage = ((Decimal)mloExt.ProductLines.size() / mloExt.PageSize).round(system.RoundingMode.UP).intValue();
        //Integer maxPage = controller.ProductLines.size();
        system.assertEquals(maxPage, mloExt.PageCounts);
        mloExt.nextPage();
        if (maxPage > 1) {
            system.assertEquals(2, mloExt.CurrentPage);
            mloExt.CurrentPage = maxPage;
            mloExt.nextPage();
        }
        mloExt.previousPage();
        if(maxPage > 1) {
            mloExt.StartIndex = 0;
            mloExt.previousPage();
        }

        mloExt.headerDiscount = 'abcd';     
        mloExt.headerDiscount = '10';
        system.assertEquals(mloExt.headerDiscount, '10.00');
        system.assertEquals(mloExt.headerDiscountValue, 10.00);
        
        system.assertEquals(mloExt.sortExpression, 'ProductName');
        mloExt.sortExpression = 'ProductName';
        system.assertEquals(mloExt.sortExpression, 'ProductName');
        system.assertEquals(mloExt.sortDirection, 'desc');
        mloExt.sortResults();

        mloExt.sortExpression = 'Serivce';
        ManageLinesController.sortProducts('Service', 'Desc', mloExt.productLines);
        ManageLinesController.sortProducts('ProductCode', 'Desc', mloExt.productLines);
        ManageLinesController.sortProducts('Description', 'Desc', mloExt.productLines);
        ManageLinesController.sortProducts('ListPrice', 'Asc', mloExt.productLines);
        ManageLinesController.sortProducts('ListPrice', 'Desc', mloExt.productLines);
        ManageLinesController.sortProducts('KitBundle', 'Asc', mloExt.productLines);
        //ManageLinesController.sortProducts('ProductName', 'Asc', maqExt.productLines);
        //ManageLinesController.sortProducts('ProductName', 'Desc', maqExt.productLines);
        //ManageLinesController.sortProducts('ProductDescription', 'Asc', maqExt.productLines);
        //ManageLinesController.sortProducts('ProductFamily', 'Desc', maqExt.productLines);

        system.assertEquals(ManageLinesController.getPageParameter('test'), null);
        ApexPages.CurrentPage().getParameters().put('test', '1');
        system.assertEquals(ManageLinesController.getPageParameter('test'), '1');
        
        ApexPages.currentPage().getParameters().put('uindex', '0');
        ApexPages.currentPage().getParameters().put('cindex', '0');
        ApexPages.currentPage().getParameters().put('headerDiscount', '0');
        ApexPages.currentPage().getParameters().put('lineType', 'All');
        mloExt.addLine();
        mloExt.cloneLine();

        // add the same line again
        mloExt.addLine();

        system.assertEquals(mloExt.SelectedLines[0].tiersWrapper, null);
        system.assertNotEquals(mloExt.SelectedLines[0].getTiersJSON(), null);

        mloExt.addAll();

        // User Favorites
        ApexPages.currentPage().getParameters().put('uProductId', Products[0].Id);
        ApexPages.currentPage().getParameters().put('uindex', '0');
        mloExt.addFavorite();
        mloExt.initFavorites(new set<Id> {Products[0].Id});
        mloExt.removeFavorite();
        mloExt.displayAllFilters();
        system.assertEquals(mloExt.showMoreFilters, true);
        mloExt.hideAllFilters();
        system.assertEquals(mloExt.showMoreFilters, false);     

        ApexPages.currentPage().getParameters().put('sindex', '0');
        mloExt.dummyStartDate.ServiceDate = system.today().addDays(-200);
        mloExt.updateheaderStartDate();
        mloExt.calculateServiceEndDate();
        mloExt.updateKitMemberStartDate();

        mloExt.updateSalesPriceAndKitMemberDtls();

        if (!mloExt.SelectedLines.isEmpty()) {
            mloExt.SelectedLines[0].salesPrice = 'abcd';
            mloExt.save();
            
            mloExt.SelectedLines[0].salesPrice = '';
            mloExt.save();
            
            mloExt.SelectedLines[0].salesPrice = '1';
        }
        
        mloExt.updateheaderDiscount();
        //mloExt.calculateTotal();
        mloExt.getProductIdToTiers();
        mloExt.getSelectedProducts();
        mloExt.getSelectedServices();
        system.assertNotEquals(ManageLinesController.Settings.Id, null);
        system.assertNotEquals(mloExt.allowOverrideServiceDateUpdate, null);
        system.assertNotEquals(mloExt.disableQuoteOptionalManagedLines, null);
        ManageLinesController.escapeSingleQuotes(null);
        //system.assertNotEquals(mloExt.ProductFamilyOptions.isEmpty(), null);
        //system.assertNotEquals(mloExt.ProductFamilies.isEmpty(), null);
        
        //mloExt.sortLines(mloExt.SelectedLines);

        for (ManageLinesController.LineItemInfo lineItem : mloExt.SelectedLines) {
            lineItem.Discount = '10';
            lineItem.salesPrice = '1';
            lineItem.quantity = '1';
            lineItem.startDate = system.today().format();
            lineItem.EndDate = system.today().addYears(1).format();
        }

        mloExt.save();
        //mloExt.updates();

        // Five Star changes - assign Line Recipients
        ApexPages.currentPage().getParameters().put('sindex', '0');
        mloExt.marketId = market.Id;
        mloExt.manageRecipients();

        ManageRecipientController mrCon = mloExt.manageRecipientCon;

        system.assertNotEquals(mrCon.manageRecipientCon, null);

        system.assertEquals(mrCon.recipientOptions.isEmpty(), true);
        mrCon.mapSelectedRecipients = new map<Id, String> {contacts[0].Id => contacts[0].FirstName};
        mrCon.recipientOptions = null;
        system.assertEquals(mrCon.recipientOptions.isEmpty(), false);
        mrCon.mapSelectedRecipients = new map<Id, String> {};

        //mrCon.doSearch();

        // make sure there are two Recipients
        system.assertEquals(mrCon.RecipientsCount, 2);
        system.assertEquals(mrCon.RecipientPageController.totalRecordsCount, 2);        

        // set the page size to 1
        mrCon.RecipientPageController.PageSize = 1;
        system.assertEquals(mrCon.RecipientPageController.PageSize, 1);

        //reset the page size
        mrCon.updatePageSize();
        system.assertEquals(mrCon.RecipientPageController.hasNext, true);

        // Five Star changes - raise an error, as there are no selected items
        mrCon.assignRecipients();

        //no previous page on the first page
        system.assertEquals(mrCon.RecipientPageController.hasPrevious, false);
        // Five Star changes - select the first Recipient
        mrCon.RecipientWrapperList[0].isSelected = true;
        mrCon.next();

        //system.assertEquals(mrCon.RecipientPageController.hasPrevious, true);
        // Five Star changes - go back to the first page
        mrCon.previous();

        // Five Star changes - un-select the first Recipient
        mrCon.RecipientWrapperList[0].isSelected = false;
        mrCon.updateSelectedItems();
*/
    // Five Star changes - sort the results
    ApexPages.currentPage().getParameters().put('sindex', '0');
    mloExt.marketId = market.Id;
    // mloExt.manageRecipients();
    ManageRecipientController mrCon = mloExt.manageRecipientCon;
    /*system.assertEquals(mrCon.RecipientPageController.totalRecordsCount, 2);
        system.assertEquals(mrCon.RecipientPageController.orderByField, 'Name');
        system.assertEquals(mrCon.RecipientPageController.sortDirection, 'ASC');
        system.assertEquals(mrCon.RecipientPageController.getSortTitle(), 'Sorted Ascending');*/
    // mrCon.RecipientPageController.orderByField = 'Name';
    //system.assertEquals(mrCon.RecipientPageController.sortDirection, 'DESC');
    //system.assertEquals(mrCon.cipientPageController.getSortStyle(), 'sortDesc');
    // mrCon.RecipientPageController.orderByField = 'Email';
    //system.assertEquals(mrCon.RecipientPageController.sortDirection, 'ASC');
    // mrCon.sortResults();

    //system.assertEquals(mrCon.selectedRecipientsCount, 0);
    //system.assertEquals(mrCon.allSelected, false);

    // explicitly throw a query error
    PagingController.generateQueryError = true;
    try {
      mrCon.doSearch();
      system.assertEquals(
        mrCon.RecipientPageController.totalRecordsCount == 0,
        true
      );
    } catch (exception ex) {
    }
    PagingController.generateQueryError = false;

    // Five Star changes - select the first two Recipients
    // mrCon.RecipientWrapperList[0].isSelected = true;
    // mrCon.RecipientWrapperList[1].isSelected = true;
    // mrCon.RecipientWrapperList[0].getAddress();
    // mrCon.assignRecipients();

    // mrCon.selectedItem = contacts[0].FirstName;
    // mrCon.selectedValue = contacts[0].Id;
    // mrCon.addRecipientOption();

    // mrCon.removeRecipientOption();
    // mrCon.getRecipientLimitDisplay();
    // mrCon.resetRecipients();

    // Five Star changes - explicitly throw an error and rkugo2p__WareHouseselectedLineItemInfoCity__collback changes
    try {
      mrCon.RecipientWrapperList[0].isSelected = true;
      mrCon.RecipientWrapperList[0].recipient = null;

      mrCon.assignRecipients();
    } catch (exception ex) {
    }

    // mrCon.RecipientWrapperList[1].isSelected = false;
    // mrCon.RecipientWrapperList[0].recipient = contacts[0];
    //mrCon.selectedPrimaryRecipientId = contacts[0].Id;
    // mrCon.assignRecipients();

    //mloExt.manageRecipientCon.assignRecipients();
    mloExt.hideRecipient();

    mloExt.headerDiscountValue = 10;
    mloExt.salesOrder.FulfillOrder__c = true;

    for (ManageLinesController.LineItemInfo lineItem : mloExt.SelectedLines) {
      lineItem.Discount = '10';
      lineItem.salesPrice = '1';
      lineItem.quantity = '1';
      lineItem.startDate = system.today().format();
      lineItem.EndDate = system.today().addYears(1).format();
    }

    mloExt.save();
    //mloExt.save();

    system.assertEquals(LineRecipients.isEmpty(), false);

    ApexPages.currentPage().getParameters().put('sindex', '0');
    // mloExt.delLine();
    // mloExt.save();
    mloExt.cancel();

    salesOrder.kugo2p__ContactShipping__c = contacts[0].Id;
    salesOrder.kugo2p__ShipToName__c = 'Will Smith';
    salesOrder.kugo2p__ShipToStreetLong__c = '1 Kugamon Street';
    salesOrder.kugo2p__ShipToCity__c = 'San Francisco';
    salesOrder.kugo2p__ShipToStateProvince__c = 'California';
    salesOrder.kugo2p__ShipToZipPostalCode__c = '95050';
    salesOrder.Release_Date__c = system.today();
    salesOrder.kugo2p__Warehouse__c = warehouses[0].Id;
    salesOrder.kugo2p__ContactBuying__c = contacts[0].Id;
    salesOrder.kugo2p__ContactBilling__c = contacts[0].Id;

    SalesOrder.kugo2p__RecordStatus__c = 'Cancelled';
    update SalesOrder;
    mloExt = new ManageLinesOrderExt(
      new ApexPages.StandardController(SalesOrder)
    );

    ManageLinesController.LineItemInfo liinfo = new ManageLinesController.LineItemInfo();

    liinfo.AvailableQuantity = 100;
    system.assertEquals(liinfo.isNewKitBundleMember, false);

    liinfo.Quantity = 'abcd';
    system.assertEquals(liinfo.Quantity, 'abcd');

    liinfo.SalesPrice = 'abcd';
    system.assertEquals(liinfo.SalesPrice, 'abcd');

    liinfo.Discount = 'abcd';
    system.assertEquals(liinfo.Discount, 'abcd');

    liinfo.StartDate = 'abcd';
    system.assertEquals(liinfo.StartDate, 'abcd');

    system.assertEquals(liinfo.isNewItem, true);

    system.assertEquals(liinfo.isKitBundleMember, false);

    system.assertNotEquals(liinfo.getHasTieredPricing(), null);

    liinfo.getKitMembers();
    system.assertNotEquals(liinfo.hasRecommendedProducts, null);
    system.assertEquals(liinfo.tiersWrapper, null);
    system.assertNotEquals(liinfo.getTiersJSON(), null);
    system.assertNotEquals(liinfo.TotalAmount, null);

    system.assertEquals(liinfo.AssignedRecipientsCount, 0);
    system.assertEquals(liinfo.hasAssignedRecipients, false);

    system.assertNotEquals(liinfo.TotalDiscount, null);

    mloExt.cancel();

    ManageLinesController.TierWrapper tw = new ManageLinesController.TierWrapper(
      10,
      new kugo2p__Tier__c(
        kugo2p__QuantityStart__c = 10,
        kugo2p__TierPrice__c = 10.00
      )
    );
    tw.discountValue = 10;
    tw.tier.kugo2p__QuantityStart__c = 10;
    tw.tier.kugo2p__TierPrice__c = 100;
    tw.getQuantityStart();
    tw.getDiscount();
    tw.getTierPrice();

    //reset pricebook
    if (mloExt.PricebookOptions.size() > 0) {
      //mloExt.PricebookId = mloExt.PricebookOptions[0].getValue();
      mloExt.resetPricebook();
      //system.assertEquals(0, mloExt.SelectedLines.size());
    }
    // Switch back to runtime context
    Test.stopTest();
  }

  @isTest
  static void test_ManageLinesOrderExt1() {
    // Switch to test context
    Test.startTest();

    // Five Star changes - set mock callout class
    Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());

    ManageLinesController mlCon = new ManageLinesController();

    system.assertEquals(mlCon.getPageTitle(), null);
    system.assertNotEquals(mlCon.showRecommendedTab, null);
    mlCon.sortRecommendedProducts();
    mlCon.sortFavoriteProducts();

    ManageLinesOrderExt mloExt = new ManageLinesOrderExt(
      new ApexPages.StandardController(SalesOrder)
    );

    mloExt.salesOrder.FulfillOrder__c = true;
    mloExt.save();

    mloExt.salesOrder.FulfillOrder__c = false;
    mloExt.save();

    ManageLinesController.mPricebookEntries.clear();
    ManageLinesController.getPricebookEntry(
      CustomPriceBook.Id,
      products[0].Id,
      ''
    );
    ManageLinesController.getPricebookEntries(
      CustomPriceBook.Id,
      new Set<Id>{ Products[0].Id, Products[1].Id },
      null
    );

    // Switch back to runtime context
    Test.stopTest();
  }

  @isTest
  static void test_ManageLinesOrderExtFilters() {
    // Switch to test context
    Test.startTest();

    ManageLinesOrderExt mloExt = new ManageLinesOrderExt(
      new ApexPages.StandardController(SalesOrder)
    );

    system.assertNotEquals(mloExt.manageLinesOrderCon, null);
    system.assertEquals(mloExt.hasTieredPricingProducts, false);

    system.assertNotEquals(mloExt.getPageTitle(), null);
    // system.assertEquals(mloExt.PageCounts > 0, true);

    mloExt.PageSize = 1;
    mloExt.ResetPagesize();

    mloExt.filters[0].selectedFieldName = 'Name';
    mloExt.filters[0].updateOperatorOptions();
    mloExt.filters[0].selectedOperator = 'not equal to';
    mloExt.filters[0].selectedFieldValue = '';

    mloExt.filters[1].selectedFieldName = 'IsActive';
    mloExt.filters[1].updateOperatorOptions();
    mloExt.filters[1].selectedOperator = 'equals';
    mloExt.filters[1].selectedFieldValue = 'true';

    mloExt.filters[2].selectedFieldName = 'kugo2p__UnitCost__c';
    mloExt.filters[2].updateOperatorOptions();
    mloExt.filters[2].selectedOperator = 'greater than';
    mloExt.filters[2].selectedFieldValue = '0';

    mloExt.QueryKey = '';
    mloExt.search();
    mloExt.clearSearch();

    mloExt.displayAllFilters();
    mloExt.hideAllFilters();

    // Switch back to runtime context
    Test.stopTest();

    // system.assert(!mloExt.ProductLines.isEmpty(), 'Search result not empty');
  }

  // Five Star changes
  @isTest
  static void test_InvoiceLineViewExt() {
    // switch to test context
    Test.startTest();

    InvoiceLineViewExt ilvExt = new InvoiceLineViewExt(
      new ApexPages.StandardController(InvoiceLines[0])
    );
    system.assertEquals(ilvExt.lineRecipients.isEmpty(), true);

    // switch back to runtime context
    Test.stopTest();
  }

  // Five Star changes
  @isTest
  static void test_OrderPaymentScheduleExt() {
    // switch to test context
    Test.startTest();

    OrderPaymentScheduleExt opsExt = new OrderPaymentScheduleExt(
      new ApexPages.StandardController(SalesOrder)
    );

    // Five Star changes - FS04 (Finance Term Options are derived from an object and can't guarantee a fixed number of 12 options)
    // Order balance due is over 7K and hence we should have 13 finance term options including 1 Month and None options
    //system.assertEquals(opsExt.FinanceTermOptions.size(), 12);
    system.assertEquals(opsExt.FinanceTermOptions.isEmpty(), false);

    ManageLinesController.Settings.FinanceOverrideProfile__c = null;
    update ManageLinesController.Settings;

    salesOrder.Shipping_Type__c = 'Residential';
    salesOrder.kugo2p__RecordStatus__c = 'Draft';
    //SalesOrder.kugo2p__ContactBilling__c = contacts[0].Id;

    salesOrder.kugo2p__ContactShipping__c = contacts[0].Id;
    salesOrder.kugo2p__ShipToName__c = 'Will Smith';
    salesOrder.kugo2p__ShipToStreetLong__c = '1 Kugamon Street';
    salesOrder.kugo2p__ShipToCity__c = 'San Francisco';
    salesOrder.kugo2p__ShipToStateProvince__c = 'California';
    salesOrder.kugo2p__ShipToZipPostalCode__c = '95050';
    salesOrder.Release_Date__c = system.today();
    salesOrder.kugo2p__Warehouse__c = warehouses[0].Id;
    salesOrder.kugo2p__ContactBuying__c = contacts[0].Id;
    salesOrder.kugo2p__ContactBilling__c = contacts[0].Id;
    salesOrder.kugo2p__Warehouse__c = warehouses[0].Id;
    salesOrder.kugo2p__ContactBuying__c = contacts[0].Id;
    salesOrder.kugo2p__ContactBilling__c = contacts[0].Id;

    salesOrder.FreeFinancingApproved__c = true;

    update salesOrder;

    opsExt.isError = false;
    opsExt.redirect();

    opsExt = new OrderPaymentScheduleExt(
      new ApexPages.StandardController(SalesOrder)
    );
    // Finance Override is false and hence we should have 4 finance term options including 1 Month and None options
    //system.assertEquals(opsExt.FinanceTermOptions.size(), 5);

    // raise an error, as the Finance Term is not selected
    opsExt.savePaymentSchedule();

    opsExt.selectedFinanceTerm = '3';
    opsExt.setFinanceTermValues();
    //  opsExt.recalcInitialAmount();
    //decimal initialDownPayment = opsExt.dummySO.kugo2p__ProductDiscountAmount__c;
    //decimal initialDownPayment = 400;
    opsExt.dummySO.kugo2p__ProductDiscountAmount__c = -1;

    // raise an error, as the initial payment must be greater than 1/3 of balance due amount for 3 months
    opsExt.savePaymentSchedule();

    // raise an error, as the initial payment is greater than Order balance due amount
    opsExt.dummySO.kugo2p__ProductDiscountAmount__c = salesOrder.kugo2p__BalanceDueAmount__c !=
      null
      ? salesOrder.kugo2p__BalanceDueAmount__c + 1
      : 1000000;
    opsExt.savePaymentSchedule();

    //opsExt.dummySO.kugo2p__ProductDiscountAmount__c = initialDownPayment;
    opsExt.dummySO.kugo2p__ProductDiscountAmount__c = salesOrder.kugo2p__BalanceDueAmount__c !=
      null
      ? salesOrder.kugo2p__BalanceDueAmount__c / 2
      : 1;

    opsExt.savePaymentSchedule();
    // opsExt.saveAndCharge();

    opsExt.SalesOrder.kugo2p__ContactBilling__c = contacts[0].Id;
    // opsExt.saveAndCharge();

    list<kugo2p__Payment_Profile__c> existingProfiles = [
      SELECT Id, kugo2p__Subscription_Status__c
      FROM kugo2p__Payment_Profile__c
      WHERE kugo2p__SalesOrder__c = :salesOrder.Id
    ];
    if (!existingProfiles.isEmpty()) {
      existingProfiles[0].kugo2p__Subscription_Status__c = 'Active';

      update existingProfiles[0];
    }

    // reload the Controller
    opsExt = new OrderPaymentScheduleExt(
      new ApexPages.StandardController(SalesOrder)
    );

    // raise an error, as there is an Active recurring charge
    opsExt.savePaymentSchedule();

    opsExt.deletePaymentSchedule();

    // delete Line items to make the balance due amount zero and the payment status to Paid
    //delete OrderACCs;
    delete [
      SELECT Id
      FROM kugo2p__SalesOrderAdditionalChargeCredit__c
      WHERE kugo2p__SalesOrder__c = :SalesOrder.Id
    ];
    delete OrderProductLines;
    // delete OrderServiceLines;
    SalesOrder = [
      SELECT
        Name,
        kugo2p__Account__c,
        kugo2p__Account__r.Name,
        kugo2p__Opportunity__c,
        kugo2p__OrderDate__c,
        kugo2p__PriceBookName__c,
        kugo2p__DateRequired__c,
        kugo2p__ServiceDateRequired__c,
        kugo2p__PaymentTerms__c,
        kugo2p__BillingFrequency__c,
        kugo2p__RecordStatus__c,
        kugo2p__DiscountPercent__c,
        kugo2p__BalanceDueAmount__c,
        kugo2p__PaymentStatus2__c,
        kugo2p__ContactBilling__c,
        kugo2p__ContactBuying__c,
        kugo2p__ContactBuying__r.Name,
        Market__c,
        Market__r.Publication_Year__c,
        FinanceTerm__c,
        FinanceOverride__c
      FROM kugo2p__SalesOrder__c
      WHERE Id = :SalesOrder.Id
    ];
    system.debug(
      ' ### kugo2p__PaymentStatus2__c ' +
      salesOrder.kugo2p__PaymentStatus2__c +
      ' BalanceDueAmount ' +
      salesOrder.kugo2p__BalanceDueAmount__c
    );

    opsExt = new OrderPaymentScheduleExt(
      new ApexPages.StandardController(SalesOrder)
    );

    // Finance Override is false and hence we should have 4 finance term options including 1 Month and None options
    system.assertEquals(opsExt.FinanceTermOptions.isEmpty(), false);

    opsExt.cancel();

    // switch back to runtime context
    Test.stopTest();
  }

  // Five Star changes
  @isTest
  static void test_OrderPaymentScheduleExt_NoFinanceOverride() {
    //system.assertEquals(FinanceChargeRules.isEmpty(), false);
    //system.assertNotEquals(SalesOrder.Id, null);
    // switch to test context
    Test.startTest();

    salesOrder.FinanceOverride__c = false;
    salesOrder.Shipping_Type__c = 'Residential';
    salesOrder.kugo2p__RecordStatus__c = 'Draft';
    //SalesOrder.kugo2p__ContactBilling__c = contacts[0].Id;

    salesOrder.kugo2p__ContactShipping__c = contacts[0].Id;
    salesOrder.kugo2p__ShipToName__c = 'Will Smith';
    salesOrder.kugo2p__ShipToStreetLong__c = '1 Kugamon Street';
    salesOrder.kugo2p__ShipToCity__c = 'San Francisco';
    salesOrder.kugo2p__ShipToStateProvince__c = 'California';
    salesOrder.kugo2p__ShipToZipPostalCode__c = '95050';
    salesOrder.Release_Date__c = system.today();
    salesOrder.kugo2p__Warehouse__c = warehouses[0].Id;
    salesOrder.kugo2p__ContactBuying__c = contacts[0].Id;
    salesOrder.kugo2p__ContactBilling__c = contacts[0].Id;

    salesOrder.FreeFinancingApproved__c = true;

    update salesOrder;

    OrderPaymentScheduleExt opsExt = new OrderPaymentScheduleExt(
      new ApexPages.StandardController(SalesOrder)
    );

    // Finance Override is false and hence we should have 4 finance term options including 1 Month and None options
    system.assertEquals(opsExt.FinanceTermOptions.isEmpty(), false);

    opsExt.selectedFinanceTerm = '3';
    opsExt.setFinanceTermValues();
    opsExt.recalcInitialAmount();

    opsExt.cancel();

    // switch back to runtime context
    Test.stopTest();
  }

  // Five Star changes
  @isTest
  static void test_RecurringChargeTrigger() {
    // Switch to test context
    Test.startTest();

    ManageLinesController.Settings.FinanceOverrideProfile__c = null;
    update ManageLinesController.Settings;

    salesOrder.Shipping_Type__c = 'Residential';
    salesOrder.kugo2p__RecordStatus__c = 'Draft';
    //SalesOrder.kugo2p__ContactBilling__c = contacts[0].Id;

    salesOrder.kugo2p__ContactShipping__c = ManageLinesTests.contacts[0].Id;
    salesOrder.kugo2p__ShipToName__c = 'Will Smith';
    salesOrder.kugo2p__ShipToStreetLong__c = '1 Kugamon Street';
    salesOrder.kugo2p__ShipToCity__c = 'San Francisco';
    salesOrder.kugo2p__ShipToStateProvince__c = 'California';
    salesOrder.kugo2p__ShipToZipPostalCode__c = '95050';
    salesOrder.Release_Date__c = system.today();
    salesOrder.kugo2p__Warehouse__c = warehouses[0].Id;
    salesOrder.kugo2p__ContactBuying__c = contacts[0].Id;
    salesOrder.kugo2p__ContactBilling__c = contacts[0].Id;

    salesOrder.FreeFinancingApproved__c = true;

    update salesOrder;

    kugo2p__Payment_Profile__c newProfile = new kugo2p__Payment_Profile__c(
      Name = 'Profile2',
      kugo2p__SalesOrder__c = salesOrder.Id,
      kugo2p__Contact__c = ManageLinesTests.contacts[0].Id,
      kugo2p__Amount__c = salesOrder.kugo2p__BalanceDueAmount__c,
      kugo2p__Subscription_Status__c = 'Not Active',
      kugo2p__Frequency__c = 1,
      kugo2p__Period__c = 'Month',
      kugo2p__Total_Occurrences__c = 1
    );
    insert newProfile;

    newProfile.kugo2p__Subscription_Status__c = 'Active';
    update newProfile;

    // Switch back to runtime context
    Test.stopTest();
  }

  /*****************************************************************************************************************************************
                                                Setup test data
 *****************************************************************************************************************************************/

  public static String CurrencyIsoCodeField {
    get {
      return kugo2p.Currencies.isMultiCurrencyEnabled
        ? 'CurrencyIsoCode, '
        : '';
    }
  }

  public static kugo2p__SalesOrder__c getSalesOrder(Id soId) {
    //SalesOrder = [select Name, kugo2p__Account__c, kugo2p__Account__r.Name, kugo2p__Opportunity__c, kugo2p__OrderDate__c, kugo2p__PriceBookName__c, kugo2p__DateRequired__c, kugo2p__ServiceDateRequired__c, kugo2p__PaymentTerms__c, kugo2p__BillingFrequency__c, kugo2p__RecordStatus__c, kugo2p__DiscountPercent__c, kugo2p__BalanceDueAmount__c, kugo2p__PaymentStatus2__c, kugo2p__ContactBilling__c, kugo2p__ContactBuying__c, kugo2p__ContactBuying__r.Name, Market__c, Market__r.Publication_Year__c, FinanceTerm__c, FinanceOverride__c from kugo2p__SalesOrder__c where Id = : SalesOrder.Id];
    return Database.query(
      'select Id, Name, ' +
      CurrencyIsoCodeField +
      'kugo2p__Account__c, kugo2p__Account__r.Name,' +
      'kugo2p__Opportunity__c, kugo2p__OrderDate__c, kugo2p__PriceBookName__c, kugo2p__DateRequired__c, kugo2p__ServiceDateRequired__c, kugo2p__PaymentTerms__c,' +
      'kugo2p__BillingFrequency__c, kugo2p__RecordStatus__c, kugo2p__PaymentMethod__c, kugo2p__DiscountPercent__c, kugo2p__ShipToStreet__c ' +
      // FS04 changes
      ', kugo2p__BalanceDueAmount__c, kugo2p__PaymentStatus2__c, kugo2p__ProductDiscountAmount__c, kugo2p__ContactBilling__c, kugo2p__ContactBuying__c, kugo2p__ContactBuying__r.Name, Market__c, Market__r.Publication_Year__c, FinanceTerm__c, FinanceOverride__c ' +
      ' from kugo2p__SalesOrder__c where Id = :soId'
    );
  }

  public static void DataSetup() {
    kugo2p.Kugamon.TestMode = true;

    // this is a workaround solution to enable Standard Price Book
    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update standardPricebook;

    // create Kugamon Settings
    system.assertNotEquals(KugamonSettings.Id, null);

    // create Invoice Schedules
    // system.assertEquals(InvoiceSchedules.isEmpty(), false);

    // create processor Connection and Payment Settings
    // system.assertNotEquals(ProcessorConnection.Id, null);

    // system.assertEquals(Products.isEmpty(), false);
    // system.assertEquals(APDs.isEmpty(), false);

    // system.assertEquals(tiers.isEmpty(), false);
    // system.assertEquals(kitBundleMembers.isEmpty(), false);
    // system.assertEquals(RecommendedProducts.isEmpty(), false);

    // system.assertNotEquals(AdditionalAccountDetail.Id, null);

    // create oppty and line items
    //system.assertEquals(opportunity.isEmpty(), false);
    // system.assertEquals(oppLineItems.isEmpty(), false);

    // create sales quote, product and service lines
    // system.assertEquals(QuoteProductLines.isEmpty(), false);
    // system.assertEquals(QuoteServiceLines.isEmpty(), false);
    // system.assertEquals(QuoteOptionalLines.isEmpty(), false);

    // create sales order, product and service lines
    // system.assertEquals(OrderProductLines.isEmpty(), false);
    // system.assertEquals(OrderServiceLines.isEmpty(), false);

    // create Quote and Order Acc lines
    // system.assertEquals(QuoteACCs.isEmpty(), false);
    // system.assertEquals(OrderACCs.isEmpty(), false);

    // create invoice and its relationship
    // system.assertNotEquals(Invoice.Id, null);
    // system.assertEquals(InvoiceLines.isEmpty(), false);
    // system.assertEquals(InvoiceACCs.isEmpty(), false);

    kugo2p__OrderInvoiceRelationship__c oir = new kugo2p__OrderInvoiceRelationship__c(
      kugo2p__Invoice__c = Invoice.Id,
      kugo2p__SalesOrder__c = SalesOrder.Id
    );
    insert oir;

    //Kugamon.refreshSalesQuote(SalesQuote.Id);
    //Kugamon.refreshSalesOrder(SalesOrder.Id);
    //Kugamon.refreshInvoices(new set<Id> {Invoice.Id});

    // FS04 - Five Star changes
    // system.assertEquals(FinanceChargeRules.isEmpty(), false);
  }

  public static String StandardPriceBookName = 'Standard Price Book';
  public static Id StandardPriceBookId {
    get {
      if (StandardPriceBookId == null) {
        StandardPriceBookId = Test.getStandardPricebookId();
      }
      return StandardPriceBookId;
    }
    private set;
  }

  private static Pricebook2 CustomPriceBook {
    get {
      if (CustomPriceBook == null) {
        CustomPriceBook = new Pricebook2(
          Name = 'SF Market',
          IsActive = true,
          Description = 'Test'
        );
        insert CustomPriceBook;
      }
      return CustomPriceBook;
    }
    private set;
  }

  public static kugo2p__KugamonSetting__c KugamonSettings {
    get {
      if (KugamonSettings == null) {
        KugamonSettings = TestFactory.kugamonSettings();
        // //KugamonSettings = kuga_sub_ManageLinesController.Settings;
        // KugamonSettings = new kugo2p__KugamonSetting__c(
        //   Name = 'My Org Setting',
        //   kugo2p__PriceBookName__c = CustomPriceBook.Name,
        //   // kugo2p__AccountingGroup__c = 'Business Sale',
        //   // kugo2p__AllowZeroUnitPrice__c = true,
        //   kugo2p__PrintSpecificTextandTerms__c = false /*kugo2p__WareHouse__c = buildWareHouse().Id ,*/,
        //   // kugo2p__MultiCurrencyEnabled__c = false,
        //   kugo2p__UnitOfMeasure__c = 'Each',
        //   kugo2p__TaxableExcise__c = false,
        //   kugo2p__TaxableSales__c = true,
        //   kugo2p__TaxableUsage__c = false,
        //   kugo2p__TaxableVat__c = false,
        //   kugo2p__AutoReleaseOrder__c = false,
        //   kugo2p__CompanyTextAndTerms__c = 'This legally binding Order Form is governed by the Master Subscription Agreement between Customer and Kugamon LLC. Prices shown do not include any taxes that may apply. Any such taxes are the responsibility of Customer. Sandbox subscriptions, if ordered, are for testing and development use only and not for production use. Subscriptions are non-cancelable before their End Date.',
        //   kugo2p__PrintCompanyTextAndTerms__c = true,
        //   kugo2p__SpecificTextandTerms__c = 'Specific Terms & Conditions',
        //   kugo2p__PrintInvoiceTextandTerms__c = true,
        //   kugo2p__InvoiceTextandTerms__c = 'Invoice Terms',
        //   kugo2p__PaymentMethod__c = 'Debit/Credit Card',
        //   kugo2p__PaymentTerms__c = 'Due Upon Receipt',
        //   kugo2p__DaysTillPaymentDue__c = 0,
        //   kugo2p__Admin_User__c = UserInfo.getUserId(),
        //   kugo2p__OnlinePaymentButton__c = 'Accept & Pay',
        //   kugo2p__OnlineConfirmationTextandTerms__c = 'Confirmation Text',
        //   kugo2p__AutoClosedLostQuote__c = false,
        //   kugo2p__AutoCancelOrder__c = false,
        //   kugo2p__AllowOverrideServiceDateUpdate__c = true
        // );
        // insert KugamonSettings;

        KugamonSettings.kugo2p__WareHouse__c = warehouses[0].Id;
        update KugamonSettings;
      }
      return KugamonSettings;
    }
    private set;
  }

  public static list<kugo2p__InvoiceSchedule__c> InvoiceSchedules {
    get {
      if (InvoiceSchedules == null) {
        invoiceschedules = new List<kugo2p__InvoiceSchedule__c>{
          new kugo2p__InvoiceSchedule__c(
            Name = 'One-Time Invoicing',
            kugo2p__Description__c = 'One-Time Invoicing',
            kugo2p__SchedulePeriod__c = null,
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          ),
          new kugo2p__InvoiceSchedule__c(
            Name = 'Yearly Invoicing',
            kugo2p__Description__c = 'Yearly Invoicing',
            kugo2p__SchedulePeriod__c = 'Annually',
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          ),
          new kugo2p__InvoiceSchedule__c(
            Name = 'Quarterly Invoicing',
            kugo2p__Description__c = 'Quarterly Invoicing',
            kugo2p__SchedulePeriod__c = 'Quarterly',
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          ),
          new kugo2p__InvoiceSchedule__c(
            Name = 'Monthly Invoicing',
            kugo2p__Description__c = 'Monthly Invoicing',
            kugo2p__SchedulePeriod__c = 'Monthly',
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          ),
          new kugo2p__InvoiceSchedule__c(
            Name = 'Weekly Invoicing',
            kugo2p__Description__c = 'Weekly Invoicing',
            kugo2p__SchedulePeriod__c = 'Weekly',
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          ),
          new kugo2p__InvoiceSchedule__c(
            Name = 'Daily Invoicing',
            kugo2p__Description__c = 'Daily Invoicing',
            kugo2p__SchedulePeriod__c = 'Daily',
            kugo2p__ServicesInvoicedAtServiceStart__c = true,
            kugo2p__KugamonSetting__c = KugamonSettings.Id
          )
        };

        insert invoiceschedules;
      }
      return invoiceschedules;
    }
    private set;
  }

  public static kugo2p__Settings__c PaymentSettings {
    get {
      if (PaymentSettings == null) {
        PaymentSettings = new kugo2p__Settings__c(
          Name = 'Test Payment Settings',
          kugo2p__Gateway_Simulation_Mode__c = true,
          kugo2p__Admin_User__c = UserInfo.getUserId()
        );
        insert PaymentSettings;
      }
      return PaymentSettings;
    }
    private set;
  }

  public static kugo2p__Processor_Connection__c ProcessorConnection {
    get {
      if (ProcessorConnection == null) {
        ProcessorConnection = new kugo2p__Processor_Connection__c(
          Name = 'Test Processor Connection',
          kugo2p__Account_Type__c = 'Website Payments Pro',
          kugo2p__PaymentConnect_Setup__c = PaymentSettings.Id,
          kugo2p__Default_Connection__c = true,
          kugo2p__Assigned_To_Terminal__c = true,
          kugo2p__Processor_Id__c = 'Authorize.Net',
          kugo2p__Enabled_Card_Types__c = 'Visa; Mastercard; Amex; Discover',
          kugo2p__Site_Checkout__c = 'Both',
          kugo2p__PDF_Checkout__c = 'Native',
          kugo2p__Tokenized_Card_Service_Enabled__c = true,
          kugo2p__Test_Mode__c = true,
          kugo2p__Notification_Relay_Method__c = 'Visualforce',
          kugo2p__Relay_Id__c = 'kugo2p__AuthNetRelay',
          kugo2p__Relay_Script__c = 'https://kugamon-customdoc-developer-edition.na15.force.com/kugo2p__AuthNetRelay'
        );
        insert ProcessorConnection;
      }
      return ProcessorConnection;
    }
    private set;
  }

  public static list<kugo2p__Warehouse__c> warehouses {
    get {
      if (warehouses == null) {
        warehouses = new List<kugo2p__Warehouse__c>{
          new kugo2p__Warehouse__c(
            kugo2p__KugamonSetting__c = KugamonSettings.Id,
            Name = 'Main Warehouse',
            kugo2p__Description__c = 'Main Warehouse',
            kugo2p__WarehouseStreet__c = '1 Market Street',
            kugo2p__WareHouseCity__c = 'San Francisco',
            kugo2p__WareHouseStateProvince__c = 'California',
            kugo2p__WareHouseZipPostalCode__c = '80005',
            kugo2p__WareHouseCountry__c = 'United States'
          ),
          new kugo2p__Warehouse__c(
            kugo2p__KugamonSetting__c = KugamonSettings.Id,
            Name = 'International Warehouse',
            kugo2p__Description__c = 'International Warehouse',
            kugo2p__WarehouseStreet__c = '1 Bazaar Street',
            kugo2p__WareHouseCity__c = 'Chennai',
            kugo2p__WareHouseStateProvince__c = 'Tamil Nadu',
            kugo2p__WareHouseZipPostalCode__c = '600001',
            kugo2p__WareHouseCountry__c = 'India'
          )
        };
        insert warehouses;
      }
      return warehouses;
    }
    private set;
  }

  public static list<Product2> Products {
    get {
      if (Products == null) {
        Products = new List<Product2>{
          new Product2(
            Name = 'Test GenWatt Bundle',
            ProductCode = 'GC1040',
            Family = 'Test Product',
            IsActive = true
          ),
          new Product2(
            Name = 'Test Service Bundle',
            ProductCode = 'GC1041',
            Family = 'Test Service',
            IsActive = true
          ),
          new Product2(
            Name = 'Kit Member Product 1',
            ProductCode = 'GC1040',
            Family = 'Test Product',
            IsActive = true
          ),
          new Product2(
            Name = 'Kit Member Service 1',
            ProductCode = 'GC1041',
            Family = 'Test Service',
            IsActive = true
          )
        };

        insert Products;

        // system.assertEquals(APDs.size() > 0, true);
        // system.assertEquals(PricebookEntries.isEmpty(), false);
      }
      return Products;
    }
    private set;
  }

  public static list<kugo2p__AdditionalProductDetail__c> APDs {
    get {
      if (APDs == null) {
        APDs = [
          SELECT
            Id,
            Name,
            kugo2p__UnitofTerm__c,
            kugo2p__UnitofMeasure__c,
            kugo2p__ProductDescription__c,
            kugo2p__ProductFamily__c,
            kugo2p__ReferenceProduct__c,
            kugo2p__Service__c,
            kugo2p__StandardPrice__c,
            kugo2p__UnitCost__c,
            kugo2p__Active__c,
            RecipientLimit__c
          FROM kugo2p__AdditionalProductDetail__c
          WHERE kugo2p__ReferenceProduct__c IN :Products
        ];
        // Product - Bundle
        if ( APDs.size() > 2){
          APDs[0].kugo2p__Service__c = false;
          APDs[0].kugo2p__PrintProductTextandTerms__c = true;
          APDs[0].kugo2p__KitBundle__c = true;
          APDs[0].kugo2p__KitBundlePricing__c = 'Member Prices Only';
          // Five Star changes
          APDs[0].RecipientLimit__c = '1';
          APDs[0].LockPrice__c = true;
          APDs[0].CreateOrderFulfillment__c = true;
          APDs[0].NumberofOrderFulfillments__c = 1;

          // Service - Bundle
          APDs[1].kugo2p__Service__c = true;
          APDs[1].kugo2p__UnitofTerm__c = 'Month';
          APDs[1].kugo2p__PrintProductTextandTerms__c = true;
          APDs[1].kugo2p__KitBundle__c = true;
          APDs[1].kugo2p__KitBundlePricing__c = 'Member Prices Only';
          // Five Star changes
          //APDs[1].RecipientLimit__c = 'No Limit';
          APDs[1].RecipientLimit__c = '1';
          APDs[1].LockPrice__c = true;
          APDs[1].CreateOrderFulfillment__c = true;
          APDs[1].NumberofOrderFulfillments__c = 2;

          // Product - Kit Member
          APDs[2].kugo2p__Service__c = false;
          APDs[2].kugo2p__PrintProductTextandTerms__c = true;
          // Five Star changes
          APDs[2].RecipientLimit__c = '1';
          APDs[2].LockPrice__c = true;
          APDs[2].CreateOrderFulfillment__c = true;
          APDs[2].NumberofOrderFulfillments__c = 3;

          // Service - Kit Member
          APDs[3].kugo2p__Service__c = true;
          APDs[3].kugo2p__UnitofTerm__c = 'Month';
          APDs[3].kugo2p__PrintProductTextandTerms__c = true;
          // Five Star changes
          APDs[2].RecipientLimit__c = '1';
          APDs[2].LockPrice__c = true;
          APDs[2].CreateOrderFulfillment__c = true;
          APDs[2].NumberofOrderFulfillments__c = 4;
        }
        update APDs;
      }
      return APDs;
    }
    private set;
  }

  public static list<PricebookEntry> PricebookEntries {
    get {
      if (PricebookEntries == null) {
        PricebookEntries = new List<PricebookEntry>{
          // kit Bundle
          new PricebookEntry(
            Product2Id = Products[0].Id,
            Pricebook2Id = StandardPriceBookId,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 10
          ),
          new PricebookEntry(
            Product2Id = Products[1].Id,
            Pricebook2Id = StandardPriceBookId,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 20
          ),
          new PricebookEntry(
            Product2Id = Products[0].Id,
            Pricebook2Id = CustomPriceBook.Id,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 100
          ),
          new PricebookEntry(
            Product2Id = Products[1].Id,
            Pricebook2Id = CustomPriceBook.Id,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 200
          ),
          // kit Members
          new PricebookEntry(
            Product2Id = Products[2].Id,
            Pricebook2Id = StandardPriceBookId,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 30
          ),
          new PricebookEntry(
            Product2Id = Products[3].Id,
            Pricebook2Id = StandardPriceBookId,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 40
          ),
          new PricebookEntry(
            Product2Id = Products[2].Id,
            Pricebook2Id = CustomPriceBook.Id,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 300
          ),
          new PricebookEntry(
            Product2Id = Products[3].Id,
            Pricebook2Id = CustomPriceBook.Id,
            IsActive = true,
            UseStandardPrice = false,
            UnitPrice = 400
          )
        };
        insert PricebookEntries;
      }
      return PricebookEntries;
    }
    private set;
  }

  public static list<kugo2p__TieredPricing__c> tieredPricing {
    get {
      if (tieredPricing == null) {
        tieredPricing = new List<kugo2p__TieredPricing__c>{
          new kugo2p__TieredPricing__c(
            Name = 'Summer Product pricing',
            kugo2p__IsActive__c = true,
            kugo2p__Pricebook2Id__c = CustomPriceBook.Id,
            kugo2p__PriceBookName__c = CustomPriceBook.Name,
            kugo2p__Product__c = Products[0].Id
          ),
          new kugo2p__TieredPricing__c(
            Name = 'Summer Service pricing',
            kugo2p__IsActive__c = true,
            kugo2p__Pricebook2Id__c = CustomPriceBook.Id,
            kugo2p__PriceBookName__c = CustomPriceBook.Name,
            kugo2p__Product__c = Products[1].Id
          )
        };
        insert tieredPricing;
      }
      return tieredPricing;
    }
    private set;
  }

  public static list<kugo2p__Tier__c> tiers {
    get {
      if (tiers == null) {
        tiers = new List<kugo2p__Tier__c>{
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[0].Id,
            kugo2p__QuantityStart__c = 10,
            kugo2p__TierPrice__c = 10.00
          ),
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[0].Id,
            kugo2p__QuantityStart__c = 20,
            kugo2p__TierPrice__c = 20.00
          ),
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[0].Id,
            kugo2p__QuantityStart__c = 30,
            kugo2p__TierPrice__c = 30.00
          ),
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[1].Id,
            kugo2p__QuantityStart__c = 100,
            kugo2p__TierPrice__c = 15.00
          ),
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[1].Id,
            kugo2p__QuantityStart__c = 200,
            kugo2p__TierPrice__c = 25.00
          ),
          new kugo2p__Tier__c(
            kugo2p__TieredPricing__c = tieredPricing[1].Id,
            kugo2p__QuantityStart__c = 300,
            kugo2p__TierPrice__c = 35.00
          )
        };
        insert tiers;
      }
      return tiers;
    }
    private set;
  }

  public static list<RecommendedProduct__c> RecommendedProducts {
    get {
      if (RecommendedProducts == null) {
        RecommendedProducts = new List<RecommendedProduct__c>{
          new RecommendedProduct__c(
            Product__c = Products[0].Id,
            ReferenceProduct__c = Products[1].Id,
            Quantity__c = 1
          ),
          new RecommendedProduct__c(
            Product__c = Products[1].Id,
            ReferenceProduct__c = Products[0].Id,
            Quantity__c = 1
          )
        };

        insert RecommendedProducts;
      }

      return RecommendedProducts;
    }
    private set;
  }

  public static list<kugo2p__KitBundleMember__c> kitBundleMembers {
    get {
      if (kitBundleMembers == null) {
        kitBundleMembers = new List<kugo2p__KitBundleMember__c>{
          // Product Kit members
          new kugo2p__KitBundleMember__c(
            kugo2p__ReferenceKitBundle__c = APDs[0].Id,
            kugo2p__ReferenceMemberProductService__c = APDs[2].Id,
            kugo2p__AllowQuantityChange__c = true,
            kugo2p__Required__c = true,
            kugo2p__Quantity__c = 1
          ),
          new kugo2p__KitBundleMember__c(
            kugo2p__ReferenceKitBundle__c = APDs[0].Id,
            kugo2p__ReferenceMemberProductService__c = APDs[3].Id,
            kugo2p__AllowQuantityChange__c = false,
            kugo2p__Required__c = false,
            kugo2p__Quantity__c = 1
          ),
          // Service Kit members
          new kugo2p__KitBundleMember__c(
            kugo2p__ReferenceKitBundle__c = APDs[1].Id,
            kugo2p__ReferenceMemberProductService__c = APDs[3].Id,
            kugo2p__AllowQuantityChange__c = false,
            kugo2p__Required__c = true,
            kugo2p__Quantity__c = 1
          )
        };

        insert kitBundleMembers;
      }

      return kitBundleMembers;
    }
    private set;
  }

  public static Account account {
    get {
      if (account == null) {
        account = new Account(
          Name = 'Test Account',
          Type = 'Customer - Direct',
          BillingStreet = '3545 Ave',
          BillingState = 'California',
          BillingPostalCode = '95050',
          BillingCountry = 'United States',
          ShippingStreet = '525 Ave',
          ShippingCity = 'San Jose',
          ShippingState = 'California',
          ShippingPostalCode = '95050',
          ShippingCountry = 'United States',
          Phone = '(336) 222-7000',
          Fax = '(336) 222-8000',
          AccountNumber = 'Test ANo',
          Website = 'www.kkk.com',
          Industry = 'Apparel',
          AnnualRevenue = 350000000,
          NumberOfEmployees = 9000,
          Ownership = 'Public',
          TickerSymbol = 'BTXT',
          Description = 'Test Account',
          Site = ''
        );
        insert account;
      }
      return account;
    }
    private set;
  }

  public static kugo2p__AdditionalAccountDetail__c AdditionalAccountDetail {
    get {
      if (AdditionalAccountDetail == null) {
        try {
          AdditionalAccountDetail = [
            SELECT
              Id,
              kugo2p__PricebookName__c,
              kugo2p__Warehouse__c,
              kugo2p__PaymentMethod__c
            FROM kugo2p__AdditionalAccountDetail__c
            WHERE kugo2p__Account__c = :account.Id
          ];
          AdditionalAccountDetail.kugo2p__PricebookName__c = CustomPriceBook.Name;
          AdditionalAccountDetail.kugo2p__Warehouse__c = warehouses[0].Id;
          AdditionalAccountDetail.kugo2p__PaymentMethod__c = 'Check';
          AdditionalAccountDetail.kugo2p__ContactBilling__c = contacts[0].Id;
          AdditionalAccountDetail.kugo2p__ContactBuying__c = contacts[0].Id;

          update AdditionalAccountDetail;
        } catch (exception ex) {
          AdditionalAccountDetail = new kugo2p__AdditionalAccountDetail__c(
            kugo2p__Account__c = account.Id,
            kugo2p__PricebookName__c = CustomPriceBook.Name,
            kugo2p__Warehouse__c = warehouses[0].Id,
            kugo2p__PaymentMethod__c = 'Check',
            kugo2p__ContactBilling__c = contacts[0].Id,
            kugo2p__ContactBuying__c = contacts[0].Id
          );
          insert AdditionalAccountDetail;
        }
      }
      return AdditionalAccountDetail;
    }
    private set;
  }

  public static list<Contact> contacts {
    get {
      if (contacts == null) {
        contacts = new List<Contact>{
          new Contact(
            AccountId = account.Id,
            FirstName = 'Will',
            LastName = 'Smith',
            Phone = '333-333-3333',
            MailingStreet = '1 Kugamon Street',
            MailingState = 'California',
            MailingCity = 'San Francisco',
            MailingPostalCode = '95050',
            MailingCountry = 'United States',
            Awarded_Years__c = String.valueOf(system.today().year()),
            Market_Project__c = market.Id
          ),
          new Contact(
            AccountId = account.Id,
            FirstName = 'Michael',
            LastName = 'Jackson',
            Phone = '333-333-3333',
            MailingStreet = '1 Kugamon Street',
            MailingState = 'California',
            MailingCity = 'San Francisco',
            MailingPostalCode = '95050',
            MailingCountry = 'United States',
            Awarded_Years__c = String.valueOf(system.today().year()),
            Market_Project__c = market.Id
          )
        };
        insert contacts;
      }
      return contacts;
    }
    private set;
  }

  public static Market__c market {
    get {
      if (market == null) {
        market = new Market__c(
          Name = 'SF Market',
          publication_Year__c = String.valueOf(system.today().year()),
          Market_Close_Date__c = system.today().addDays(1)
        );

        insert market;
      }
      return market;
    }
    private set;
  }

  public static Opportunity opportunity {
    get {
      if (opportunity == null) {
        OpportunityStage stage = [
          SELECT MasterLabel
          FROM OpportunityStage
          WHERE IsWon = FALSE AND IsClosed = FALSE AND isActive = TRUE
          LIMIT 1
        ];
        system.debug(
          ' ### Queries: ' +
          Limits.getQueries() +
          '/' +
          Limits.getLimitQueries()
        );
        opportunity = new Opportunity(
          Name = 'Test Opp',
          AccountId = account.Id,
          StageName = stage.MasterLabel,
          CloseDate = system.today().addDays(-15),
          PriceBook2Id = StandardPriceBookId,
          Market_Project__c = market.Id,
          Next_call_date__c = system.today()
        );
        insert opportunity;

        //opportunity = [select Id, Name, AccountId, StageName, closeDate, PriceBook2Id, Pricebook2.Name from Opportunity where Id = : opportunity.Id];
        //system.debug(' ### opportunity ' + opportunity.PriceBook2Id + ' => ' + opportunity.Pricebook2.Name + ' opp ' + opportunity);
      }
      return opportunity;
    }
    private set;
  }

  public static list<OpportunityLineItem> oppLineItems {
    get {
      if (oppLineItems == null) {
        oppLineItems = new List<OpportunityLineItem>{
          new OpportunityLineItem(
            // Interest_Level__c = 'Interested',
            Description = 'Item 1',
            OpportunityId = opportunity.Id,
            Quantity = 1,
            ServiceDate = system.today(),
            pricebookEntryId = PricebookEntries[0].Id,
            TotalPrice = 100
          ),
          new OpportunityLineItem(
            // Interest_Level__c = 'Interested',
            Description = 'Item 2',
            OpportunityId = opportunity.Id,
            Quantity = 2,
            ServiceDate = system.today(),
            pricebookEntryId = PricebookEntries[1].Id,
            TotalPrice = 100
          )
        };
        insert oppLineItems;
      }
      return oppLineItems;
    }
    private set;
  }

  public static kugo2p__SalesOrder__c SalesOrder {
    get {
      if (SalesOrder == null) {
        SalesOrder = new kugo2p__SalesOrder__c(
          kugo2p__Account__c = account.Id,
          kugo2p__Opportunity__c = opportunity.Id,
          kugo2p__OrderDate__c = system.today(),
          kugo2p__PriceBookName__c = CustomPriceBook.Name,
          kugo2p__DiscountPercent__c = null,
          kugo2p__PaymentMethod__c = 'Authorize.Net',
          kugo2p__ContactShipping__c = contacts[0].Id,
          kugo2p__ContactBuying__c = contacts[0].Id,
          kugo2p__ContactBilling__c = contacts[0].Id,
          kugo2p__RecordStatus__c = 'Draft',
          kugo2p__Warehouse__c = warehouses[0].Id,
          kugo2p__ShipToStreet__c = 'https://kugamon.com/sitesurl',
          kugo2p__InvoiceSchedule__c = InvoiceSchedules[3].Id,
          // FS04 changes
          kugo2p__ShipToName__c = (contacts[0].FirstName +
          ' ' +
          contacts[0].LastName),
          kugo2p__ShipToStreetLong__c = contacts[0].MailingStreet,
          kugo2p__ShipToCity__c = contacts[0].MailingCity,
          kugo2p__ShipToStateProvince__c = contacts[0].MailingState,
          kugo2p__ShipToZipPostalCode__c = contacts[0].MailingPostalCode,
          Market__c = market.Id,
          FinanceOverride__c = true,
          Shipping_Type__c = 'Residential',
          FulfillOrder__c = false
        );
        insert SalesOrder;

        // update Sales Order to override Ship to Street address
        kugo2p__SalesOrder__c tempSO = new kugo2p__SalesOrder__c(
          Id = SalesOrder.Id,
          kugo2p__ShipToStreet__c = 'https://kugamon.com/sitesurl'
        );
        update tempSO;
      }
      return SalesOrder;
    }
    set;
  }

  public static list<kugo2p__SalesOrderProductLine__c> OrderProductLines {
    get {
      if (OrderProductLines == null) {
        OrderProductLines = new List<kugo2p__SalesOrderProductLine__c>{
          new kugo2p__SalesOrderProductLine__c(
            kugo2p__LineDescription__c = 'Item 1',
            kugo2p__SalesOrder__c = SalesOrder.id,
            kugo2p__Quantity__c = 10,
            // kugo2p__Product__c = APDs[0].Id,
            kugo2p__DateAvailableToPromise__c = System.today(),
            kugo2p__DateRequired__c = System.today(),
            kugo2p__ContactShipping__c = contacts[0].Id,
            kugo2p__OpportunityLineItemId__c = oppLineItems[0].Id,
            kugo2p__SalesQuoteProductLine__c = QuoteProductLines[0].Id,
            kugo2p__Warehouse__c = warehouses[0].Id
          )
        };
        // insert OrderProductLines;

        OrderProductLines = [
          SELECT
            Id,
            Name,
            kugo2p__SalesOrder__c,
            kugo2p__LineDescription__c,
            kugo2p__Quantity__c,
            kugo2p__ListPrice__c,
            kugo2p__SalesPrice__c,
            kugo2p__Product__c,
            kugo2p__DateRequired__c,
            kugo2p__ContactShipping__c,
            kugo2p__OpportunityLineItemId__c,
            kugo2p__SalesQuoteProductLine__c,
            kugo2p__SalesOrder__r.kugo2p__Account__c,
            kugo2p__Product__r.kugo2p__ReferenceProduct__r.Name,
            kugo2p__SalesOrder__r.kugo2p__ContactBuying__c,
            kugo2p__Product__r.kugo2p__ReferenceProduct__c,
            kugo2p__DiscountSalesPrice__c,
            kugo2p__DateAvailableToPromise__c,
            kugo2p__Warehouse__c
          FROM kugo2p__SalesOrderProductLine__c
          WHERE Id IN :OrderProductLines
        ];

        boolean updateSOPLs = false;
        for (kugo2p__SalesOrderProductLine__c sopl : OrderProductLines) {
          if (sopl.kugo2p__Warehouse__c != warehouses[0].Id) {
            updateSOPLs = true;
            sopl.kugo2p__Warehouse__c = warehouses[0].Id;
          }
        }
        system.debug(' ### updateSOPLs ' + updateSOPLs);
        if (updateSOPLs)
          update OrderProductLines;
      }
      return OrderProductLines;
    }
    private set;
  }

  public static list<kugo2p__SalesOrderServiceLine__c> OrderServiceLines {
    get {
      if (OrderServiceLines == null) {
        OrderServiceLines = new List<kugo2p__SalesOrderServiceLine__c>{
          new kugo2p__SalesOrderServiceLine__c(
            kugo2p__LineDescription__c = 'Item 2',
            kugo2p__SalesOrder__c = SalesOrder.Id,
            kugo2p__Quantity__c = 2,
            // kugo2p__Service__c = APDs[1].Id,
            kugo2p__DateServiceStart__c = System.today(),
            kugo2p__DateServiceEnd__c = System.today().addMonths(2),
            kugo2p__ServiceTerm__c = 2,
            kugo2p__OpportunityLineItemId__c = oppLineItems[1].Id,
            kugo2p__SalesQuoteServiceLine__c = QuoteServiceLines[0].Id
          )
        };

        // insert OrderServiceLines;

        // SalesOrder = getSalesOrder(SalesOrder.Id);
        //system.debug(' ### SalesOrder ' + SalesOrder.kugo2p__PriceBookName__c + ' => ' + SalesOrder);
      }
      return OrderServiceLines;
    }
    private set;
  }

  public static list<kugo2p__AdditionalChargeCredit__c> accs {
    get {
      if (accs == null) {
        accs = new List<kugo2p__AdditionalChargeCredit__c>{
          new kugo2p__AdditionalChargeCredit__c(
            Name = 'Shipping Fee',
            kugo2p__UnitPrice__c = 25,
            kugo2p__IsActive__c = true
          ),
          new kugo2p__AdditionalChargeCredit__c(
            Name = 'Late Fee',
            kugo2p__UnitPrice__c = 50,
            kugo2p__IsActive__c = true
          )
        };

        insert accs;
      }
      return accs;
    }
    private set;
  }

  public static list<kugo2p__SalesQuoteAdditionalChargeCredit__c> QuoteACCs {
    get {
      if (QuoteACCs == null) {
        QuoteACCs = new List<kugo2p__SalesQuoteAdditionalChargeCredit__c>{
          new kugo2p__SalesQuoteAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[0].Id,
            kugo2p__SalesQuote__c = SalesQuote.Id,
            kugo2p__Quantity__c = 1,
            kugo2p__LineDescription__c = 'Acc Desc 1'
          ),
          new kugo2p__SalesQuoteAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[1].Id,
            kugo2p__SalesQuote__c = SalesQuote.Id,
            kugo2p__Quantity__c = 2,
            kugo2p__LineDescription__c = 'Acc Desc 2'
          )
        };
        insert QuoteACCs;
      }
      return QuoteACCs;
    }
    private set;
  }

  public static list<kugo2p__SalesOrderAdditionalChargeCredit__c> OrderACCs {
    get {
      if (OrderACCs == null) {
        OrderACCs = new List<kugo2p__SalesOrderAdditionalChargeCredit__c>{
          new kugo2p__SalesOrderAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[0].Id,
            kugo2p__SalesOrder__c = SalesOrder.Id,
            kugo2p__Quantity__c = 1,
            kugo2p__LineDescription__c = 'Acc Desc 1'
          ),
          new kugo2p__SalesOrderAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[1].Id,
            kugo2p__SalesOrder__c = SalesOrder.Id,
            kugo2p__Quantity__c = 2,
            kugo2p__LineDescription__c = 'Acc Desc 2'
          )
        };
        insert OrderACCs;
      }
      return OrderACCs;
    }
    private set;
  }

  public static kugo2p__SalesQuote__c SalesQuote {
    get {
      if (SalesQuote == null) {
        SalesQuote = new kugo2p__SalesQuote__c(
          kugo2p__Account__c = Account.Id,
          kugo2p__Opportunity__c = opportunity.Id,
          kugo2p__PriceBookName__c = CustomPriceBook.Name,
          kugo2p__Warehouse__c = warehouses[0].Id
        );
        insert SalesQuote;
      }
      return SalesQuote;
    }
    private set;
  }

  public static list<kugo2p__SalesQuoteProductLine__c> QuoteProductLines {
    get {
      if (QuoteProductLines == null) {
        QuoteProductLines = new List<kugo2p__SalesQuoteProductLine__c>{
          new kugo2p__SalesQuoteProductLine__c(
            kugo2p__LineDescription__c = 'Item 1',
            kugo2p__SalesQuote__c = SalesQuote.Id,
            kugo2p__Quantity__c = 1,
            // kugo2p__Product__c = APDs[0].Id,
            kugo2p__DateRequired__c = system.today().addMonths(2),
            kugo2p__OpportunityLineItemId__c = oppLineItems[0].Id
          )
        };
        // insert QuoteProductLines;
      }

      return QuoteProductLines;
    }
    private set;
  }

  public static list<kugo2p__SalesQuoteServiceLine__c> QuoteServiceLines {
    get {
      if (QuoteServiceLines == null) {
        QuoteServiceLines = new List<kugo2p__SalesQuoteServiceLine__c>{
          new kugo2p__SalesQuoteServiceLine__c(
            kugo2p__LineDescription__c = 'Item 2',
            kugo2p__SalesQuote__c = SalesQuote.Id,
            kugo2p__Quantity__c = 3,
            // kugo2p__Service__c = APDs[1].Id,
            kugo2p__DateServiceStart__c = system.today().addMonths(2),
            kugo2p__DateServiceEnd__c = system.today().addMonths(4),
            kugo2p__ServiceTerm__c = 2,
            kugo2p__OpportunityLineItemId__c = oppLineItems[1].Id
          )
        };
        // insert QuoteServiceLines;
      }

      return QuoteServiceLines;
    }
    private set;
  }

  public static list<kugo2p__SalesQuoteOptionalLine__c> QuoteOptionalLines {
    get {
      if (QuoteOptionalLines == null) {
        QuoteOptionalLines = new List<kugo2p__SalesQuoteOptionalLine__c>{
          new kugo2p__SalesQuoteOptionalLine__c(
            kugo2p__SalesQuote__c = SalesQuote.Id,
            // kugo2p__ProductService__c = apds[0].Id,
            kugo2p__ListPrice__c = 100,
            kugo2p__SalesPrice__c = 85,
            kugo2p__LineDescription__c = 'Optional product'
          ),
          new kugo2p__SalesQuoteOptionalLine__c(
            kugo2p__SalesQuote__c = SalesQuote.Id,
            // kugo2p__ProductService__c = apds[1].Id,
            kugo2p__ListPrice__c = 100,
            kugo2p__SalesPrice__c = 85,
            kugo2p__LineDescription__c = 'Optional service'
          )
        };
        insert QuoteOptionalLines;
      }
      return QuoteOptionalLines;
    }
    private set;
  }

  public static kugo2p__KugamonInvoice__c Invoice {
    get {
      if (Invoice == null) {
        Invoice = new kugo2p__KugamonInvoice__c(
          kugo2p__Account__c = account.Id,
          kugo2p__AdditionalAccountDetail__c = AdditionalAccountDetail.Id,
          kugo2p__InvoiceDate__c = Date.today(),
          kugo2p__InvoiceDueDate__c = Date.today().addDays(4),
          kugo2p__RecordStatus__c = 'Unsent',
          kugo2p__ContactBilling__c = contacts[0].Id
        );
        insert invoice;
      }
      return Invoice;
    }
    private set;
  }

  public static list<kugo2p__KugamonInvoiceLine__c> InvoiceLines {
    get {
      if (InvoiceLines == null) {
        InvoiceLines = new List<kugo2p__KugamonInvoiceLine__c>{
          new kugo2p__KugamonInvoiceLine__c(
            kugo2p__Invoice__c = Invoice.Id,
            kugo2p__SalesOrder__c = SalesOrder.Id,
            // kugo2p__SalesOrderProductLine__c = OrderProductLines[0].Id,
            // kugo2p__ProductService__c = apds[0].Id,
            // kugo2p__UnitOfMeasure__c = apds[0].kugo2p__UnitOfMeasure__c,
            // kugo2p__UnitOfTerm__c = apds[0].kugo2p__UnitOfTerm__c, //ShipmentLine__c = shipmentLine.Id,
            kugo2p__CalculatedQuantity__c = 1,
            kugo2p__Quantity__c = 1//,
            // kugo2p__LineDescription__c = OrderProductLines[0].kugo2p__LineDescription__c
          ),
          new kugo2p__KugamonInvoiceLine__c(
            kugo2p__Invoice__c = Invoice.Id,
            kugo2p__SalesOrder__c = SalesOrder.Id,
            kugo2p__SalesOrderServiceLine__c = OrderServiceLines[0].Id,
            // kugo2p__ProductService__c = apds[1].Id,
            // kugo2p__UnitOfMeasure__c = apds[1].kugo2p__UnitOfMeasure__c,
            // kugo2p__UnitOfTerm__c = apds[1].kugo2p__UnitOfTerm__c, //ShipmentLine__c = shipmentLine.Id,
            kugo2p__CalculatedQuantity__c = 1,
            kugo2p__Quantity__c = 1,
            kugo2p__LineDescription__c = OrderServiceLines[0]
              .kugo2p__LineDescription__c
          )
        };
        insert InvoiceLines;
      }
      return InvoiceLines;
    }
    private set;
  }

  public static list<kugo2p__KugamonInvoiceAdditionalChargeCredit__c> InvoiceACCs {
    get {
      if (InvoiceACCs == null) {
        InvoiceACCs = new List<kugo2p__KugamonInvoiceAdditionalChargeCredit__c>{
          new kugo2p__KugamonInvoiceAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[0].Id,
            kugo2p__Invoice__c = Invoice.Id,
            kugo2p__Quantity__c = 1,
            kugo2p__LineDescription__c = 'Acc Desc 1'
          ),
          new kugo2p__KugamonInvoiceAdditionalChargeCredit__c(
            kugo2p__AdditionalChargeCredit__c = accs[1].Id,
            kugo2p__Invoice__c = Invoice.Id,
            kugo2p__Quantity__c = 2,
            kugo2p__LineDescription__c = 'Acc Desc 2'
          )
        };
        insert InvoiceACCs;
      }
      return InvoiceACCs;
    }
    private set;
  }

  public static list<LineRecipient__c> LineRecipients {
    get {
      if (LineRecipients == null) {
        LineRecipients = new List<LineRecipient__c>{
          new LineRecipient__c(
            Order__c = salesOrder.Id,
            // OrderProductLine__c = OrderProductLines[0].Id,
            OrderServiceLine__c = null,
            Recipient__c = contacts[1].Id,
            Primary__c = true
          )
        };
        // insert LineRecipients;
      }
      return LineRecipients;
    }
    private set;
  }

  public static kugo2p__Payment_Profile__c RecurringCharge {
    get {
      if (RecurringCharge == null) {
        RecurringCharge = new kugo2p__Payment_Profile__c(
          Name = 'Test Profile',
          kugo2p__AuthNet_Subscription_Id__c = '13224sskjfs',
          kugo2p__SalesOrder__c = salesOrder.Id,
          kugo2p__Contact__c = contacts[0].Id,
          kugo2p__Amount__c = salesOrder.kugo2p__BalanceDueAmount__c,
          kugo2p__Subscription_Status__c = 'Not Active',
          kugo2p__Frequency__c = 1,
          kugo2p__Period__c = 'Month',
          kugo2p__Total_Occurrences__c = 1
        );

        insert RecurringCharge;
      }
      return RecurringCharge;
    }
    private set;
  }

  // FS04 - Five Star changes
  public static list<kuga_FinanceChargeRule__c> FinanceChargeRules {
    get {
      if (FinanceChargeRules == null) {
        delete [
          SELECT Id
          FROM kuga_FinanceChargeRule__c
          WHERE kuga_Term__c = 3
        ];

        FinanceChargeRules = new List<kuga_FinanceChargeRule__c>{
          new kuga_FinanceChargeRule__c(
            kuga_KugamonSetting__c = KugamonSettings.Id,
            kuga_IsFinanceCharged__c = true,
            kuga_IsFinanceOverride__c = false,
            kuga_MinimumInitialPaymentAmount__c = 3,
            kuga_MinimumOrderAmount__c = 3,
            kuga_Term__c = 3
          )
        };
        insert FinanceChargeRules;
      }
      return FinanceChargeRules;
    }
    private set;
  }
}