CREATE PROCEDURE [dbo].[usp_InsertLeadsByCOP_EventQualifier]
	 @Error	INT = 0 OUTPUT
	,@ErrorMessage VARCHAR(4000) = '' OUTPUT
	,@IsDevQA TINYINT = 0
					 
AS
BEGIN

/*******************************************************************************************************
	OBJECT:      [dbo].[usp_InsertLeadsByCOP_EventQualifier]	
	USE:
			DECLARE @e int = 0, @em varchar(4000)

			EXEC [dbo].[usp_InsertLeadsByCOP_EventQualifier]
					,@Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT
					,@IsDevQA = 0

			SELECT @e, @em
	
	DESCRIPTION:     
	NOTES:
    DEPENDENCIES
    -----------------------------------------------------------------------------------------
    VERSIONS
    -----------------------------------------------------------------------------------------
    1.0.0       2024-06-05     puertac        Initial
***********************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID) 
		,@StartTime datetime2 = GETUTCDATE()		   
		
SELECT @Error = 0, @ErrorMessage = ''; 

	BEGIN TRY
	
		IF @IsDevQA= 2 THROW 60000, N'Unit test Error', 1;
		
		DROP TABLE IF EXISTS #EventsToProcess

		CREATE TABLE #EventsToProcess(
			 RowNumber INT IDENTITY(1,1)
			,PK_Event			INT
			,PK_SubEvent		INT
			,PK_Event_Leads		INT
			,COP				VARCHAR(1000)
			,IsActive			BIT
		)
		
		INSERT INTO #EventsToProcess (PK_Event, PK_SubEvent, PK_Event_Leads, COP, IsActive)
		SELECT PK_Event, PK_SubEvent, PK_Event_Leads, COP, IsActive
		FROM DevAdmin.ConfigQualifiersForLeadsByCOP WITH (NOLOCK)
		WHERE IsActive = 1

		CREATE INDEX IX_#EventsToProcess_PK ON #EventsToProcess(PK_Event)
		

		DECLARE  @PK_Events_Count INT = (SELECT COUNT(*) FROM #EventsToProcess)
				,@Count INT = 1
				,@Current_PK_Event INT
				,@Current_PK_SubEvent INT
				,@Current_PK_Event_Leads INT
				,@COP	VARCHAR (500)
				,@ValidDate DATETIME = '2049-12-31'						  
				  						
										
		WHILE @Count <= @PK_Events_Count										--Update SubEvents flags
		 BEGIN
				SELECT   @Current_PK_Event = PK_Event
						,@Current_PK_SubEvent = PK_SubEvent
						,@Current_PK_Event_Leads = PK_Event_Leads
						,@COP = COP
				FROM #EventsToProcess 
				WHERE RowNumber = @Count


				DROP TABLE IF EXISTS #Countries

				SELECT VALUE AS COP
				INTO #Countries
				FROM STRING_SPLIT(@COP, ',')   


				DELETE FROM EventQualifier WHERE PK_Event = @Current_PK_Event_Leads 
				
				INSERT INTO EventQualifier (PK_Event, PK_Distributor, DistributorID, Qualified)
				SELECT DISTINCT @Current_PK_Event_Leads AS PK_Event, S.PK_Distributor, V.sDistributorID, 1 AS Qualified
				FROM SubEventQualifier AS S WITH (NOLOCK)
				INNER JOIN v_Distributor AS V
					ON S.PK_Distributor = V.nDistributorID
				WHERE S.PK_Event = @Current_PK_Event
				AND S.PK_SubEvent = @Current_PK_SubEvent
				AND S.Qualified = 1		
				AND S.RemovedUTC = @ValidDate
				AND V.sDistributorCountryProcessingCode IN (SELECT COP FROM #Countries)

				SET @Count = @Count + 1
		 END


		 -- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime
															  
				
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
	END CATCH;
END