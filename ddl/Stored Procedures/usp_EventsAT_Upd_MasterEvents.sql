CREATE PROCEDURE [dbo].[usp_EventsAT_Upd_MasterEvents]			
	@MasterEventsTbl udt_MasterEvents READONLY
	,@ModifiedBy nVARCHAR(50)
		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventsAT_Upd_MasterEvents

USE:	
	DECLARE @e int, @em varchar(4000)
		
DECLARE @MasterEvents udt_MasterEvents

insert into @MasterEvents values (null,'Test Atomic 2',1,1,3,1,1)
--insert into @MasterEvents values (2,'Retreat',1,1,1,1)
--insert into @MasterEvents values (2,'Retreat',1,2,0,1)
--insert into @MasterEvents values (2,'Retreat',1,3,1,1)
			
	EXEC usp_EventsAT_Upd_MasterEvents
					@MasterEventsTbl = @MasterEvents
					,@ModifiedBy = 'JuanaH'  
		,@Error = @e OUTPUT  -- @e must be defined in the local call   
		,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
		,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Functionality is to Activate/Deactivate Master Events, Remove the dependent SubTypes
				& SubTypes Locales data when the code types are checked off for a master event.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventSubTypeGroup
dbo.EventType

VERSIONS
--------------------------------------------------------------------
	1.0.0	2012-11-09		SandhyaP		Initial
	1.1.0	2019-08-08		NoeG			Refactor code (SRE)
	1.2.0	2019-10-16      puertac		    SRE Implementation 
	1.2.1	2020-07-01		puertac			T 290609 Save IsMajor flag 

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY  
		/******************************************************************************
			Read the udt_MasterEvents into Table variable
		******************************************************************************/

		DECLARE @MasterEvents AS TABLE (
			[PK_MasterEvent] int,
			[MasterEvent] nvarchar(50),
			[IsAtomic] bit,
			[IsActive] bit,
			[CodeType] int,
			[CheckYN] bit,
			[IsEnabled] bit,
			[IsMajor] bit )				--T 290609 Adding IsMajor flag 

		Insert @MasterEvents
		(
			[PK_MasterEvent] 
			,[MasterEvent]
			,[IsAtomic]
			,[IsActive]
			,[CodeType]
			,[CheckYN]
			,[IsEnabled]
			,[IsMajor]				--T 290609 Adding IsMajor flag 
		)
		SELECT
			 [PK_MasterEvent] 
			,[MasterEvent]
			,[IsAtomic]
			,[IsActive]
			,[CodeType]
			,[CheckYN]
			,[IsEnabled]
			,[IsMajor]				--T 290609 Adding IsMajor flag 
		FROM
			@MasterEventsTbl		


		/********************************************************
		  create new master events and add the code types
		*********************************************************/	

		DECLARE @MasterEventsNotExists AS TABLE
		(	 
			MasterEvent nvarchar(50)
		)

		INSERT @MasterEventsNotExists (MasterEvent)
		SELECT DISTINCT MasterEvent
		FROM @MasterEvents
		EXCEPT
		SELECT DISTINCT EventSubTypeGroupMasterName
		FROM dbo.EventSubTypeGroupMaster WITH (NOLOCK)


		/* Verify if the Master Event has no subevents before making it atomic*/
		DECLARE @MasterEventsExists AS TABLE
		(	 
			 MasterEvent nvarchar(50)
			,PK_MasterEvent INT
		)

		INSERT @MasterEventsExists (MasterEvent, PK_MasterEvent)
		SELECT DISTINCT A.MasterEvent,A.PK_MasterEvent FROM 
		(
			SELECT M.MasterEvent, M.PK_MasterEvent
			FROM @MasterEvents M
			JOIN DBO.EventSubTypeGroupMaster EGM WITH (NOLOCK) ON M.MasterEvent = EGM.EventSubTypeGroupMasterName
			AND M.PK_MasterEvent = EGM.PK_EventSubTypeGroupMaster
			JOIN DBO.EventSubTypeGroup EG WITH (NOLOCK) ON EGM.PK_EventSubTypeGroupMaster = EG.PK_EventSubTypeGroupMaster
			JOIN DBO.EventSubTypes EST WITH (NOLOCK) ON EG.PK_EventSubTypeGroup = EST.PK_EventSubTypeGroup
			WHERE 
			EGM.IsAtomic = 0 
			AND M.IsAtomic = 1	
		) A

		IF EXISTS(SELECT 1 FROM @MasterEventsExists)
		BEGIN 
	
			SELECT @Error =  298
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				 @ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 
	
		END
	
		-- INSERT MASTER EVENTS		

		INSERT dbo.EventSubTypeGroupMaster
		(
			EventSubTypeGroupMasterName
			,IsActive
			,CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
			,[IsAtomic]
			,[IsMajor]				--T 290609 Adding IsMajor flag 
		) 
		SELECT DISTINCT
				T.MasterEvent
			   ,T.IsActive 
			   ,GETUTCDATE()
			   ,@ModifiedBy
			   ,GETUTCDATE()
			   ,@ModifiedBy
			   ,[IsAtomic]
			   ,[IsMajor]				--T 290609 Adding IsMajor flag 
		FROM 
			@MasterEventsNotExists M
		INNER JOIN
			@MasterEvents T	
			ON
				M.MasterEvent = T.MasterEvent

		-- INSERT MASTER EVENTS	WITH CODE TYPES	

		INSERT 
			dbo.EventSubTypeGroup 
		(
			PK_EventType
			,PK_EventSubTypeGroupMaster
			,CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
		)	
		SELECT 
			   ET.PK_EventType
			   ,SGM.PK_EventSubTypeGroupMaster
			   ,GETUTCDATE()
			   ,@ModifiedBy
			   ,GETUTCDATE()
			   ,@ModifiedBy
		FROM 
			@MasterEvents T
		--INNER JOIN
		--	@MasterEventsNotExists M
		--	ON
		--		T.MasterEvent = M.MasterEvent
		INNER JOIN
			dbo.EventSubTypeGroupMaster SGM WITH (NOLOCK)
			ON
				SGM.EventSubTypeGroupMasterName = T.MasterEvent		
		INNER JOIN
			dbo.EventType ET WITH (NOLOCK)	
			ON
				T.CodeType = ET.PK_EventType
		WHERE
			T.CheckYN = 1	
			AND 
			NOT EXISTS (SELECT [PK_EventSubTypeGroup] FROM dbo.EventSubTypeGroup EGM WITH (NOLOCK) WHERE SGM.PK_EventSubTypeGroupMaster = PK_EventSubTypeGroupMaster AND ET.PK_EventType = PK_EventType)	
	
		
		-- INSERT MASTER EVENTS	WITH DEFAULT TRANSLATIONS FOR 'en-US'		
		/*
		INSERT dbo.EventSubTypeGroupLocale
		(
			EventSubTypeGroupLocale
			,PK_EventSubTypeGroupMaster
			,PK_Locale
			,CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
		) 
		SELECT DISTINCT
				T.MasterEvent
			   ,SGM.PK_EventSubTypeGroupMaster
			   ,77
			   ,GETUTCDATE()
			   ,@ModifiedBy
			   ,GETUTCDATE()
			   ,@ModifiedBy
		FROM 
			@MasterEvents T	
		INNER JOIN
			dbo.EventSubTypeGroupMaster SGM
			ON
				SGM.EventSubTypeGroupMasterName = T.MasterEvent	
		WHERE
			NOT EXISTS (SELECT PK_EventSubTypeGroupLocale,PK_EventSubTypeGroupMaster,PK_Locale,EventSubTypeGroupLocale,CreatedDateUTC,CreatedBy,ModifiedDateUTC,ModifiedBy FROM dbo.EventSubTypeGroupLocale WHERE SGM.PK_EventSubTypeGroupMaster = PK_EventSubTypeGroupMaster AND PK_Locale = 77)				
		*/
		
		/******************************************************************************
		  Remove the SubTypes & SubTypesLocales for the Atomic to Non Atomic conversion
		******************************************************************************/			
		
