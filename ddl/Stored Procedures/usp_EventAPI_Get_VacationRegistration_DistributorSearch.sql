CREATE PROCEDURE [dbo].[usp_EventAPI_Get_VacationRegistration_DistributorSearch]
	-- REQUIRED
	 @DistributorID varchar(30)
	,@Documentno varchar(30)
	,@PK_Event int	
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0	

AS
BEGIN


/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Get_VacationRegistration_DistributorSearch

DESCRIPTION:Search results for Distributor,Document number and both	

NOTES:			
		DECLARE @e int, @em varchar(4000)
		EXEC dbo.usp_EventAPI_Get_VacationRegistration_DistributorSearch 
				@DistributorID = '2222222222'
				,@Documentno = ''
				,@PK_Event = 691
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.v_Distributor
dbo.VacationRegistration

VERSIONS
--------------------------------------------------------------------
1	2011-07-20		Jahnavi/Chandan 	Initial
1.1 2012-06-26      SandhyaP	        Renamed SP from usp_EventAPI_Get_DistributorSearch_SamCam to usp_EventAPI_Get_VacationRegistration_DistributorSearch
									    Uncommented hardcoded PK_Event value
1.2 2019-09-05		NoeG				SRE template applied
1.3 2019-10-09		alejandramed		SRE Compliance 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @DistributorType VARCHAR(5) = 'B'

SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

		/******************************************************************************
		be sure the value of FK exists in referenced table
		******************************************************************************/
		IF @DistributorID IS NULL and @Documentno IS NULL
		BEGIN
			SET @Error = 219
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 
		END

		IF @DistributorID IS NOT NULL AND NOT EXISTS (SELECT DistributorID FROM dbo.EventQualifier WITH (NOLOCK) WHERE PK_Event = @PK_Event AND DistributorID = @DistributorID)
		  BEGIN
			SET @Error = 182
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 
		  END
  
		IF @DistributorID IS NOT NULL AND NOT EXISTS (SELECT sDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID)
		  BEGIN
			SET @Error = 8
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 
		  END
  
		IF @DistributorID IS NOT NULL AND @Documentno IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.VacationRegistration WITH (NOLOCK) WHERE DistributorID = @DistributorID AND DocumentNumber = @DocumentNo)
			BEGIN

			  SET @Error = 188

			  -- Update ErrorLog

			  EXEC dbo.usp_Utility_UpdateErrorLog 

					@ProcedureName = @StoredProcedure 

					,@ErrorNumber = @Error

					,@ErrorMessage = @ErrorMessage OUTPUT

			  RETURN 

		  END

		/******************************************************************************
		select record
		******************************************************************************/
		DECLARE @ISVALID Varchar(30)

		BEGIN		 
				 IF  @DistributorID is not null and isnull(@Documentno,'')=''
				 BEGIN
						 SELECT DistributorID, 
						 LTRIM(RTRIM(FirstName))+ ' ' + LTRIM(RTRIM(LastName)) AS DistributorName
						 FROM dbo.VacationRegistration a  WITH (NOLOCK) WHERE 
						a.DistributorID = @DistributorID
						and a.DistributorType = @DistributorType
				 End 
		
				 Else IF @Documentno IS NOT NULL and ISNULL(@DistributorID,'') = '' 
				  
							 Begin
							   SELECT DistributorID, 
							   LTRIM(RTRIM(FirstName))+ ' ' + LTRIM(RTRIM(LastName)) AS DistributorName
							   FROM dbo.VacationRegistration a  WITH (NOLOCK)
							   WHERE 
								  a.DistributorID IN (SELECT DistributorID FROM dbo.VacationRegistration  WITH (NOLOCK) WHERE 
								  DocumentNumber = @Documentno) 
							 End

		  ELSE IF @DistributorID IS NOT NULL and  @Documentno IS NOT NULL 
				Begin
				   SELECT DistributorID,
							   LTRIM(RTRIM(FirstName))+ ' ' + LTRIM(RTRIM(LastName)) AS DistributorName
							   FROM dbo.VacationRegistration a WITH (NOLOCK)
							   WHERE
				   a.DistributorID = @DistributorID AND DocumentNumber = @Documentno
				 End        
		END  

		/******************************************************************************
			end procedure
		******************************************************************************/
		
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
		RETURN 
	END CATCH;
END;
