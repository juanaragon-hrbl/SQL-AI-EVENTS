
CREATE PROCEDURE [dbo].[usp_EventsAT_Upd_SubEvents]	
    -- MANDATORY
    @PK_Locale INT,
    @PK_MasterEventID INT,
    @EventSubTypes udt_EventSubTypes READONLY,    
    
    @ModifiedBy nVARCHAR(50)	
		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:			dbo.usp_EventsAT_Upd_SubEvents

USE:	
			DECLARE @e int, @em varchar(4000)
				,@SubTypes udt_EventSubTypes
			
				INSERT INTO @SubTypes 
				VALUES (22,'Spectacular','Spectacular','Desc Spectacular',2, 1, 'http://herbalife.com/logo')
				--,(null,'Local Event','Local Event','Local Event',2,1) 
			
				EXEC usp_EventsAT_Upd_SubEvents
					 @PK_Locale = 69
					,@PK_MasterEventID = 19
					,@EventSubTypes = @SubTypes
					,@ModifiedBy = 'RogelioR'
					,@Error = @e OUTPUT  -- @e must be defined in the local call   
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]
				select <all> from EventSubTypeLocaleDesc where modifiedby = 'RogelioR'
DESCRIPTION:	Insert/Update SubEvents

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventSubTypes
dbo.EventSubtypesLocaleDesc