/* ***************** SonarQube check 77 - Nullable subqueries should not be used in "NOT IN" conditions */
		DELETE ESTL
		FROM dbo.EventSubTypeLocaleDesc ESTL
		INNER JOIN
			dbo.EventSubTypes EST WITH (NOLOCK)
			ON
				EST.PK_EventSubType = ESTL.PK_EventSubType
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (NOLOCK)
			ON
				EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
				AND
				EST.PK_EventType = ESG.PK_EventType	
		INNER JOIN
			dbo.EventSubTypeGroupMaster ESGM WITH (NOLOCK)
			ON
				ESG.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster		
		INNER JOIN
			@MasterEvents T
			ON
				T.MasterEvent = ESGM.EventSubTypeGroupMasterName
				AND
				T.CodeType = ESG.PK_EventType	
		WHERE
			ESGM.IsAtomic = 1	
			AND
			T.IsAtomic = 0
			--AND
			--ESGM.PK_EventSubTypeGroupMaster NOT IN (SELECT PK_EventSubTypeGroupMaster FROM dbo.EventSubTypeGroupLocale WITH (NOLOCK))
			AND
			----ESTL.PK_EventSubTypeLocaleDesc NOT IN (SELECT PK_EventSubTypeLocaleDesc FROM dbo.EventDSAccess WITH (NOLOCK) )
			ESTL.PK_EventSubTypeLocaleDesc NOT IN (SELECT PK_EventSubTypeLocaleDesc FROM dbo.EventDSAccess WITH (NOLOCK) WHERE PK_EventSubTypeLocaleDesc IS NOT NULL)
