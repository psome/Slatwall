/*

    Slatwall - An Open Source eCommerce Platform
    Copyright (C) ten24, LLC
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
	
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
	
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    Linking this program statically or dynamically with other modules is
    making a combined work based on this program.  Thus, the terms and
    conditions of the GNU General Public License cover the whole
    combination.
	
    As a special exception, the copyright holders of this program give you
    permission to combine this program with independent modules and your 
    custom code, regardless of the license terms of these independent
    modules, and to copy and distribute the resulting program under terms 
    of your choice, provided that you follow these specific guidelines: 

	- You also meet the terms and conditions of the license of each 
	  independent module 
	- You must not alter the default display of the Slatwall name or logo from  
	  any part of the application 
	- Your custom code must not alter or create any files inside Slatwall, 
	  except in the following directories:
		/integrationServices/

	You may copy and distribute the modified version of this program that meets 
	the above guidelines as a combined work under the terms of GPL for this program, 
	provided that you include the source code of that other code when and as the 
	GNU GPL requires distribution of source code.
    
    If you modify this program, you may extend this exception to your version 
    of the program, but you are not obligated to do so.

Notes:

*/
component displayname="Product Type" entityname="SlatwallProductType" table="SlatwallProductType" persistent="true" extends="HibachiEntity" cacheuse="transactional" hb_serviceName="productService" hb_permission="this" hb_parentPropertyName="parentProductType" {
			
	// Persistent Properties
	property name="productTypeID" ormtype="string" length="32" fieldtype="id" generator="uuid" unsavedvalue="" default="";
	property name="productTypeIDPath" ormtype="string";
	property name="activeFlag" ormtype="boolean" hint="As A ProductType Get Old, They would be marked as Not Active";
	property name="publishedFlag" ormtype="boolean";
	property name="urlTitle" ormtype="string" unique="true" hint="This is the name that is used in the URL string";
	property name="productTypeName" ormtype="string";
	property name="productTypeDescription" ormtype="string" length="4000";
	property name="systemCode" ormtype="string";
	
	// Related Object Properties (Many-To-One)
	property name="parentProductType" cfc="ProductType" fieldtype="many-to-one" fkcolumn="parentProductTypeID";
	
	// Related Object Properties (One-To-Many)
	property name="childProductTypes" singularname="childProductType" cfc="ProductType" fieldtype="one-to-many" inverse="true" fkcolumn="parentProductTypeID" cascade="all";
	property name="products" singularname="product" cfc="Product" fieldtype="one-to-many" inverse="true" fkcolumn="productTypeID" lazy="extra" cascade="all";
	property name="attributeValues" singularname="attributeValue" cfc="AttributeValue" fieldtype="one-to-many" fkcolumn="productTypeID" cascade="all-delete-orphan" inverse="true";
	
	// Related Object Properties (Many-To-Many - inverse)
	property name="promotionRewards" singularname="promotionReward" cfc="PromotionReward" fieldtype="many-to-many" linktable="SlatwallPromotionRewardProductType" fkcolumn="productTypeID" inversejoincolumn="promotionRewardID" inverse="true";
	property name="promotionRewardExclusions" singularname="promotionRewardExclusion" cfc="PromotionReward" type="array" fieldtype="many-to-many" linktable="SlatwallPromotionRewardExcludedProductType" fkcolumn="productTypeID" inversejoincolumn="promotionRewardID" inverse="true";
	property name="promotionQualifiers" singularname="promotionQualifier" cfc="PromotionQualifier" fieldtype="many-to-many" linktable="SlatwallPromotionQualifierProductType" fkcolumn="productTypeID" inversejoincolumn="promotionQualifierID" inverse="true";
	property name="promotionQualifierExclusions" singularname="promotionQualifierExclusion" cfc="PromotionQualifier" type="array" fieldtype="many-to-many" linktable="SlatwallPromotionQualifierExcludedProductType" fkcolumn="productTypeID" inversejoincolumn="promotionQualifierID" inverse="true";
	property name="priceGroupRates" singularname="priceGroupRate" cfc="PriceGroupRate" fieldtype="many-to-many" linktable="SlatwallPriceGroupRateProductType" fkcolumn="productTypeID" inversejoincolumn="priceGroupRateID" inverse="true";
	property name="attributeSets" singularname="attributeSet" cfc="AttributeSet" type="array" fieldtype="many-to-many" linktable="SlatwallAttributeSetProductType" fkcolumn="productTypeID" inversejoincolumn="attributeSetID" inverse="true";
	property name="physicals" singularname="physical" cfc="Physical" type="array" fieldtype="many-to-many" linktable="SlatwallPhysicalProductType" fkcolumn="productTypeID" inversejoincolumn="physicalID" inverse="true";
	
	// Remote properties
	property name="remoteID" ormtype="string";
	
	// Audit properties
	property name="createdDateTime" hb_populateEnabled="false" ormtype="timestamp";
	property name="createdByAccount" hb_populateEnabled="false" cfc="Account" fieldtype="many-to-one" fkcolumn="createdByAccountID";
	property name="modifiedDateTime" hb_populateEnabled="false" ormtype="timestamp";
	property name="modifiedByAccount" hb_populateEnabled="false" cfc="Account" fieldtype="many-to-one" fkcolumn="modifiedByAccountID";
	
	// Non-Persistent Properties
	property name="parentProductTypeOptions" type="array" persistent="false";
	
	
	public array function getInheritedAttributeSetAssignments(){
		// Todo get by all the parent productTypeIDs
		var attributeSetAssignments = getService("AttributeService").getAttributeSetAssignmentSmartList().getRecords();
		if(!arrayLen(attributeSetAssignments)){
			attributeSetAssignments = [];
		}
		return attributeSetAssignments;
	}
	
	public void function setProducts(required array Products) {
		// first, clear existing collection
		variables.Products = [];
		for( var product in arguments.Products ) {
			addProduct(product);
		}
	}
	
	//get merchandisetype 
	public any function getBaseProductType() {
		if(isNull(getSystemCode()) || getSystemCode() == ""){
			return getService("ProductService").getProductType(listFirst(getProductTypeIDPath())).getSystemCode();
		}
		return getSystemCode();
	}
	
    public any function getAppliedPriceGroupRateByPriceGroup( required any priceGroup) {
		return getService("priceGroupService").getRateForProductTypeBasedOnPriceGroup(product=this, priceGroup=arguments.priceGroup);
	}
    
    // ============ START: Non-Persistent Property Methods =================
	public any function getParentProductTypeOptions( string baseProductType="" ) {
		if(!structKeyExists(variables, "parentProductTypeOptions")) {
			if( !len(arguments.baseProductType) ) {
				arguments.baseProductType = getBaseProductType();
			}
			
			var smartList = getPropertyOptionsSmartList( "parentProductType" );
			smartList.addLikeFilter( "productTypeIDPath", "#getService('productService').getProductTypeBySystemCode( arguments.baseProductType ).getProductTypeID()#%" );
			
			var records = smartList.getRecords();
			
			variables.parentProductTypeOptions = [];
			
			for(var i=1; i<=arrayLen(records); i++) {
				if(records[i].getProductTypeName() != getProductTypeName()) {
					arrayAppend(variables.parentProductTypeOptions, {name=records[i].getSimpleRepresentation(), value=records[i].getProductTypeID()});	
				}
			}
		}
		return variables.parentProductTypeOptions;
	}
	
	// ============  END:  Non-Persistent Property Methods =================
		
	// ============= START: Bidirectional Helper Methods ===================
	
	// Parent Product Type (many-to-one)
	public void function setParentProductType(required any parentProductType) {
		variables.parentProductType = arguments.parentProductType;
		if(isNew() or !arguments.parentProductType.hasChildProductType( this )) {
			arrayAppend(arguments.parentProductType.getChildProductTypes(), this);
		}
	}
	public void function removeParentProductType(any parentProductType) {
		if(!structKeyExists(arguments, "parentProductType")) {
			arguments.parentProductType = variables.parentProductType;
		}
		var index = arrayFind(arguments.parentProductType.getChildProductTypes(), this);
		if(index > 0) {
			arrayDeleteAt(arguments.parentProductType.getChildProductTypes(), index);
		}
		structDelete(variables, "parentProductType");
	}
	
	// Child Product Types (one-to-many)
	public void function addchildProductType(required any ChildProductType) {
		arguments.ChildProductType.setParentProductType( this );
	}
	public void function removechildProductType(required any ChildProductType) {
		arguments.ChildProductType.removeParentProductType( this );
	}
	
	// Products (one-to-many)
	public void function addProduct(required any product) {
		arguments.product.setProductType( this );
	}
	public void function removeProduct(required any product) {
		arguments.product.removeProductType( this );
	}
	
	// Promotion Rewards (many-to-many - inverse)
	public void function addPromotionReward(required any promotionReward) {
		arguments.promotionReward.addProductType( this );
	}
	public void function removePromotionReward(required any promotionReward) {
		arguments.promotionReward.removeProductType( this );
	}
	
	// Promotion Reward Exclusions (many-to-many - inverse)    
	public void function addPromotionRewardExclusion(required any promotionReward) {    
		arguments.promotionReward.addExcludedProductType( this );    
	}
	public void function removePromotionRewardExclusion(required any promotionReward) {    
		arguments.promotionReward.removeExcludedProductType( this );    
	}
	
	// Promotion Qualifiers (many-to-many - inverse)
	public void function addPromotionQualifier(required any promotionQualifier) {
		arguments.promotionQualifier.addProductType( this );
	}
	public void function removePromotionQualifier(required any promotionQualifier) {
		arguments.promotionQualifier.removeProductType( this );
	}
	
	// Promotion Qualifier Exclusions (many-to-many - inverse)    
	public void function addPromotionQualifierExclusion(required any promotionQualifier) {    
		arguments.promotionQualifier.addExcludedProductType( this );    
	}    
	public void function removePromotionQualifierExclusion(required any promotionQualifier) {    
		arguments.promotionQualifier.removeExcludedProductType( this );    
	}
	
	// Price Group Rates (many-to-many - inverse)
	public void function addPriceGroupRate(required any priceGroupRate) {
		arguments.priceGroupRate.addProductType( this );
	}
	public void function removePriceGroupRate(required any priceGroupRate) {
		arguments.priceGroupRate.removeProductType( this );
	}
	
	// Attribute Sets (many-to-many - inverse)
	public void function addAttributeSet(required any attributeSet) {
		arguments.attributeSet.addProductType( this );
	}
	public void function removeAttributeSet(required any attributeSet) {
		arguments.attributeSet.removeProductType( this );
	}
	
	// Attribute Values (one-to-many)
	public void function addAttributeValue(required any attributeValue) {
		arguments.attributeValue.setProductType( this );
	}
	public void function removeAttributeValue(required any attributeValue) {
		arguments.attributeValue.removeProductType( this );
	}
	
	// Physicals (many-to-many - inverse)    
	public void function addPhysical(required any physical) {    
		arguments.physical.addProductType( this );    
	}    
	public void function removePhysical(required any physical) {    
		arguments.physical.removeProductType( this );
	}
	
	// =============  END:  Bidirectional Helper Methods ===================
	
	// ============== START: Overridden Implicet Getters ===================
	
	public string function getProductTypeIDPath() {
		if(isNull(variables.productTypeIDPath)) {
			variables.productTypeIDPath = buildIDPathList( "parentProductType" );
		}
		return variables.productTypeIDPath;
	}
	
	// ==============  END: Overridden Implicet Getters ====================
	
	// ============= START: Overridden Smart List Getters ==================
	
	public any function getProductsSmartList() {
		if(!structKeyExists(variables, "productsSmartList")) {
			variables.productsSmartList = getService("productService").getProductSmartList();
			variables.productsSmartList.addWhereCondition(" aslatwallproducttype.productTypeIDPath LIKE '#getProductTypeIDPath()#%'");
		}
		return variables.productsSmartList;
	}
	
	// =============  END: Overridden Smart List Getters ===================
	
	// ================== START: Overridden Methods ========================
	
	public string function getSimpleRepresentation() {
		if(!isNull(getParentProductType())) {
			return getParentProductType().getSimpleRepresentation() & " &raquo; " & getProductTypeName();
		}
		return getProductTypeName();
	}
	
	public any function getAssignedAttributeSetSmartList(){
		if(!structKeyExists(variables, "assignedAttributeSetSmartList")) {
			
			variables.assignedAttributeSetSmartList = getService("attributeService").getAttributeSetSmartList();
			
			variables.assignedAttributeSetSmartList.addFilter('activeFlag', 1);
			variables.assignedAttributeSetSmartList.addFilter('attributeSetType.systemCode', 'astProductType');
			
			variables.assignedAttributeSetSmartList.joinRelatedProperty("SlatwallAttributeSet", "productTypes", "left");
			
			var wc = "(";
			wc &= " aslatwallattributeset.globalFlag = 1";
			wc &= " OR aslatwallproducttype.productTypeID IN ('#replace(getProductTypeIDPath(),",","','","all")#')";
			wc &= ")";
			
			variables.assignedAttributeSetSmartList.addWhereCondition( wc );
		}
		
		return variables.assignedAttributeSetSmartList;
	}
	
	// ==================  END:  Overridden Methods ========================
	
	// =================== START: ORM Event Hooks  =========================
	
	public void function preInsert(){
		setProductTypeIDPath( buildIDPathList( "parentProductType" ) );
		super.preInsert();
	}
	
	public void function preUpdate(struct oldData){
		setProductTypeIDPath( buildIDPathList( "parentProductType" ) );;
		super.preUpdate(argumentcollection=arguments);
	}
	
	// ===================  END:  ORM Event Hooks  =========================
}


