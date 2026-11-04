CREATE PROCEDURE [dbo].[usp_Event_Ins_Locale]
	-- Add the parameters for the stored procedure here
	@PK_Locale INT = NULL, -- Optional . If NULL it will identity insert
	@LanguageCountryRegion nvarchar (1000),
	@LocaleCode varchar (5),

	-- Error Parameters
		@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = NULL OUTPUT
	-- QA/DEV
		,@IsDevQA bit = 0
/******************************************************************************
OBJECT:		dbo.[usp_Event_Ins_Locale]


USE:		
	declare @e int
    ,@em varchar(200)

             EXEC [usp_Event_Ins_Locale]
					 @PK_Locale = NULL
					,@LocaleCode = 'en-KH'
                    ,@LanguageCountryRegion = 'Cambodia-English'
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					
					SELECT @e, @em

DESCRIPTION:	Get the Region - Country Dropdown based on the User Access Level

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
	1.0.0   	2013-10-02      Juanah      	Initial
	1.1.0		2019-10-11		puertac			SRE Implementation
******************************************************************************/
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @StoredProcedure varchar(100)
	DECLARE @StartTime datetime

	SET @StoredProcedure = 'usp_Event_Ins_Locale'
	SET @StartTime = GETUTCDATE()
	SET @Error = 0
	SET @ErrorMessage = 'No Error.'
	BEGIN TRY

	IF @PK_Locale IS NULL 
		SET @PK_Locale = IDENT_CURRENT('dbo.Locales') + 1

		IF EXISTS (SELECT 1 FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode)
		BEGIN
			SET @ErrorMessage = 'Locale ' +@LocaleCode + ' is already present and will result in duplicate record'
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage OUTPUT
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage
			RETURN
		END

		SET IDENTITY_INSERT dbo.Locales ON
	
	   	INSERT INTO dbo.Locales (PK_Locale, LanguageCountryRegion, LocaleCode, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy)
		VALUES (@PK_Locale, @LanguageCountryRegion, @LocaleCode,DEFAULT,DEFAULT,DEFAULT,DEFAULT)

	-- ================
	-- Give IT Access to the NEW Locale
	-- ================
		INSERT INTO [dbo].[EventATAccessUserModules] (PK_EventATAccessUser,PK_Locale)
		SELECT PK_EventATAccessUser, @PK_Locale FROM dbo.EventATAccessUser A WITH (NOLOCK)  
			INNER JOIN	dbo.EventATAccessUserTypes B WITH (NOLOCK)  
			 ON A.PK_EventATAccessUserType = B.PK_EventATAccessUserType
		WHERE B.EventATAccessUserType = 'IT ADMIN'
		EXCEPT SELECT PK_EventATAccessUser, PK_Locale FROM EventATAccessUserModules WITH (NOLOCK)  


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

	SET IDENTITY_INSERT DBO.Locales OFF

END
