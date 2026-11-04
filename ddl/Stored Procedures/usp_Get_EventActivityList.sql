CREATE PROCEDURE [dbo].[usp_Get_EventActivityList]
        -- Mandatory Parameters
		@PK_Event					INT
		-- Optional Parameters
		,@ActivityName				nVARCHAR(400)	= NULL
		,@StartUTC					DATETIME		= NULL
		,@EndUTC					DATETIME		= NULL
		,@PK_Country                INT             = NULL
		,@RegStartUTC				DATETIME		= NULL
		,@RegEndUTC					DATETIME		= NULL
		,@ReturnActive				BIT				= 1  -- Exclude Deleted Activity(s)
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT
		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_Get_EventActivityList

USE:	        
				DECLARE @e int, @em varchar(4000)
                EXEC dbo.usp_Get_EventActivityList
					 	 @PK_Event = 2595
                        ,@ReturnActive = 0
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Return Activities for an Event
TABLES:			dbo.Event, dbo.EventActivity
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1	2015-06-19		SandhyaP	Intitial
2	2019-08-14		NoeG		Refactor code (SRE)
******************************************************************************/

/* DECLARE THE REQUIRED VARIABLES */
DECLARE @CurrentUTC DATETIME = GETUTCDATE()
DECLARE @DelDate DATETIME
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

/* ***************** SonarQube check 81 and 82 - Output parameters should be assigned 
	SRE changes added
*/
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	/* GET THE ACTIVITY LIST BASED ON THE INPUT PARAMETER VALUES  */

	If @ReturnActive = 0 Set @DelDate = @CurrentUTC

	SELECT PK_EventActivity
		  ,PK_Event
		  ,ActivityName
		  ,ActivityDesc
		  ,ActivitySequence
		  ,Location
		  ,Address1
		  ,Address2
		  ,City
		  ,StateProvince
		  ,PostalCode
		  ,PK_Country
		  ,StartUTC
		  ,EndUTC
		  ,RegistrationStartUTC
		  ,RegistrationEndUTC
		  ,UnitPrice
		  ,CurrencyType
		  ,CompQtyPerDS
		  ,MaxQtyPerDS
		  ,MaxQty
		  ,SoldQty
		  ,ProcessingQty
		  ,AvailableQty
		  ,ReserveTimeOut
		  ,PaymentTimeOut
		  ,DeletedUTC
		  ,CreatedUTC
		  ,CreatedBy
		  ,ModifiedUTC
		  ,ModifiedBy
	FROM	
		dbo.EventActivity (NOLOCK)
	WHERE
		PK_Event = @PK_Event
		AND
		(COALESCE(@StartUTC, StartUTC, 1) >= COALESCE(StartUTC, 1)  OR COALESCE(@EndUTC, EndUTC, 1) <= COALESCE(EndUTC, 1))
		AND
		COALESCE(PK_Country, 1) = COALESCE(@PK_Country, PK_Country, 1)
		AND
		PK_Event = COALESCE(@PK_Event, PK_Event)
		AND
		ActivityName = COALESCE(@ActivityName, ActivityName)	
		AND 
		(COALESCE(@RegStartUTC, RegistrationStartUTC, 1) >= COALESCE(RegistrationStartUTC, 1)  OR COALESCE(@RegEndUTC, RegistrationEndUTC, 1) <= COALESCE(RegistrationEndUTC, 1))
		AND
		(COALESCE(DeletedUTC, @CurrentUTC) >= @DelDate OR DeletedUTC IS NULL)
	ORDER BY
		ActivitySequence	

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

END