/*
    Slatwall - An e-commerce plugin for Mura CMS
    Copyright (C) 2011 ten24, LLC

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
    
    Linking this library statically or dynamically with other modules is
    making a combined work based on this library.  Thus, the terms and
    conditions of the GNU General Public License cover the whole
    combination.
 
    As a special exception, the copyright holders of this library give you
    permission to link this library with independent modules to produce an
    executable, regardless of the license terms of these independent
    modules, and to copy and distribute the resulting executable under
    terms of your choice, provided that you also meet, for each linked
    independent module, the terms and conditions of the license of that
    module.  An independent module is a module which is not derived from
    or based on this library.  If you modify this library, you may extend
    this exception to your version of the library, but you are not
    obligated to do so.  If you do not wish to do so, delete this
    exception statement from your version.

Notes:

*/
component displayname="Account Loyalty Program" entityname="SlatwallAccountLoyaltyProgram" table="SwAccountLoyaltyProgram" persistent="true" accessors="true"  output="false" extends="HibachiEntity" cacheuse="transactional" hb_serviceName="accountService" hb_permission="account.accountLoyaltyPrograms" {
	
	// Persistent Properties
	property name="accountLoyaltyProgramID" ormtype="string" length="32" fieldtype="id" generator="uuid" unsavedvalue="" default="";
	property name="accountLoyaltyProgramNumber" ormtype="string";

	// Related Object Properties (many-to-one)
	property name="account" cfc="Account" fieldtype="many-to-one" fkcolumn="accountID";
	property name="loyaltyProgram" cfc="loyaltyProgram" fieldtype="many-to-one" fkcolumn="loyaltyProgramID";
	
	// Related Object Properties (one-to-many)
	property name="accountLoyaltyProgramTransactions" singularname="accountLoyaltyProgramTransaction" type="array" fieldtype="one-to-many" fkcolumn="accountLoyaltyProgramID" cfc="AccountLoyaltyProgramTransaction" cascade="all-delete-orphan" inverse="true";
	
	// Remote Properties
	property name="remoteID" ormtype="string";
	
	// Audit Properties
	property name="createdDateTime" ormtype="timestamp";
	property name="createdByAccount" cfc="Account" fieldtype="many-to-one" fkcolumn="createdByAccountID";
	property name="modifiedDateTime" ormtype="timestamp";
	property name="modifiedByAccount" cfc="Account" fieldtype="many-to-one" fkcolumn="modifiedByAccountID";
	
	// Non-Persistent Properties

	
	// ============ START: Non-Persistent Property Methods =================
	
	// ============  END:  Non-Persistent Property Methods =================
		
	// ============= START: Bidirectional Helper Methods ===================
	
	// Account Loyalty Programs Transactions (one-to-many)
	public void function addAccountLoyaltyProgramTransaction(required any accountLoyaltyProgramTransaction) {    
		arguments.accountLoyaltyProgramTransaction.setAccountLoyaltyProgram( this );    
	}    
	public void function removeAccountLoyaltyProgramTransaction(required any accountLoyaltyProgramTransaction) {    
		arguments.accountLoyaltyProgramTransaction.removeAccountLoyaltyProgram( this );    
	}
	
	// Account (many-to-one)
	public void function setAccount(required any account) {
		variables.account = arguments.account;
		if(isNew() or !arguments.account.hasAccountLoyaltyProgram( this )) {
			arrayAppend(arguments.account.getAccountLoyaltyPrograms(), this);
		}
	}
	
	public void function removeAccount(any account) {
		if(!structKeyExists(arguments, "account")) {
			arguments.account = variables.account;
		}
		var index = arrayFind(arguments.account.getAccountLoyaltyPrograms(), this);
		if(index > 0) {
			arrayDeleteAt(arguments.account.getAccountLoyaltyPrograms(), index);
		}
		structDelete(variables, "account");
	}
	
	// Loyalty Program (many-to-one)
	public void function setLoyaltyProgram(required any loyaltyProgram) {
		variables.loyaltyProgram = arguments.loyaltyProgram;
		if(isNew() or !arguments.loyaltyProgram.hasAccountLoyaltyProgram( this )) {
			arrayAppend(arguments.loyaltyProgram.getAccountLoyaltyPrograms(), this);
		}
	}
	public void function removeLoyaltyProgram(any loyaltyProgram) {
		if(!structKeyExists(arguments, "loyaltyProgram")) {
			arguments.loyaltyProgram = variables.loyaltyProgram;
		}
		var index = arrayFind(arguments.loyaltyProgram.getAccountLoyaltyPrograms(), this);
		if(index > 0) {
			arrayDeleteAt(arguments.loyaltyProgram.getAccountLoyaltyPrograms(), index);
		}
		structDelete(variables, "loyaltyProgram");
	}
	
	// =============  END:  Bidirectional Helper Methods ===================

	// =============== START: Custom Validation Methods ====================
	
	// ===============  END: Custom Validation Methods =====================
	
	// =============== START: Custom Formatting Methods ====================
	
	// ===============  END: Custom Formatting Methods =====================
	
	// ============== START: Overridden Implicet Getters ===================
	
	// ==============  END: Overridden Implicet Getters ====================

	// ================== START: Overridden Methods ========================
	
	public string function getSimpleRepresentation() {
		return getLoyaltyProgram().getLoyaltyProgramName();
	}
	
	// ==================  END:  Overridden Methods ========================
	
	// =================== START: ORM Event Hooks  =========================
	
	// TODO [paul]: add a preInsert event hook so that we process an enrollment for the loyalty program.
	
	public void function preInsert() {
		for(var accountLoyaltyProgram in getAccount().getAccountLoyaltyPrograms()) {
			getService("accountService").processAccountLoyaltyProgram(accountLoyaltyProgram, 'enrollment'); 
		}
		
		super.preInsert();
    }

	
	// ===================  END:  ORM Event Hooks  =========================
	
	// ================== START: Deprecated Methods ========================
	
	// ==================  END:  Deprecated Methods ========================
}