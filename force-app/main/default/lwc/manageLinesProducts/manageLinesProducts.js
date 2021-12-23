import { LightningElement, api, track } from "lwc";
import doQuery from "@salesforce/apex/LWC.doQuery";
import saveRecord from "@salesforce/apex/LWC.saveRecord";
import deleteRecord from "@salesforce/apex/LWC.deleteRecord";
import { getMLRecord } from "c/manageLinesHelpers";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Id from "@salesforce/user/Id";
// ! slds-color__background_gray-4
export default class ManageLinesProducts extends LightningElement {
  userId = Id;
  userFavorites = [];
  numberOfProducts = 0;
  @api salesOrder;
  showRecordsValue = 25;
  showRecordsOptions = [];
  searchKeyword;
  isExactMatch = false;
  // pricebooks;
  errorMessage = null;
  // isPriceBookValid = true;
  products;
  transferredProducts;
  // isPriceBookChanged = false;
  // @api newPriceBookName;
  searchOptions = [];
  newSearchOptions = [];
  allProductNames = [];
  isPriceBookEditing = false;

  retrieveProducts = async () => {
    const searchStatement = this.isExactMatch
      ? ` AND (Product2.Name='${this.searchKeyword}' OR Product2.Base_Product__c='${this.searchKeyword}' OR Product2.ProductCode='${this.searchKeyword}' OR Product2.Description='${this.searchKeyword}')`
      : ` AND (Product2.Name LIKE '%${this.searchKeyword}%' OR Product2.Base_Product__c LIKE '%${this.searchKeyword}%' OR Product2.ProductCode LIKE '%${this.searchKeyword}%' OR Product2.Description LIKE '%${this.searchKeyword}%')`;

    const searchQuery = this.searchKeyword ? searchStatement : "";

    // const whereQuery = this.isPriceBookChanged
    //   ? `Pricebook2Id='${this.newPriceBookName}'`
    //   : `Pricebook2Id='${this.salesOrder.Price_Book__c}'`;

    const whereQuery = `Pricebook2Id='${this.salesOrder.Price_Book__c}'`;

    const [numberOfProducts, numberError] = await getMLRecord({
      getFunction: doQuery,
      objectType: "PricebookEntry",
      fields: "COUNT(Product2Id)",
      hasConditions: true,
      conditions: `WHERE ${whereQuery} AND isActive=True`
    });

    const [searchedProducts, searchError] = await getMLRecord({
      getFunction: doQuery,
      objectType: "PricebookEntry",
      fields:
        "Product2Id, Product2.IsKitBundle__c, Product2.ProductCode, Product2.Description, Product2.Name, Product2.Base_Product__c, Product2.Maximum_Quantity__c, Product2.Minimum_Quantity__c, Product2.Default_Quantity__c, Product2.Recipient_Limit__c, UnitPrice, Id",
      hasConditions: true,
      conditions: `WHERE ${whereQuery} AND isActive=True${searchQuery} ORDER BY Product2.Name`
    });

    if (searchError !== null || numberError !== null) {
      const errorMessage =
        searchError !== null
          ? "SEARCH ERROR: " + JSON.stringify(searchError)
          : "COUNT ERROR: " + JSON.stringify(numberError);
      console.error(errorMessage);
    } else {
      return [numberOfProducts[0].expr0, searchedProducts];
    }
  };

  retrieveFavorites = async () => {
    const [favorites, error] = await getMLRecord({
      getFunction: doQuery,
      objectType: "UserProduct__c",
      fields: "Id, Product__c",
      hasConditions: true,
      conditions: `WHERE OwnerId='${this.userId}' AND IsFavorite__c=true`
    });
    if (error !== null) {
      console.log("FAVORITES RETRIEVAL ERROR : ");
      console.error(error);
    } else {
      return favorites;
    }
  };

