CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_TempDistributor]
-- REQUIRED
@DistributorID varchar(10)
,@FirstName varchar(100) = NULL
,@LastName varchar(100) = NULL
,@Address1 varchar(100) = NULL
,@Address2 varchar(100) = NULL
,@Address3 varchar(100) = NULL
,@City varchar(50) = NULL
,@State varchar(50) = NULL
,@ZipCode varchar(20) = NULL
,@Country varchar(50) = NULL
,@DayPhone varchar(30) = NULL
,@EveningPhone varchar(30) = NULL
,@MobilePhone varchar(30) = NULL
,@CreatedOnSite char(1) = 'Y'
,@UserID varchar(50) 

-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0    

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Ins_TempDistributor

USE:
			DECLARE @e int, @em varchar(4000)

            EXEC usp_EventAPI_Ins_TempDistributor @DistributorID = 'ASTA LA VISTA'
                                                    ,@FirstName  = NULL
                                                    ,@LastName = NULL
                                                    ,@Address1 = NULL
                                                    ,@Address2 = NULL
                                                    ,@Address3 = NULL
                                                    ,@City = NULL
                                                    ,@State = NULL
                                                    ,@ZipCode  = NULL
                                                    ,@Country = NULL
                                                    ,@DayPhone = NULL
                                                    ,@EveningPhone = NULL
                                                    ,@MobilePhone = NULL
                                                    ,@CreatedOnSite = 'Y'
                                                    ,@UserID  = 'SandhyaP'
                                                    ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                            ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
													,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Insert Temp Distributors in the TempDistributors table

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1	2009-01-22		SandhyaP		Initial
2   2011-09-22		SandhyaP		Add PK_Event to the INSERT
3	2019-09-05		NoeG			SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @e int
DECLARE @em varchar(200)
DECLARE @PK_Temp INT

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	/******************************************************************************
	  Generate the temporary ID for a distributor
	******************************************************************************/
	IF EXISTS (
	  SELECT 
		sDistributorID 
	  FROM  
		dbo.v_Distributor D
	  WHERE 
		D.sDistributorID = @DistributorID
	  UNION
	  SELECT 
		DistributorID 
	  FROM  
		dbo.TempDistributors T WITH (NOLOCK)
	  WHERE 
		T.DistributorID = @DistributorID)

	BEGIN
	   BEGIN
		SET @Error = 249
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	  END
	END
	ELSE
	BEGIN TRY
  
	  INSERT INTO [dbo].[TempDistributors]
			   ([DistributorID]
			   ,[FirstName]
			   ,[LastName]
			   ,[Address1]
			   ,[Address2]
			   ,[Address3]
			   ,[City]
			   ,[State]
			   ,[ZipCode]
			   ,[Country]
			   ,[DayPhone]
			   ,[EveningPhone]
			   ,[MobilePhone]
			   ,[CreatedOnSite]
			   ,[CreatedBy]
			   ,[ModifiedBy]
			   ,[PK_Event])
		 VALUES
			   (@DistributorID
			   ,@FirstName
			   ,@LastName
			   ,@Address1
			   ,@Address2
			   ,@Address3
			   ,@City
			   ,@State
			   ,@ZipCode
			   ,@Country
			   ,@DayPhone
			   ,@EveningPhone
			   ,@MobilePhone
			   ,@CreatedOnSite
			   ,@UserID
			   ,@UserID
			   ,SUBSTRING(@UserID, 5, LEN(@UserID)) )

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
	END CATCH
/******************************************************************************
	end procedure
******************************************************************************/
END
GO

