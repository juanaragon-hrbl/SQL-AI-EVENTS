CREATE PROCEDURE [dbo].[usp_EventsAT_Get_EventSubTypes]	
    -- MANDATORY
     @PK_Locale INT
    ,@PK_MasterEvent INT	
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:			dbo.usp_EventsAT_Get_EventSubTypes

USE:	
			DECLARE @e int, @em varchar(4000)
		
				EXEC usp_EventsAT_Get_EventSubTypes
					 @PK_Locale = 46
					,@PK_MasterEvent = 19
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Returns the SubEvents that don't belong to the Master Event Selected

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventSubTypes

VERSIONS
--------------------------------------------------------------------
2	2019-08-08	OrlandoL	Refactor code (SRE)
1.1 2013-05-09  SandhyaP	dropdown has subtypes with translations missing for the selected locale and master type.
1	2013-01-24	Sushma		Initial
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE @LocaleID INT

BEGIN TRY
	
	SELECT DISTINCT A.EventSubType--A.EventSubType
	FROM
	(
		/* Pick all the SubTypes which don't belong to the EventType and Locale of MasterEvent's SubTypes*/
		SELECT A.EventSubType
		FROM
		(
			SELECT 
				EST.EventSubType, ESG.PK_EventType, ESG.PK_EventSubTypeGroupMaster
			FROM 
				dbo.EventSubTypes EST WITH (NOLOCK)
			INNER JOIN 
				dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK)
				ON 
					EST.PK_EventSubType = ESL.PK_EventSubType
			INNER JOIN 
				dbo.EventSubTypeGroup ESG WITH (NOLOCK)
				ON 
					EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
			WHERE
				EST.IsActive = 1
				AND
				ESG.PK_EventSubTypeGroupMaster = @PK_MasterEvent
			EXCEPT
			SELECT 
				EST.EventSubType, ESG.PK_EventType, ESG.PK_EventSubTypeGroupMaster
			FROM 
				dbo.EventSubTypes EST WITH (NOLOCK)
			INNER JOIN 
				dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK)
				ON 
					EST.PK_EventSubType = ESL.PK_EventSubType
			INNER JOIN 
				dbo.EventSubTypeGroup ESG WITH (NOLOCK)
				ON 
					EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
			WHERE 
				ESL.PK_Locale = @PK_Locale
				AND 
				ESG.PK_EventSubTypeGroupMaster = @PK_MasterEvent
				AND 
				EST.IsActive = 1
		)A

		--UNION ALL

		/* Pick all the SubTypes where its not associated to all the EventTypes of the Master*/
		--SELECT A.EventSubType 
		--FROM
		--(
		--	SELECT A.EventSubType--, MAX(a.Masters), SUM(A.SubTypes)
		--	FROM
		--	(
		--		SELECT ESG.PK_EventSubTypeGroupMaster, EST.EventSubType, ESA.Masters1 as [Masters], COUNT(0) AS [SubTypes]
		--		FROM
		--			dbo.EventSubTypes (NOLOCK) EST
		--			INNER JOIN dbo.EventSubTypeLocaleDesc(NOLOCK) ESL
		--				ON EST.PK_EventSubType = ESL.PK_EventSubType
		--				AND
		--				ESL.PK_Locale = @PK_Locale
		--				AND
		--				EST.IsActive = 1
		--			INNER JOIN dbo.EventSubTypeGroup(NOLOCK) ESG
		--				ON EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
		--				AND
		--				ESG.PK_EventSubTypeGroupMaster = @PK_MasterEvent
		--			LEFT JOIN
		--			(
		--				SELECT ESG.PK_EventSubTypeGroupMaster, COUNT(0) AS [Masters1]
		--				FROM dbo.EventSubTypeGroup ESG
		--				GROUP BY esg.PK_EventSubTypeGroupMaster
		--			)ESA
		--			ON ESG.PK_EventSubTypeGroupMaster = ESA.PK_EventSubTypeGroupMaster
		--			GROUP BY ESG.PK_EventSubTypeGroupMaster,  EST.EventSubType, ESA.Masters1
		--		--HAVING COUNT(0) < ESS.Masters
		--		) A
		--		WHERE (A.Masters <> A.SubTypes)
		--)A

	) A
	--WHERE A.PK_EventSubTypeGroupMaster = 10
	ORDER BY 1
	
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