  handleFavoriteChange = async (evt) => {
    const product = { ...evt.detail };
    console.log(product);
    // ? check if favorite is unset and it's an existing record
    if (product.Product__c && !product.isFavorite) {
      const recordForDeletion = {
        sobjectType: "UserProduct__c",
        Id: product.Id
      };
      this.userFavorites = this.userFavorites.filter(
        (fave) => fave.Id !== recordForDeletion.Id
      );
      try {
        await deleteRecord({ record: recordForDeletion });
        this.template.querySelector("c-manage-lines-products-list") &&
          this.template
            .querySelector("c-manage-lines-products-list")
            .removeFavorite(product.Product__c);
      } catch (err) {
        console.log("DELETE FAVORITE ERROR : ");
        console.error(err);
      }
    } else {
      if (product.isFavorite) {
        const newFavorite = {
          sobjectType: "UserProduct__c",
          CreatedById: this.userId,
          IsFavorite__c: true,
          LastModifiedById: this.userId,
          OwnerId: this.userId,
          Product__c: product.Id,
          User__c: this.userId
        };
        try {
          const savedFavorite = await saveRecord({ record: newFavorite });
          const newFavoriteId = await savedFavorite.Id;
          product.Product__c = product.Id;
          product.Id = newFavoriteId;
          this.userFavorites = [...this.userFavorites, product];
          this.template.querySelector("c-manage-lines-favorites") &&
            this.template
              .querySelector("c-manage-lines-favorites")
              .updateData([...this.userFavorites]);
        } catch (err) {
          console.log("SAVE FAVORITE ERROR : ");
          console.error(err);
        }
      } else {
        const deleteFrom = this.userFavorites.find(
          (fave) => fave.Product__c === product.Id
        );
        this.userFavorites = this.userFavorites.filter(
          (fave) => fave.Id !== deleteFrom.Id
        );
        const recordForDeletion = {
          sobjectType: "UserProduct__c",
          Id: deleteFrom.Id
        };
        try {
          await deleteRecord({ record: recordForDeletion });
        } catch (err) {
          console.log("DELETE FAVORITE ERROR : ");
          console.error(err);
        }
      }
    }
  };

  //DONE: if quantity is less than the minimum allowed, change it to minimum
  //DONE: if quantity is greater than the maximum allowed, change it to maximum
  //DONE: send a warning toast event for both explaining what happened
  handleLineAdd = (event) => {
    const newOrderLine = event.detail;
    const productName = newOrderLine.Product__r.Name;
    const qty = Number(newOrderLine.Quantity__c);
    const minQty = Number(newOrderLine.Product__r.Minimum_Quantity__c);
    const maxQty = Number(newOrderLine.Product__r.Maximum_Quantity__c);
    const warningTitle = `Product line for ${newOrderLine.Product__r.Name} has been added with changes`;
    const toastParams = {
      title: `Product line for ${productName} has been added successfully without changes!`,
      message: "",
      variant: "Success",
      mode: "dismissable"
    };

    // newOrderLine.OrderDiscountPercent__c = Number(
    //   this.salesOrder.DiscountPercent__c
    // );
    if (qty < 1) {
      newOrderLine.Quantity__c = minQty ? minQty : 1;
    }

    if (minQty && qty < minQty) {
      newOrderLine.Quantity__c = minQty;
      toastParams.title = warningTitle;
      toastParams.message = `Quantity has been changed to this product's minimum allowed quantity, ${minQty}.`;
      toastParams.variant = "warning";
      toastParams.mode = "sticky";
    }

    if (maxQty && qty > maxQty) {
      newOrderLine.Quantity__c = maxQty;
      toastParams.title = warningTitle;
      toastParams.message = `Quantity has been changed to this product's maximum allowed quantity, ${maxQty}.`;
      toastParams.variant = "warning";
      toastParams.mode = "sticky";
    }

    // const totalAmount =
    //   Number(newOrderLine.Quantity__c) *
    //   (Number(newOrderLine.SalesPrice__c) *
    //     ((100 - newOrderLine.OrderDiscountPercent__c) / 100));
    // newOrderLine.TotalAmount__c = totalAmount.toFixed(2);

    // if (newOrderLine.bundleRecords) {
    //   newOrderLine.bundleRecords = JSON.parse(newOrderLine.bundleRecords).map(
    //     (rec) => {
    //       const price = this.products.find(p => p.Id == rec.Id).UnitPrice;
    //       const newRec = {
    //       AllowQuantityChange__c: rec.AllowQuantityChange__c,
    //       KitBundle__c: false,
    //       KitBundleMemberRequired__c: rec.Required__c,
    //       Product__c: rec.Id,
    //       SalesPrice__c: price,
    //       ListPrice__c: price,
    //     }
    //     return newRec;
    //   }
    //   );
    // }

    const addLineEvent = new CustomEvent("lineadd", {
      detail: newOrderLine
    });

    const toastEvent = new ShowToastEvent({
      title: toastParams.title,
      message: toastParams.message,
      variant: toastParams.variant,
      mode: toastParams.mode
    });
    this.dispatchEvent(toastEvent);
    this.dispatchEvent(addLineEvent);
  };