VERSIONS
--------------------------------------------------------------------
1		2012-10-29		OrlandoL		Initial
1.1		2013-05-09		SandhyaP		Added error code 412 for validating the subtype to have active association with only 1 master type at a time
1.2		2017-09-14		RogelioR		Added [Image] column to insert in [EventSubtypesLocaleDesc]
2.0		2019-08-08		NoeG			Refactor code (SRE)
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	IF NOT EXISTS(SELECT PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE PK_Locale = @PK_Locale)
	BEGIN
		SET @Error = 294
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END


	/**************************************************************************************
	 Validate SubEvent name already in use
	***************************************************************************************/	

	IF EXISTS (
		SELECT  1 FROM 	@EventSubTypes ST INNER JOIN dbo.EventSubTypes EST WITH (NOLOCK) 
		ON 	ST.SubTypeName = EST.EventSubType AND ST.CodeType = EST.PK_EventType INNER JOIN dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK) 
		ON 	EST.PK_EventSubType = ESL.PK_EventSubType AND ESL.PK_Locale =  @PK_Locale
		INNER JOIN dbo.EventSubTypeGroup ESG WITH (NOLOCK) ON EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup AND ESG.PK_EventSubTypeGroupMaster = @PK_MasterEventID
		WHERE ST.PK_SubType IS NULL
	)
	BEGIN
		SELECT @Error =  405
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			 @ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END

	/**************************************************************************************
	 Validate SubEvents has a valid association with master type
	***************************************************************************************/	
	 SELECT ROW_NUMBER() over (order by EventSubType) as ID, EventSubType, A, EventSubTypeGroupMasterName
	 INTO #TEST1
	 FROM
	 (
	  SELECT DISTINCT EST.EventSubType, ' is already associated to MasterType ' A,  ESGM.EventSubTypeGroupMasterName
	  FROM 
		@EventSubTypes ST 
	  INNER JOIN 
		dbo.EventSubTypes EST WITH (NOLOCK) 
		ON    
			ST.SubTypeName = EST.EventSubType 
			--AND
			--ST.CodeType = EST.PK_EventType            
	  INNER JOIN
		dbo.EventSubTypeGroup ESG WITH (NOLOCK)
		ON
			EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
	  INNER JOIN  
		dbo.EventSubTypeGroupMaster ESGM WITH (NOLOCK)
		ON
			ESG.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster        
	  WHERE 
			ST.PK_SubType IS NULL
			AND
			EST.IsActive = 1
			AND
			ESGM.IsActive = 1
			AND
			ESGM.PK_EventSubTypeGroupMaster <> @PK_MasterEventID
		   )A 

	IF EXISTS (
		SELECT ID, EventSubType, A, EventSubTypeGroupMasterName
		FROM #TEST1
	)
	BEGIN
		DECLARE @Counter INT, @Count INT = 1
		DECLARE @EM VARCHAR(2000)
		SET @EM = ''
		SELECT @Counter = COUNT(0) FROM #TEST1
	
		SELECT @ErrorMessage = ''

		WHILE (@Count <= @Counter)
		BEGIN
			  declare @e1 varchar(200)
			  select @e1 = '</br>'  + CAST(@Count as varchar) + '.' + EventSubType + A + EventSubTypeGroupMasterName FROM #TEST1 where ID = @Count
			  --select @e1
			  select @EM = @EM + CHAR(13) + @e1
		SET @Count = @Count + 1
		END

		SELECT @Error =  412
	
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			 @ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage  OUTPUT
		
		SELECT @ErrorMessage = @ErrorMessage + @EM
	
		RETURN 
	END


	BEGIN TRY
		/********************************************************
		  Insert New SubEvents and Traslations 
		*********************************************************/	

		;WITH SubEventsNotExists (SubType, CodeType, PK_EventSubTypeGroupMaster)
		 AS (SELECT DISTINCT SubTypeName, CodeType, @PK_MasterEventID
			 FROM 
				@EventSubTypes
			 WHERE
				PK_SubType IS NULL
			 EXCEPT
			  SELECT DISTINCT EventSubType, ES.PK_EventType, ESG.PK_EventSubTypeGroupMaster
			 FROM 
				dbo.EventSubTypes ES WITH (NOLOCK)
			 INNER JOIN
				dbo.EventSubTypeGroup ESG WITH (NOLOCK)
				ON
				ES.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup	
		 ), SubEventNotExistMID (SubType, CodeType, MasterEventID) AS
		 (
			SELECT DISTINCT 
				SE.SubType, SE.CodeType, ESG.PK_EventSubTypeGroup
			FROM
				@EventSubTypes ST
			INNER JOIN
				SubEventsNotExists SE WITH (NOLOCK)
			ON
				ST.SubTypeName = SE.SubType AND ST.CodeType = SE.CodeType
			INNER JOIN
				dbo.EventSubTypeGroup ESG WITH (NOLOCK)
			ON
				ESG.PK_EventSubTypeGroupMaster  = @PK_MasterEventID
				AND
				ESG.PK_EventType = ST.CodeType
		 )
 
		SELECT SubType, CodeType, MasterEventID INTO #SubEventNotExists FROM SubEventNotExistMID WITH (NOLOCK)
 
 
		INSERT 
			dbo.EventSubTypes
		(
			PK_EventType
			,EventSubType
		--	,EventSubTypeDesc
			,PK_EventSubTypeGroup
			,CreatedBy
			,IsActive
		)	
		SELECT 
		   ET.PK_EventType
		   ,ST.SubTypeName
		--   ,ST.SubTypeDesc
		   ,SE.MasterEventID
		   ,@ModifiedBy
		   ,ST.IsActive
		FROM 
			@EventSubTypes ST
		INNER JOIN
			#SubEventNotExists SE
			ON
				ST.SubTypeName = SE.SubType
				AND
				ST.CodeType = SE.CodeType	
		INNER JOIN
			dbo.EventType ET WITH (NOLOCK)	
			ON
				ST.CodeType = ET.PK_EventType

 
		INSERT 
			dbo.EventSubTypeLocaleDesc
		(
			PK_EventSubType
			,PK_Locale
			,EventSubTypeDesc
			,LocaleDescription
			,[Image]
		)	
		SELECT 
			   ET.PK_EventSubType
			   ,@PK_Locale
			   ,ST.SubTypeTraslation
			   ,ST.SubTypeDesc
			   ,ST.[Image]
		FROM 
			@EventSubTypes ST
		INNER JOIN
			#SubEventNotExists SE
			ON
				ST.SubTypeName = SE.SubType
				AND
				ST.CodeType = SE.CodeType	
		INNER JOIN
			dbo.EventSubTypes ET WITH (NOLOCK)	
			ON
				ST.CodeType = ET.PK_EventType
				AND
				ST.SubTypeName = ET.EventSubType
		WHERE
			ST.SubTypeTraslation IS NOT NULL
	
		/**************************************************************************
			For the translations that did not exist before but the SubTypes did
		***************************************************************************/

		INSERT 
			dbo.EventSubTypeLocaleDesc
		(
			 PK_EventSubType
			,PK_Locale
			,EventSubTypeDesc
			,LocaleDescription
			,[Image]
		)	
		SELECT 
			   ET.PK_EventSubType
			   ,@PK_Locale
			   ,ST.SubTypeTraslation
			   ,ST.SubTypeDesc
			   ,ST.[Image]
		FROM 
			@EventSubTypes ST
		INNER JOIN
			dbo.EventSubTypes ET WITH (NOLOCK)	
			ON
				ST.CodeType = ET.PK_EventType
				AND
				ST.SubTypeName = ET.EventSubType
		WHERE
			ST.SubTypeTraslation IS NOT NULL
			AND
			ST.PK_SubType IS NOT NULL
			AND
			NOT EXISTS (SELECT 1 FROM dbo.EventSubTypeLocaleDesc WITH (NOLOCK) WHERE PK_Locale = @PK_Locale AND PK_EventSubType = ST.PK_SubType)

		/**************************************************************************
			For the same subevent name with a different translation
		***************************************************************************/

		INSERT 
			dbo.EventSubTypeLocaleDesc
		(
			 PK_EventSubType
			,PK_Locale
			,EventSubTypeDesc
			,LocaleDescription
			,[Image]
		)

		SELECT
		  EST.PK_EventSubType
		, @PK_Locale
		, ST.SubTypeTraslation
		, ST.SubTypeDesc
		, ST.[Image]
		FROM
			@EventSubTypes ST
		INNER JOIN 
			dbo.EventSubTypes EST WITH (NOLOCK) 
			ON 
				ST.SubTypeName = EST.EventSubType 
				AND ST.CodeType = EST.PK_EventType
		LEFT JOIN 
			dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK) 
			ON 
				EST.PK_EventSubType = ESL.PK_EventSubType 
				AND 
				ESL.PK_Locale =  @PK_Locale
		WHERE 
			ESL.PK_EventSubTypeLocaleDesc IS NULL
			AND 
			ST.PK_SubType IS NULL	

		/********************************************************
		  Activate/Deactivate the existing SubEvent
		*********************************************************/	

		UPDATE EST
		SET 
			 EST.IsActive = ST.IsActive
			,EST.ModifiedBy = @ModifiedBy
		FROM
			dbo.EventSubTypes EST
		INNER JOIN
			@EventSubTypes ST
			ON
				EST.EventSubType = ST.SubTypeName
				AND
				EST.PK_EventType = ST.CodeType


		/********************************************************
		  Update the existing Sub Events 
		*********************************************************/	

		UPDATE EST
		SET 
			EST.EventSubType = ST.SubTypeName
		--	,EST.EventSubTypeDesc = ST.SubTypeDesc
			,EST.ModifiedBy = @ModifiedBy
		FROM
			dbo.EventSubTypes EST
		INNER JOIN
			@EventSubTypes ST
			ON
			EST.PK_EventType = ST.CodeType
		WHERE
			EST.PK_EventSubType = ST.PK_SubType
	

		UPDATE EST
		SET 
			EST.EventSubTypeDesc = ST.SubTypeTraslation
			,EST.LocaleDescription = ST.SubTypeDesc
			,EST.ModifiedBy = @ModifiedBy
			,EST.[Image] = ST.[Image]
		FROM
			dbo.EventSubTypeLocaleDesc EST
		INNER JOIN
			@EventSubTypes ST
			ON
				EST.PK_EventSubType = ST.PK_SubType
				AND
				EST.PK_Locale = @PK_Locale
		WHERE
			ST.SubTypeTraslation IS NOT NULL
		
		
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage 
		RETURN 
	END CATCH



/******************************************************************************
End Stored procedure
******************************************************************************/
END
GO

