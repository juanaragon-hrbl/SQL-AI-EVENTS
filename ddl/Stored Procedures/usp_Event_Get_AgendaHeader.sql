
CREATE PROC [dbo].[usp_Event_Get_AgendaHeader]
	@DistributorID VARCHAR(15),
	@PK_Event INT,
	@Language VARCHAR(20) 

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
/* -----------------------------------------------------------------------------------------------------------------------------------------
	OBJECT:			dbo.usp_Event_Get_AgendaHeader
	USAGE:			
				DECLARE @e int, @em varchar(4000)
				
				EXEC usp_Event_Get_AgendaHeader
						 @DistributorID = '10Y0452542',
						 @PK_Event = 1189,
						 @Language = 'EN'
						,@Error = @e OUTPUT
						,@ErrorMessage = @em OUTPUT
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	

	DEPENDENCIES
	---------------------------------------------------------------------------------------------------------------------------------------
	
	VERSIONS
	----------------------------------------------------------------------------------------------------------------------------------------
	1	2014-08-14   Emi	Initial
	2	2019-08-14   NoeG	Refactor code (SRE)
-----------------------------------------------------------------------------------------------------------------------------------------*/

BEGIN
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE @Default_Language char(2) = 'XX'; -- Should default to default language of the event if member/DS language not setup for agenda
	
		IF NOT EXISTS (SELECT PK_Agenda FROM dbo.Agenda WITH (NOLOCK) WHERE PK_Event = @PK_Event AND AgendaLanguage = @Language)
		BEGIN
			SELECT  
				@Default_Language = LEFT(L.LocaleCode,2) 
			FROM
				dbo.Event E WITH (NOLOCK) 
			INNER JOIN 
				dbo.Locales L WITH (NOLOCK)
					ON E.PK_Event = @PK_Event 
					   AND E.PK_DefaultLocale = L.PK_Locale
		
			SET @Language = CASE WHEN @Default_Language = 'XX' THEN @Language ELSE @Default_Language END
		END

		SELECT
			ai.DisplayDescription AS HeaderDescription,
			ai.DisplayLocation AS HeaderDetail,
			ISNULL(ai.IsImage,0) AS IsImage
		FROM
			dbo.Agenda a WITH (NOLOCK)
		JOIN
			dbo.AgendaItem ai WITH (NOLOCK)
			ON
				a.PK_Agenda = ai.PK_Agenda
		JOIN
			dbo.AgendaItemType at WITH (NOLOCK)
			ON
				ai.PK_AgendaItemType = at.PK_AgendaItemType		
		WHERE
			a.PK_Event = @PK_Event
			AND
			a.AgendaLanguage = @Language
			AND
			at.TypeDescription IN ('Header','Footer')
		UNION
		SELECT
			'DistributorName' AS HeaderDescription,
			sFirstName + ' ' + sLastName + 
			CASE WHEN DSS.nDistributorSpouseID IS NOT NULL THEN ' AND ' + DSS.sSpouseFirstName + ' ' + DSS.sSpouseLastName
			ELSE '' END AS HeaderDetail,
			0 AS IsImage
			FROM 
				dbo.v_Distributor DS 
			LEFT JOIN 
				dbo.v_DistributorSpouse DSS 
			ON
				DS.nDistributorID = DSS.nDistributorID 
			WHERE
				DS.sDistributorID = @DistributorID 

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