  loadContent = async () => {
    const [productCount, products] = await this.retrieveProducts();
    const favorites = await this.retrieveFavorites();
    const productNames = products.map((prod) => ({
      Name: prod.Product2.Name,
      Id: prod.Product2Id,
      Base_Product__c:
        prod.Product2.Base_Product__c && prod.Product2.Base_Product__c,
      ProductCode: prod.Product2.ProductCode && prod.Product2.ProductCode,
      Description: prod.Product2.Description && prod.Product2.Description
    }));
    this.allProductNames = productNames;
    this.errorMessage = null;
    if (products && productCount) {
      let favoriteProducts = [];
      if (favorites.length < 1) {
        this.products = products.map((prod) => ({
          ...prod,
          isFavorite: false,
          buttonVariant: "border",
          productUrl: `/lightning/r/Product2/${prod.Product2Id}/view`
        }));
      } else {
        products.forEach((prod) => {
          const matchedFavorite = favorites.find(
            (fave) => fave.Product__c == prod.Product2Id
          );
          if (matchedFavorite) {
            prod.isFavorite = true;
            prod.buttonVariant = "brand";
            favoriteProducts.push({
              ...matchedFavorite,
              productName: prod.Product2.Name,
              unitPrice: prod.UnitPrice,
              salesPrice: prod.UnitPrice,
              quantity: 0,
              productUrl: `/lightning/r/Product2/${prod.Product2Id}/view`,
              isFavorite: prod.isFavorite,
              buttonVariant: prod.buttonVariant,
              Maximum_Quantity__c: prod.Product2.Maximum_Quantity__c,
              Minimum_Quantity__c: prod.Product2.Minimum_Quantity__c,
              Default_Quantity__c: prod.Product2.Default_Quantity__c,
              Recipient_Limit__c: prod.Product2.Recipient_Limit__c,
              isKitBundle: prod.Product2.IsKitBundle__c
            });
          } else {
            prod.isFavorite = false;
            prod.buttonVariant = "border";
          }
        });
      }
      this.products = products;
      this.transferredProducts = products.slice(0, this.showRecordsValue);
      this.numberOfProducts = productCount;
      this.userFavorites = favoriteProducts;
    }
  };

  async connectedCallback() {
    const optionNumbers = [10, 25, 50, 100, 200];
    this.showRecordsOptions = optionNumbers.map((n) => ({
      key: n.toString(),
      value: n,
      isSelected: n === this.showRecordsValue
    }));
    await this.loadContent();
  }

  handleKeywordChange = (evt) => {
    const newKeyword = evt.detail.value.toLowerCase();
    this.searchKeyword = newKeyword;
    const newOptions = this.allProductNames.filter((prod) => {
      if (
        prod.Name.toLowerCase().includes(newKeyword) ||
        (prod.Base_Product__c &&
          prod.Base_Product__c.toLowerCase().includes(newKeyword)) ||
        (prod.ProductCode &&
          prod.ProductCode.toLowerCase().includes(newKeyword)) ||
        (prod.Description &&
          prod.Description.toLowerCase().includes(newKeyword))
      ) {
        return true;
      } else {
        return false;
      }
    });
    // Not a fan of this method but after consulting several sources this is apparently the only way for it to not throw an error
    this.newSearchOptions = [].concat(newOptions);
    this.searchOptions = [];
  };

