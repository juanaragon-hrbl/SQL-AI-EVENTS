CREATE PROCEDURE [dbo].[usp_EventQual_ProcessMAPKickstarters]
        -- Error Parameters
        @Error int = 0  OUTPUT
        ,@ErrorMessage varchar(4000) = '' OUTPUT

        -- QA/DEV
        ,@IsDevQA bit = 0
AS 
BEGIN  
  
/******************************************************************************  
OBJECT:  dbo.usp_EventQual_ProcessMAPKickstarters
  
USE:  EXEC dbo.usp_EventQual_ProcessMAPKickstarters --@PK_Event
	-- Error Parameters
       -- @Error int = 0  OUTPUT
       -- ,@ErrorMessage varchar(4000) = '' OUTPUT

        -- QA/DEV
        --@IsDevQA bit = 0
  
DESCRIPTION: This Stored Proc will populate all qualifiers to SubEventQualifier table once a day
for all MAPs and Kickstarter promos
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
VERSIONS  
--------------------------------------------------------------------  
1 2017-11-10   OrlandoL   Initial  
2 2021-04-20   puertac	  Cleanup: Removing old Promotions
3 2021-06-09   rosarioo	  removing 20086 - EMEA MAP 2020 option 1 and option 2 (45229,45171)
4 2021-07-06   puertac	  Cleanup: Removing old Promotions
5 2021-07-19   puertac	  Cleanup: Removing old Promotions  
6 2022-01-05   puertac	  Cleanup: Removing old Promotions  
******************************************************************************/   
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON   
  
DECLARE @ProcName varchar(100)
 ,@ProcParamRecur varchar(100)
 ,@StartTimeRecur datetime
 ,@PK_Event INT = 14251
 ,@PK_SubEvent INT

SET @ProcName = 'usp_EventQual_ProcessMAPKickstarters'
SET @ProcParamRecur = CONVERT(VARCHAR,@PK_Event) 
SET @StartTimeRecur = GETUTCDATE() 


