
CREATE PROC [dbo].[usp_Event_Get_AgendaItem]
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
	OBJECT:			dbo.usp_Event_Get_AgendaItem
	USAGE:			
				DECLARE @e int, @em varchar(4000)
				
				EXEC usp_Event_Get_AgendaItem
						 @DistributorID = '10Y0452542',
						 @PK_Event = 1157,
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
		DECLARE @SubTypeCodeNum AS TINYINT
	
		IF NOT EXISTS (SELECT PK_Agenda FROM dbo.Agenda WITH (NOLOCK) WHERE PK_Event = @PK_Event AND AgendaLanguage = @Language)
		BEGIN
			SELECT  @Default_Language = LEFT(L.LocaleCode,2) FROM dbo.Event E WITH (NOLOCK) INNER JOIN dbo.Locales L WITH (NOLOCK)
			ON E.PK_Event = @PK_Event AND E.PK_DefaultLocale = L.PK_Locale
		
			SET @Language = CASE WHEN @Default_Language = 'XX' THEN @Language ELSE @Default_Language END
		END
	
		SELECT
			@SubTypeCodeNum = SortBy
		FROM
			PubEvents.dbo.dimDistributor d WITH (NOLOCK)
		JOIN
			PubEvents.dbo.dimDSSubType dst WITH (NOLOCK)
			ON
				d.PK_DSSubType = dst.PK_DSSubType
		WHERE
			d.DistributorID = @DistributorID
		
		;WITH cte_QualifiedSubEvent AS
		(
			SELECT
				SubEventNumber
			FROM
				dbo.SubEventQualifier seq WITH (nolock)
			JOIN 
				dbo.SubEvent se WITH (nolock)
				ON 
					seq.PK_SubEvent = se.PK_SubEvent
			WHERE 
				DistributorID = @DistributorID
				AND Qualified = 1
				and seq.PK_Event = @PK_Event
		),
		cte_Agenda AS 
		(	
			SELECT
				ai.IsSubHeader,
				ai.DisplayDescription,
				ai.DisplayTime,
				ai.DisplayLocation,
				ai.DisplayAttire,
				ai.LocalStartDate,
				ai.SortOrder
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
			OUTER APPLY
			(
				SELECT 
					COUNT(1) AS Qualified
				FROM 
					dbo.udf_SplitString(ai.SubEventNumber,',') s
				JOIN
					cte_QualifiedSubEvent qse 
					ON
						s.Val = qse.SubEventNumber
			) sq
			LEFT JOIN
				PubEvents.dbo.dimDSSubType dst WITH (NOLOCK)
				ON
					ai.TeamLevelRequired = dst.SubTypeCode			
			WHERE
				a.PK_Event = @PK_Event
				AND
				a.AgendaLanguage = @Language
				AND
				at.TypeDescription = 'Body'
				AND
				(ai.SubEventNumber IS NULL OR sq.Qualified > 0)
				AND
				(ai.TeamLevelRequired IS NULL OR @SubTypeCodeNum >= dst.SortBy)
		),
		cte_AgendaDay AS
		(
			SELECT 
				LocalStartDate
			FROM
				cte_Agenda
			WHERE
				IsSubHeader = 0
			GROUP BY
				LocalStartDate
			HAVING 
				COUNT(1) > 0
		)
	
		SELECT 
			a.IsSubHeader,
			a.DisplayDescription,
			a.DisplayTime,
			a.DisplayLocation,
			a.DisplayAttire
		FROM 
			cte_Agenda a
		JOIN 
			cte_AgendaDay d
			ON
				a.LocalStartDate = d.LocalStartDate
		ORDER BY
			a.SortOrder 

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