  renderedCallback() {
    if (this.searchOptions.length !== this.newSearchOptions.length) {
      this.searchOptions = [].concat(this.newSearchOptions);
    }
  }

  handleSearch = async () => {
    // if (!this.isPriceBookValid) {
    //   this.errorMessage = "Please choose a valid Price Book first.";
    //   return;
    // }
    const [_, searchResult] = await this.retrieveProducts();
    const favoriteIds = this.userFavorites.map((fave) => fave.Product__c);
    this.products =
      searchResult &&
      searchResult.map((res) => {
        if (favoriteIds.some((id) => id === res.Product2Id)) {
          return {
            ...res,
            isFavorite: true,
            buttonVariant: "brand"
          };
        } else {
          return {
            ...res,
            isFavorite: false,
            buttonVariant: "border"
          };
        }
      });
    this.searchKeyword = null;
    this.isExactMatch = false;
    if (searchResult.length > 0) {
      this.template
        .querySelector("c-manage-lines-products-list")
        .loadData(this.products.slice(0, this.showRecordsValue));
    } else {
      this.template.querySelector("c-manage-lines-products-list").loadData();
    }
  };

  handleOptionSelect = async (evt) => {
    const selectedKeyword = evt.detail.name;
    console.log("SELECTED FOR : " + selectedKeyword);
    this.searchKeyword = selectedKeyword;
    this.isExactMatch = true;
    await this.handleSearch();
    this.isExactMatch = false;
  };

  handleKeyUp = async (evt) => {
    const isEnterKey = evt.keyCode === 13;
    if (isEnterKey) await this.handleSearch();
  };

  toggleExactMatch = (evt) => {
    this.isExactMatch = evt.target.checked;
  };

  handleShowRecords = (event) => {
    this.showRecordsValue = Number(event.target.value);
    console.log(event.target.value, " selected show record number");
    this.transferredProducts = null;
    setTimeout(() => {
      this.transferredProducts = this.products.slice(0, this.showRecordsValue);
    }, 1000);
  };

  onPriceBookChange = () => {
    const toastEvent = new ShowToastEvent({
      title: "Warning",
      message:
        "Changing the pricebook name will delete all of this sales order's related order product lines and recipients.",
      variant: "Warning",
      mode: "sticky"
    });
    this.dispatchEvent(toastEvent);
    this.isPriceBookEditing = true;
  };

  onPriceBookCancel = () => {
    this.isPriceBookEditing = false;
  };

  onPriceBookSave = (evt) => {
    const toastEvent = new ShowToastEvent({
      title: "The pricebook has been changed successfully",
      variant: "Success"
    });
    this.dispatchEvent(toastEvent);
    this.isPriceBookEditing = false;
    if (this.products.length > 0) {
      this.template
        .querySelector("c-manage-lines-products-list")
        .loadData(this.products);
    } else {
      this.template.querySelector("c-manage-lines-products-list").loadData();
    }
    this.dispatchEvent(new CustomEvent("pricebookchange"));
  };

  // retrievePricebooks = async () => {
  //   const [pricebooks, error] = await getMLRecord({
  //     getFunction: doQuery,
  //     objectType: "Pricebook2",
  //     fields: "Id, Name, isActive",
  //     hasConditions: true,
  //     conditions: `WHERE isActive=True ORDER BY Name`
  //   });
  //   if (error !== null) {
  //     console.error(error);
  //     return;
  //   } else {
  //     return pricebooks;
  //   }
  // };