BEGIN TRY

		/* {{Event Promo Templates}}_START */	

		/******************************************************************
			Process Qualifiers FOR EMEA OPTION 3
		******************************************************************/
		SET @PK_Event = 24450
		SET @PK_SubEvent = NULL

		/*E1 Qualifier*/
		IF OBJECT_ID('tempdb..##QP56', 'U') IS NOT NULL DROP TABLE ##QP56
 
		SELECT @PK_SubEvent = [PK_SubEvent] FROM [dbo].[SubEvent] (NOLOCK) WHERE [PK_Event] = @PK_Event AND [SubEventNumber] = 1
		SELECT 	t.[PK_Distributor] INTO ##QP56 FROM [dbo].[WRK_24450_EMEA_MAP_3_2019] AS t WITH (NOLOCK) WHERE t.[E1] = 1

		EXEC dbo.usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##QP56', 0
		IF OBJECT_ID('tempdb..##QP56', 'U') IS NOT NULL DROP TABLE ##QP56

		/******************************************************************
			Process Qualifiers FOR EMEA OPTION 4 (Ghana)
		******************************************************************/
		SET @PK_Event = 24467
		SET @PK_SubEvent = NULL

		/*E1 Qualifier*/
		IF OBJECT_ID('tempdb..##QP57', 'U') IS NOT NULL DROP TABLE ##QP57
 
		SELECT @PK_SubEvent = [PK_SubEvent] FROM [dbo].[SubEvent] (NOLOCK) WHERE [PK_Event] = @PK_Event AND [SubEventNumber] = 1
		SELECT 	t.[PK_Distributor] INTO ##QP57 FROM [dbo].[WRK_24467_EMEA_MAP_4_2019] AS t WITH (NOLOCK) WHERE t.[E1] = 1

		EXEC dbo.usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##QP57', 0
		IF OBJECT_ID('tempdb..##QP57', 'U') IS NOT NULL DROP TABLE ##QP57


		/******************************************************************
			Process Qualifiers FOR NAM DAP 2021
		******************************************************************/
		SET @PK_Event = 41188
		SET @PK_SubEvent = NULL
		
		
		IF OBJECT_ID('dbo.WRK_41188') IS NOT NULL
		BEGIN
			/*E1 Qualifier*/
			IF OBJECT_ID('tempdb..##QP_41188_1', 'U') IS NOT NULL DROP TABLE ##QP_41188_1
 
			SELECT @PK_SubEvent = [PK_SubEvent] FROM [dbo].[SubEvent] (NOLOCK) WHERE [PK_Event] = @PK_Event AND [SubEventNumber] = 1
			SELECT 	t.[PK_Distributor] INTO ##QP_41188_1 FROM [dbo].[WRK_41188] AS t WITH (NOLOCK) WHERE t.[E1] = 1

			EXEC dbo.usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##QP_41188_1', 0
			IF OBJECT_ID('tempdb..##QP_41188_1', 'U') IS NOT NULL DROP TABLE ##QP_41188_1

			/*E2 Qualifier*/
			IF OBJECT_ID('tempdb..##QP_41188_2', 'U') IS NOT NULL DROP TABLE ##QP_41188_2
 
			SELECT @PK_SubEvent = [PK_SubEvent] FROM [dbo].[SubEvent] (NOLOCK) WHERE [PK_Event] = @PK_Event AND [SubEventNumber] = 2
			SELECT 	t.[PK_Distributor] INTO ##QP_41188_2 FROM [dbo].[WRK_41188] AS t WITH (NOLOCK) WHERE t.[E2] = 1

			EXEC dbo.usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##QP_41188_2', 0
			IF OBJECT_ID('tempdb..##QP_41188_2', 'U') IS NOT NULL DROP TABLE ##QP_41188_2

			/*E3 Qualifier*/
			IF OBJECT_ID('tempdb..##QP_41188_3', 'U') IS NOT NULL DROP TABLE ##QP_41188_3
 
			SELECT @PK_SubEvent = [PK_SubEvent] FROM [dbo].[SubEvent] (NOLOCK) WHERE [PK_Event] = @PK_Event AND [SubEventNumber] = 3
			SELECT 	t.[PK_Distributor] INTO ##QP_41188_3 FROM [dbo].[WRK_41188] AS t WITH (NOLOCK) WHERE t.[E3] = 1

			EXEC dbo.usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##QP_41188_3', 0
			IF OBJECT_ID('tempdb..##QP_41188_3', 'U') IS NOT NULL DROP TABLE ##QP_41188_3

			/*E4 Qualifier*/
			IF OBJECT_ID('tempdb..##QP_41188_4', 'U') IS NOT NULL DROP TABLE ##QP_41188_4
 
			SELECT @PK_SubEvent = [PK_SubEvent] FROM [dbo].[SubEvent] (NOLOCK) WHERE [PK_Event] = @PK_Event AND [SubEventNumber] = 4
			SELECT 	t.[PK_Distributor] INTO ##QP_41188_4 FROM [dbo].[WRK_41188] AS t WITH (NOLOCK) WHERE t.[E4] = 1

			EXEC dbo.usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##QP_41188_4', 0
			IF OBJECT_ID('tempdb..##QP_41188_4', 'U') IS NOT NULL DROP TABLE ##QP_41188_4

			/*E5 Qualifier*/
			IF OBJECT_ID('tempdb..##QP_41188_5', 'U') IS NOT NULL DROP TABLE ##QP_41188_5
 
			SELECT @PK_SubEvent = [PK_SubEvent] FROM [dbo].[SubEvent] (NOLOCK) WHERE [PK_Event] = @PK_Event AND [SubEventNumber] = 5
			SELECT 	t.[PK_Distributor] INTO ##QP_41188_5 FROM [dbo].[WRK_41188] AS t WITH (NOLOCK) WHERE t.[E5] = 1

			EXEC dbo.usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##QP_41188_5', 0
			IF OBJECT_ID('tempdb..##QP_41188_5', 'U') IS NOT NULL DROP TABLE ##QP_41188_5

			/*E6 Qualifier*/
			IF OBJECT_ID('tempdb..##QP_41188_6', 'U') IS NOT NULL DROP TABLE ##QP_41188_6
 
			SELECT @PK_SubEvent = [PK_SubEvent] FROM [dbo].[SubEvent] (NOLOCK) WHERE [PK_Event] = @PK_Event AND [SubEventNumber] = 6
			SELECT 	t.[PK_Distributor] INTO ##QP_41188_6 FROM [dbo].[WRK_41188] AS t WITH (NOLOCK) WHERE t.[E6] = 1

			EXEC dbo.usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##QP_41188_6', 0
			IF OBJECT_ID('tempdb..##QP_41188_6', 'U') IS NOT NULL DROP TABLE ##QP_41188_6

		END

		/******************************************************************
			Process Qualifiers 21023 - NAM New SP 2021
		******************************************************************/
		SET @PK_Event = 52122
		SET @PK_SubEvent = NULL
			
		SET @ProcParamRecur = CONVERT(VARCHAR,@PK_Event) 
		SET @StartTimeRecur = GETUTCDATE() 

		IF OBJECT_ID('Promo.DSSubEvent') IS NOT NULL
		BEGIN

			/* E1 Qualifier */
			DROP TABLE IF EXISTS ##QP_52122_1;
			SELECT @PK_SubEvent = [PK_SubEvent] FROM [dbo].[SubEvent] (NOLOCK) WHERE [PK_Event] = @PK_Event AND [SubEventNumber] = 1
			SELECT 	t.[PK_Distributor] INTO ##QP_52122_1 FROM [Promo].[DSSubEvent] AS t WITH (NOLOCK) WHERE [PK_Event] = @PK_Event AND [SubEvent] = 1
			EXEC dbo.usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##QP_52122_1', 0
			DROP TABLE IF EXISTS ##QP_52122_1;

						
			EXEC dbo.usp_Utility_UpdateProcessingLog
				@StoredProcedureName = @ProcName
				,@StoredProcedureParameters = @ProcParamRecur
				,@StartTime = @StartTimeRecur

		END;
			 
			 
/* {{Event Promo Templates}}_END */

END TRY
    BEGIN CATCH
        SET @Error = ERROR_NUMBER()
        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ProcName = ERROR_PROCEDURE()

        IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

        -- UPDATE ERROR LOG
        EXEC dbo.usp_Utility_UpdateErrorLog
                @ProcedureName = @ProcName
                ,@ErrorNumber = 3
                ,@ErrorMessage = @ErrorMessage
                ,@SQLErrorCode = @Error
                ,@SQLErrorMsg = @ErrorMessage
        
END CATCH;


EXEC dbo.usp_Utility_UpdateProcessingLog
@StoredProcedureName = @ProcName
,@StoredProcedureParameters = @ProcParamRecur
,@StartTime = @StartTimeRecur

/******************************************************************************  
 END PROCEDURE  
******************************************************************************/   
END