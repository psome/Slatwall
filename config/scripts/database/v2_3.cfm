<!---

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

--->

<cfset local.scriptHasErrors = false />

<!--- Update SlatwallPromotionQualifierExcludedProduct and drop priceGroupRateID if it exists --->
<cftry>
	<cfdbinfo datasource="#getApplicationValue("datasource")#" username="#getApplicationValue("datasourceUsername")#" password="#getApplicationValue("datasourcePassword")#" type="Columns" table="SlatwallPromotionQualifierExcludedProduct" name="local.infoColumns" />
	
	<cfquery name="local.hasColumn" dbtype="query">
		SELECT
			* 
		FROM
			infoColumns
		WHERE
			COLUMN_NAME = 'priceGroupRateID'
	</cfquery>
	
	<cfif local.hasColumn.recordCount>
		<cfquery name="local.constraintData">
			SELECT
				CONSTRAINT_NAME
			FROM
				information_schema.key_column_usage
			WHERE
				TABLE_NAME = 'SlatwallPromotionQualifierExcludedProduct'
		</cfquery>
		<cfif local.constraintData.recordCount>
			<cfloop query="local.constraintData">
				<cftry>
					<cfquery name="local.updateData">
						ALTER TABLE SlatwallPromotionQualifierExcludedProduct DROP
						<cfif getApplicationValue("databaseType") eq "MicrosoftSQLServer">
							CONSTRAINT
						<cfelse>
							FOREIGN KEY
						</cfif>
						#local.constraintData.CONSTRAINT_NAME#
					</cfquery>
					<cfcatch><!--- It is ok for this to fail for other DB's ---></cfcatch>
				</cftry>
			</cfloop>
		</cfif>
		
		<cfquery name="local.updateData">
			ALTER TABLE SlatwallPromotionQualifierExcludedProduct DROP COLUMN priceGroupRateID
		</cfquery>
	</cfif>
	
	<cfcatch>
		<cflog file="Slatwall" text="ERROR UPDATE SCRIPT - Drop Column priceGroupRateID on SlatwallPromotionQualifierExcludedProduct Has Error">
		<cfset local.scriptHasErrors = true />
	</cfcatch>
</cftry>


<!--- Update SlatwallPromotionQualifierExcludedProductType and drop priceGroupRateID if it exists --->
<cftry>
	<cfdbinfo datasource="#getApplicationValue("datasource")#" username="#getApplicationValue("datasourceUsername")#" password="#getApplicationValue("datasourcePassword")#" type="Columns" table="SlatwallPromotionQualifierExcludedProductType" name="local.infoColumns" />
	
	<cfquery name="local.hasColumn" dbtype="query">
		SELECT
			* 
		FROM
			infoColumns
		WHERE
			COLUMN_NAME = 'priceGroupRateID'
	</cfquery>
	
	<cfif local.hasColumn.recordCount>
		<cfquery name="local.constraintData">
			SELECT
				CONSTRAINT_NAME
			FROM
				information_schema.key_column_usage
			WHERE
				TABLE_NAME = 'SlatwallPromotionQualifierExcludedProductType'
		</cfquery>
		<cfif local.constraintData.recordCount>
			<cfloop query="local.constraintData">
				<cftry>
					<cfquery name="local.updateData">
						ALTER TABLE SlatwallPromotionQualifierExcludedProductType DROP
						<cfif getApplicationValue("databaseType") eq "MicrosoftSQLServer">
							CONSTRAINT
						<cfelse>
							FOREIGN KEY
						</cfif>
						#local.constraintData.CONSTRAINT_NAME#
					</cfquery>
					<cfcatch><!--- It is ok for this to fail for other DB's ---></cfcatch>
				</cftry>
			</cfloop>
		</cfif>
		
		<cfquery name="local.updateData">
			ALTER TABLE SlatwallPromotionQualifierExcludedProductType DROP COLUMN priceGroupRateID
		</cfquery>
	</cfif>
	
	<cfcatch>
		<cflog file="Slatwall" text="ERROR UPDATE SCRIPT - Drop Column priceGroupRateID on SlatwallPromotionQualifierExcludedProductType Has Error">
		<cfset local.scriptHasErrors = true />
	</cfcatch>
