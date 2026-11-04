
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_AdminsEmail]
	--Required
	@Locales VARCHAR (200)

		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN


/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Get_AdminsEmail

USE:		
			DECLARE @e int, @em varchar(4000)

			EXEC dbo.usp_MyHLEventAPI_Get_AdminsEmail 
				@Locales = 'es-MX,en-US' 
				-- Error Parameters
				,@Error = @e OUTPUT  
				,@ErrorMessage = @em OUTPUT 
				,@IsDevQA = 1

DESCRIPTION:	Get HL-Admins, HL-Staff by Locale

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventATAccessUser
dbo.Locales


VERSIONS
--------------------------------------------------------------------
1	2013-02-13	Juan	Initial
2	2019-08-14	NoeG	Refactor code (SRE)

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

		DECLARE @Len INT
		DECLARE @tbl TABLE(LocaleCode VARCHAR(5))

		SET @Locales =@Locales + ','

		SET @Len = LEN(@Locales)

		WHILE @Len > 0
		BEGIN
			  INSERT @tbl (LocaleCode) SELECT LEFT(@Locales, CHARINDEX(',',@Locales)-1)
			  SET @Locales = REPLACE(@Locales,LEFT(@Locales, CHARINDEX(',',@Locales)),'')
			  SET @Len = LEN(@Locales)
		END

		SELECT  
			U.EventATAccessUserName,
			U.EventATAccessUserFirstName,
			U.EventATAccessUserLastName,
			U.EventATAccessUserEmailAddress,
			L.LocaleCode

		FROM dbo.EventATAccessUser U WITH (NOLOCK)
			INNER JOIN
				dbo.EventATAccessUserModules M WITH (NOLOCK) ON U.PK_EventATAccessUser = M.PK_EventATAccessUser
			INNER JOIN 
				dbo.Locales L WITH (NOLOCK) ON M.PK_Locale = L.PK_Locale
			INNER JOIN 
				@tbl T ON L.LocaleCode= T.LocaleCode
		WHERE
			U.PK_EventATAccessUserType IN (2, 3) --HL Admin, HL Staff
		Order BY 
			U.EventATAccessUserName

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

GO

