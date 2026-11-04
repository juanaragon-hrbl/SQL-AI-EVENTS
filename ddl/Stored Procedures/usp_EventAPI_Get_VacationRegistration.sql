
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_VacationRegistration]
	 @DistributorID varchar(40)
	,@PK_Event int
	--,@sequencenumber INT OUTPUT
		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Get_VacationRegistration


DESCRIPTION:	Retrieves record from dbo.VacationRegistration

NOTES:			
		DECLARE @e int, @em varchar(200)
		EXEC dbo.usp_EventAPI_Get_VacationRegistration 
				@DistributorID = '2222222222'
				,@PK_Event = 691
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.VacationRegistration

VERSIONS
--------------------------------------------------------------------
1	2011-07-19	Jahnavi/Chandan	Initial
1.1 2012-06-19  SandhyaP		 Renamed SP from usp_EventAPI_Get_VacationRegistration_samcam to usp_EventAPI_Get_VacationRegistration
								 Add fields - BirthDate, DocumentIssueDate, PreMedicalConditions, CountryOfResidence, FileType, FilePath, FileName
								 Changed @PK_Event varchar type to int and uncommented hardcoded value, hence @PK_Event must be passed
1.2 2019-09-05	NoeG			 SRE template applied								 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
	DECLARE @country varchar(100)

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

		/******************************************************************************
		be sure the value of FK exists in referenced table
		******************************************************************************/
		IF NOT EXISTS(SELECT DistributorID FROM dbo.VacationRegistration WITH (NOLOCK) WHERE DistributorID = @DistributorID)
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
		SELECT
			 [PK_VacationRegistration]
			,[DistributorID] 
			,[FirstName]
			,[LastName] 
			,[TeamStatus]  
			,[Email]
			,[Phone]
			,[Mobile]
			FROM 
				dbo.VacationRegistration WITH (NOLOCK) 
			WHERE 
				DistributorID = @DistributorID
				AND 
				DistributorType = 'B'
				AND 
				PK_Event = @PK_Event
			--	group by distributorID

		/******************************************************************************
		select record
		******************************************************************************/

	BEGIN TRY

		SELECT
			 b.PK_VacationRegistration
			,b.CreatedDate
			,b.CreatedBy
			,b.ModifiedDate
			,b.ModifiedBy
			,b.PK_Event
			,b.PK_Distributor
			,b.DistributorID 
			,b.FirstName
			,b.MiddleName
			,b.LastName 
			,b.DistributorType
			,b.PK_Nationality 
			,b.PK_TravelDocumentType
			,'DocumentType' = 
			case b.PK_TravelDocumentType
			when 1 then (select DocumentTypeDesc from TravelDocumentType WITH (NOLOCK) where PK_TravelDocumentType =1)
			when 2 then (select DocumentTypeDesc from TravelDocumentType WITH (NOLOCK) where PK_TravelDocumentType =2)
			when 3 then (select DocumentTypeDesc from TravelDocumentType WITH (NOLOCK) where PK_TravelDocumentType =3)
			when 4 then (select DocumentTypeDesc from TravelDocumentType WITH (NOLOCK) where PK_TravelDocumentType =4)
			when 5 then (select DocumentTypeDesc from TravelDocumentType WITH (NOLOCK) where PK_TravelDocumentType =5)
			when 6 then (select DocumentTypeDesc from TravelDocumentType WITH (NOLOCK) where PK_TravelDocumentType =6)
			when 7 then (select DocumentTypeDesc from TravelDocumentType WITH (NOLOCK) where PK_TravelDocumentType =7)
			else  (select documenttype from VacationRegistration vac WITH (NOLOCK) where PK_TravelDocumentType is null and distributorID=@DistributorID
							and vac.PK_VacationRegistration = b.PK_VacationRegistration)
			end
			,b.DocumentNumber
			,b.DocumentExpiryDate
			,b.RecordStatus
			,b.ApprovalDate
			,b.ApprovedBy
			,C.sCountryName AS CountryName
			,b.DateOfBirth
			,b.DocumentIssueDate
			,b.PreMedicalConditions
			,b.CountryOfResidence
			,b.FileType
			,b.FilePath
			,b.[FileName]		
		FROM 
			dbo.VacationRegistration b WITH (NOLOCK)
		LEFT JOIN 
			dbo.TravelDocumentType a WITH (NOLOCK) 
			ON
				a.pk_traveldocumentType=b.Pk_traveldocumentType 
		LEFT JOIN 
			dbo.v_Nationality c 
			ON
				c.nCountryID = b.PK_Nationality
		WHERE 
			b.DistributorID=@DistributorID 
			AND 
			DistributorType != 'B'
			AND 
			PK_Event = @PK_Event

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

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime
	

/******************************************************************************
	end procedure
******************************************************************************/
END