/* ***************** SonarQube check 77 */


		DELETE EST 
		FROM dbo.EventSubTypes EST
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (NOLOCK)
			ON
				EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
				AND
				EST.PK_EventType = ESG.PK_EventType	
		INNER JOIN
			dbo.EventSubTypeGroupMaster ESGM WITH (NOLOCK)
			ON
				ESG.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster		
		INNER JOIN
			@MasterEvents T
			ON
				T.MasterEvent = ESGM.EventSubTypeGroupMasterName
				AND
				T.CodeType = ESG.PK_EventType
		WHERE
			ESGM.IsAtomic = 1	
			AND
			T.IsAtomic = 0	

		/********************************************************
		  Activate/Deactivate the existing master events 
		*********************************************************/	
	
		
		UPDATE ESG
		SET 
			 IsActive = T.IsActive
			,IsAtomic = T.IsAtomic
			,IsMajor  = T.IsMajor			--T 290609 Adding IsMajor flag 
			,ModifiedBy = @ModifiedBy	
		FROM
			dbo.EventSubTypeGroupMaster ESG
		INNER JOIN
			@MasterEvents T
			ON
				T.PK_MasterEvent = ESG.PK_EventSubTypeGroupMaster

		/******************************************************************************
		 Default Event Subtypes creation for Atomic Master Events
		******************************************************************************/	

		INSERT INTO dbo.EventSubTypes
		(
			 PK_EventType
			,EventSubType
			,CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
			,PK_EventSubTypeGroup
			,IsActive
		)

		SELECT 
			 T.CodeType
			,T.MasterEvent
			,GETUTCDATE()
			,@ModifiedBy
			,GETUTCDATE()
			,@ModifiedBy
			,ESG.PK_EventSubTypeGroup
			,T.IsActive	   
		FROM 
			@MasterEvents T
		--INNER JOIN
		--	@MasterEventsNotExists M
		--	ON
		--		T.MasterEvent = M.MasterEvent
		INNER JOIN
			dbo.EventSubTypeGroupMaster SGM WITH (NOLOCK)
			ON
				SGM.EventSubTypeGroupMasterName = T.MasterEvent		
		INNER JOIN
			dbo.EventType ET WITH (NOLOCK)	
			ON
				T.CodeType = ET.PK_EventType
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (NOLOCK)
			ON
			ET.PK_EventType = ESG.PK_EventType
			AND
			SGM.PK_EventSubTypeGroupMaster = ESG.PK_EventSubTypeGroupMaster
		WHERE
			T.CheckYN = 1
			AND
			T.IsAtomic = 1	
			AND 
			NOT EXISTS (SELECT [PK_EventSubType] FROM dbo.EventSubTypes S WITH (NOLOCK) WHERE ESG.PK_EventType = S.PK_EventType AND ESG.PK_EventSubTypeGroup = S.PK_EventSubTypeGroup)
	 
		INSERT INTO dbo.EventSubTypeLocaleDesc
		(
			PK_EventSubType
			,PK_Locale
			,EventSubTypeDesc
			,CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
		)
		SELECT
			EST.PK_EventSubType
			,ESTL.PK_Locale
			,ESTL.EventSubTypeGroupLocale
			,GETUTCDATE()
			,@ModifiedBy
			,GETUTCDATE()
			,@ModifiedBy
		FROM 
			@MasterEvents T
		INNER JOIN
			dbo.EventSubTypeGroupMaster SGM WITH (NOLOCK)
			ON
				SGM.EventSubTypeGroupMasterName = T.MasterEvent		
		INNER JOIN
			dbo.EventType ET WITH (NOLOCK)	
			ON
				T.CodeType = ET.PK_EventType
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (NOLOCK)
			ON
			ET.PK_EventType = ESG.PK_EventType
			AND
			SGM.PK_EventSubTypeGroupMaster = ESG.PK_EventSubTypeGroupMaster
		INNER JOIN
			dbo.EventSubTypes EST WITH (NOLOCK)
			ON
			EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
		INNER JOIN
			dbo.EventSubTypeGroupLocale ESTL WITH (NOLOCK)
			ON
			ESTL.PK_EventSubTypeGroupMaster =ESG.PK_EventSubTypeGroupMaster
		WHERE
			T.CheckYN = 1
			AND
			T.IsAtomic = 1	
			AND 
			NOT EXISTS (SELECT [PK_EventSubTypeLocaleDesc] FROM dbo.EventSubTypeLocaleDesc S WITH (NOLOCK) WHERE EST.PK_EventSubType = S.PK_EventSubType AND ESTL.PK_Locale = S.PK_Locale)	
	

		/******************************************************************************
		  Remove the SubTypes & SubTypesLocales for the checkedoff Code Types
		******************************************************************************/			
		