  // loadContent = async () => {
  //   const priceBooks = await this.retrievePricebooks();
  //   const [productCount, products] = await this.retrieveProducts();
  //   const favorites = await this.retrieveFavorites();
  //   const productNames = products.map((prod) => ({
  //     Name: prod.Product2.Name,
  //     Id: prod.Product2Id,
  //     Base_Product__c:
  //       prod.Product2.Base_Product__c && prod.Product2.Base_Product__c,
  //     ProductCode: prod.Product2.ProductCode && prod.Product2.ProductCode,
  //     Description: prod.Product2.Description && prod.Product2.Description
  //   }));
  //   const priceBookName = this.newPriceBookName;
  //   this.allProductNames = productNames;
  //   if (priceBooks) {
  //     const isValid = priceBooks.some((pB) => pB.Name === priceBookName);
  //     if (!isValid) {
  //       this.errorMessage =
  //         "The default price book that you've entered is either inactive or invalid. Please choose a valid and active one.";
  //       this.isPriceBookValid = false;
  //     } else {
  //       this.errorMessage = null;
  //       this.isPriceBookValid = true;
  //       if (products && productCount) {
  //         let favoriteProducts = [];
  //         if (favorites.length < 1) {
  //           this.products = products.map((prod) => ({
  //             ...prod,
  //             isFavorite: false,
  //             buttonVariant: "border",
  //             productUrl: `/lightning/r/Product2/${prod.Product2Id}/view`
  //           }));
  //         } else {
  //           products.forEach((prod) => {
  //             const matchedFavorite = favorites.find(
  //               (fave) => fave.Product__c == prod.Product2Id
  //             );
  //             if (matchedFavorite) {
  //               prod.isFavorite = true;
  //               prod.buttonVariant = "brand";
  //               favoriteProducts.push({
  //                 ...matchedFavorite,
  //                 productName: prod.Product2.Name,
  //                 unitPrice: prod.UnitPrice,
  //                 salesPrice: prod.UnitPrice,
  //                 quantity: 0,
  //                 productUrl: `/lightning/r/Product2/${prod.Product2Id}/view`,
  //                 isFavorite: prod.isFavorite,
  //                 buttonVariant: prod.buttonVariant,
  //                 Maximum_Quantity__c: prod.Product2.Maximum_Quantity__c,
  //                 Minimum_Quantity__c: prod.Product2.Minimum_Quantity__c,
  //                 Default_Quantity__c: prod.Product2.Default_Quantity__c,
  //                 Recipient_Limit__c: prod.Product2.Recipient_Limit__c
  //               });
  //             } else {
  //               prod.isFavorite = false;
  //               prod.buttonVariant = "border";
  //             }
  //           });
  //         }
  //         this.products = products;
  //         this.transferredProducts = products.slice(0, this.showRecordsValue);
  //         this.numberOfProducts = productCount;
  //         this.userFavorites = favoriteProducts;
  //       }
  //     }
  //     this.pricebooks = priceBooks.map((pb) => ({
  //       ...pb,
  //       isSelected: pb.Name === priceBookName
  //     }));
  //   }
  // };

  // handlePricebookSelect = (evt) => {
  //   const doChange = confirm(
  //     "Changing a selected price book will delete all existing product and service lines from this order. Would you like to proceed?"
  //   );
  //   if (doChange == true) {
  //     try {
  //       const newPriceBookName = evt.target.value;
  //       this.newPriceBookName = newPriceBookName;
  //       this.isPriceBookChanged = true;
  //       this.searchKeyword = null;
  //       this.pricebooks = this.pricebooks.map((pb) => ({
  //         ...pb,
  //         isSelected: pb.Name === newPriceBookName
  //       }));
  //       this.searchKeyword = null;
  //       this.isExactMatch = false;
  //       if (this.products.length > 0) {
  //         this.template
  //           .querySelector("c-manage-lines-products-list")
  //           .loadData(this.products);
  //       } else {
  //         this.template
  //           .querySelector("c-manage-lines-products-list")
  //           .loadData();
  //       }

  //       this.dispatchEvent(
  //         new CustomEvent("pricebookchange", {
  //           detail: newPriceBookName
  //         })
  //       );
  //     } catch (err) {
  //       console.error(err);
  //     }
  //   } else {
  //     evt.target.value = this.salesOrder.PriceBookName__c;
  //   }
  // };
}