</cftry>


<!--- Update SlatwallPromotionQualifierExcludedSku and drop priceGroupRateID if it exists --->
<cftry>
	<cfdbinfo datasource="#getApplicationValue("datasource")#" username="#getApplicationValue("datasourceUsername")#" password="#getApplicationValue("datasourcePassword")#" type="Columns" table="SlatwallPromotionQualifierExcludedSku" name="local.infoColumns" />
	
	<cfquery name="local.hasColumn" dbtype="query">
		SELECT
			* 
		FROM
			infoColumns
		WHERE
			COLUMN_NAME = 'priceGroupRateID'
	</cfquery>
	
	<cfif local.hasColumn.recordCount>
		<cfquery name="local.constraintData">
			SELECT
				CONSTRAINT_NAME
			FROM
				information_schema.key_column_usage
			WHERE
				TABLE_NAME = 'SlatwallPromotionQualifierExcludedSku'
		</cfquery>
		<cfif local.constraintData.recordCount>
			<cfloop query="local.constraintData">
				<cftry>
					<cfquery name="local.updateData">
						ALTER TABLE SlatwallPromotionQualifierExcludedSku DROP
						<cfif getApplicationValue("databaseType") eq "MicrosoftSQLServer">
							CONSTRAINT
						<cfelse>
							FOREIGN KEY
						</cfif>
						#local.constraintData.CONSTRAINT_NAME#
					</cfquery>
					<cfcatch><!--- It is ok for this to fail for other DB's ---></cfcatch>
				</cftry>
			</cfloop>
		</cfif>
		
		<cfquery name="local.updateData">
			ALTER TABLE SlatwallPromotionQualifierExcludedSku DROP COLUMN priceGroupRateID
		</cfquery>
	</cfif>
	
	<cfcatch>
		<cflog file="Slatwall" text="ERROR UPDATE SCRIPT - Drop Column priceGroupRateID on SlatwallPromotionQualifierExcludedSku Has Error">
		<cfset local.scriptHasErrors = true />
	</cfcatch>
</cftry>


<!--- Update SlatwallPromotionRewardExcludedProduct and drop priceGroupRateID if it exists --->
<cftry>
	<cfdbinfo datasource="#getApplicationValue("datasource")#" username="#getApplicationValue("datasourceUsername")#" password="#getApplicationValue("datasourcePassword")#" type="Columns" table="SlatwallPromotionRewardExcludedProduct" name="local.infoColumns" />
	
	<cfquery name="local.hasColumn" dbtype="query">
		SELECT
			* 
		FROM
			infoColumns
		WHERE
			COLUMN_NAME = 'priceGroupRateID'
	</cfquery>
	
	<cfif local.hasColumn.recordCount>
		<cfquery name="local.constraintData">
			SELECT
				CONSTRAINT_NAME
			FROM
				information_schema.key_column_usage
			WHERE
				TABLE_NAME = 'SlatwallPromotionRewardExcludedProduct'
		</cfquery>
		<cfif local.constraintData.recordCount>
			<cfloop query="local.constraintData">
				<cftry>
					<cfquery name="local.updateData">
						ALTER TABLE SlatwallPromotionRewardExcludedProduct DROP
						<cfif getApplicationValue("databaseType") eq "MicrosoftSQLServer">
							CONSTRAINT
						<cfelse>
							FOREIGN KEY
						</cfif>
						#local.constraintData.CONSTRAINT_NAME#
					</cfquery>
					<cfcatch><!--- It is ok for this to fail for other DB's ---></cfcatch>
				</cftry>
			</cfloop>
		</cfif>
		
		<cfquery name="local.updateData">
			ALTER TABLE SlatwallPromotionRewardExcludedProduct DROP COLUMN priceGroupRateID
		</cfquery>
	</cfif>
	
	<cfcatch>
		<cflog file="Slatwall" text="ERROR UPDATE SCRIPT - Drop Column priceGroupRateID on SlatwallPromotionRewardExcludedProduct Has Error">
		<cfset local.scriptHasErrors = true />
	</cfcatch>
</cftry>