/* ***************** SonarQube check 78 - Nullable subqueries should not be used in "NOT IN" conditions */
		DELETE ESTL
		FROM dbo.EventSubTypeLocaleDesc ESTL
		INNER JOIN
			dbo.EventSubTypes EST WITH (NOLOCK)
			ON
				EST.PK_EventSubType = ESTL.PK_EventSubType
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (NOLOCK)
			ON
				EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
				AND
				EST.PK_EventType = ESG.PK_EventType	
		INNER JOIN
			dbo.EventSubTypeGroupMaster ESGM WITH (NOLOCK)
			ON
				ESG.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster		
		INNER JOIN
			@MasterEvents T
			ON
				T.MasterEvent = ESGM.EventSubTypeGroupMasterName
				AND
				T.CodeType = ESG.PK_EventType	
		WHERE
			T.CheckYN = 0	
			--AND
			--ESGM.PK_EventSubTypeGroupMaster NOT IN (SELECT PK_EventSubTypeGroupMaster FROM dbo.EventSubTypeGroupLocale WITH (NOLOCK))
			AND
			--ESTL.PK_EventSubTypeLocaleDesc NOT IN (SELECT PK_EventSubTypeLocaleDesc FROM dbo.EventDSAccess WITH (NOLOCK) )
			ESTL.PK_EventSubTypeLocaleDesc NOT IN (SELECT PK_EventSubTypeLocaleDesc FROM dbo.EventDSAccess WITH (NOLOCK) WHERE PK_EventSubTypeLocaleDesc IS NOT NULL)
/* ***************** SonarQube check 78 */


		DELETE EST 
		FROM dbo.EventSubTypes EST
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (NOLOCK)
			ON
				EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
				AND
				EST.PK_EventType = ESG.PK_EventType	
		INNER JOIN
			dbo.EventSubTypeGroupMaster ESGM WITH (NOLOCK)
			ON
				ESG.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster		
		INNER JOIN
			@MasterEvents T
			ON
				T.MasterEvent = ESGM.EventSubTypeGroupMasterName
				AND
				T.CodeType = ESG.PK_EventType
		WHERE
			T.CheckYN = 0	
			--AND
			--ESGM.PK_EventSubTypeGroupMaster NOT IN (SELECT PK_EventSubTypeGroupMaster FROM dbo.EventSubTypeGroupLocale WITH (NOLOCK))
			--AND
			--ESG.PK_EventSubTypeGroup NOT IN (SELECT EST.PK_EventSubTypeGroup FROM dbo.EventDSAccess EDA WITH (NOLOCK) JOIN dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK) ON EDA.PK_EventSubTypeLocaleDesc = ESL.PK_EventSubTypeLocaleDesc JOIN dbo.EventSubTypes EST WITH (NOLOCK) ON ESL.PK_EventSubType = EST.PK_EventSubType)		
	

		/******************************************************************************************
		 Remove the associations from EventSubTypeGroup for the checkedoff Code Types
		******************************************************************************************/		
	
		DELETE ESG
		FROM dbo.EventSubTypeGroup ESG
		INNER JOIN
			dbo.EventSubTypeGroupMaster ESGM WITH (NOLOCK)
			ON
				ESG.PK_EventSubTypeGroupMaster = ESGM.PK_EventSubTypeGroupMaster		
		INNER JOIN
			@MasterEvents T
			ON
				T.MasterEvent = ESGM.EventSubTypeGroupMasterName
				AND
				T.CodeType = ESG.PK_EventType
		WHERE
			T.CheckYN = 0	
			--AND
			--ESGM.PK_EventSubTypeGroupMaster NOT IN (SELECT PK_EventSubTypeGroupMaster FROM dbo.EventSubTypeGroupLocale WITH (NOLOCK))
			--AND
			--ESG.PK_EventSubTypeGroup NOT IN (SELECT EST.PK_EventSubTypeGroup FROM dbo.EventDSAccess EDA WITH (NOLOCK) JOIN dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK) ON EDA.PK_EventSubTypeLocaleDesc = ESL.PK_EventSubTypeLocaleDesc JOIN dbo.EventSubTypes EST WITH (NOLOCK) ON ESL.PK_EventSubType = EST.PK_EventSubType)	
						
	-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		 
	END CATCH  

END