<!--- Update SlatwallPromotionRewardExcludedProductType and drop priceGroupRateID if it exists --->
<cftry>
	<cfdbinfo datasource="#getApplicationValue("datasource")#" username="#getApplicationValue("datasourceUsername")#" password="#getApplicationValue("datasourcePassword")#" type="Columns" table="SlatwallPromotionRewardExcludedProductType" name="local.infoColumns" />
	
	<cfquery name="local.hasColumn" dbtype="query">
		SELECT
			* 
		FROM
			infoColumns
		WHERE
			COLUMN_NAME = 'priceGroupRateID'
	</cfquery>
	
	<cfif local.hasColumn.recordCount>
		<cfquery name="local.constraintData">
			SELECT
				CONSTRAINT_NAME
			FROM
				information_schema.key_column_usage
			WHERE
				TABLE_NAME = 'SlatwallPromotionRewardExcludedProductType'
		</cfquery>
		<cfif local.constraintData.recordCount>
			<cfloop query="local.constraintData">
				<cftry>
					<cfquery name="local.updateData">
						ALTER TABLE SlatwallPromotionRewardExcludedProductType DROP
						<cfif getApplicationValue("databaseType") eq "MicrosoftSQLServer">
							CONSTRAINT
						<cfelse>
							FOREIGN KEY
						</cfif>
						#local.constraintData.CONSTRAINT_NAME#
					</cfquery>
					<cfcatch><!--- It is ok for this to fail for other DB's ---></cfcatch>
				</cftry>
			</cfloop>
		</cfif>
		
		<cfquery name="local.updateData">
			ALTER TABLE SlatwallPromotionRewardExcludedProductType DROP COLUMN priceGroupRateID
		</cfquery>
	</cfif>
	
	<cfcatch>
		<cflog file="Slatwall" text="ERROR UPDATE SCRIPT - Drop Column priceGroupRateID on SlatwallPromotionRewardExcludedProductType Has Error">
		<cfset local.scriptHasErrors = true />
	</cfcatch>
</cftry>



<!--- Update SlatwallPromotionRewardExcludedSku and drop priceGroupRateID if it exists --->
<cftry>
	<cfdbinfo datasource="#getApplicationValue("datasource")#" username="#getApplicationValue("datasourceUsername")#" password="#getApplicationValue("datasourcePassword")#" type="Columns" table="SlatwallPromotionRewardExcludedSku" name="local.infoColumns" />
	
	<cfquery name="local.hasColumn" dbtype="query">
		SELECT
			* 
		FROM
			infoColumns
		WHERE
			COLUMN_NAME = 'priceGroupRateID'
	</cfquery>
	
	<cfif local.hasColumn.recordCount>
		<cfquery name="local.constraintData">
			SELECT
				CONSTRAINT_NAME
			FROM
				information_schema.key_column_usage
			WHERE
				TABLE_NAME = 'SlatwallPromotionRewardExcludedSku'
		</cfquery>
		<cfif local.constraintData.recordCount>
			<cfloop query="local.constraintData">
				<cftry>
					<cfquery name="local.updateData">
						ALTER TABLE SlatwallPromotionRewardExcludedSku DROP
						<cfif getApplicationValue("databaseType") eq "MicrosoftSQLServer">
							CONSTRAINT
						<cfelse>
							FOREIGN KEY
						</cfif>
						#local.constraintData.CONSTRAINT_NAME#
					</cfquery>
					<cfcatch><!--- It is ok for this to fail for other DB's ---></cfcatch>
				</cftry>
			</cfloop>
		</cfif>
		
		<cfquery name="local.updateData">
			ALTER TABLE SlatwallPromotionRewardExcludedSku DROP COLUMN priceGroupRateID
		</cfquery>
	</cfif>
	
	<cfcatch>
		<cflog file="Slatwall" text="ERROR UPDATE SCRIPT - Drop Column priceGroupRateID on SlatwallPromotionRewardExcludedSku Has Error">
		<cfset local.scriptHasErrors = true />
	</cfcatch>
</cftry>

<cfif local.scriptHasErrors>
	<cflog file="Slatwall" text="General Log - Part of Script v2_3 had errors when running">
	<cfthrow detail="Part of Script v2_3 had errors when running">
<cfelse>
	<cflog file="Slatwall" text="General Log - Script v2_3 has run with no errors">
</cfif>
