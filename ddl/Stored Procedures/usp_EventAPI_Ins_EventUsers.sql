--**********************************************************************************************************
--   OBJECT NAME   : usp_EventAPI_Ins_EventUsers
--   MSSQL VERSION : 10.0 (SQL 2008)     
--   PURPOSE       : The proc will insert records to dbo.EventSecurityRoles and dbo.SecurityUsers table
--   INPUT PARAMS  : @EventPKs - PK's which needs to be updated, Add as string if more than one(Multiple PK's
--                               can be passed)
--                   @MainUser - Optional parameter, defaulted to 'SandhyaP'
--                   @timeZone - Optional parameter, defaulted to -8
--                   @MaxStaffUsers - Optional parameter, defaulted to 99
--                   @MaxAdminUsers - Optional parameter, defaulted to 20
--   OUT PARAMS    : NONE
--   CALLED BY     : NONE
--   CALLS         : NONE
--
--   EXEC Statement : Example 1 - Multiple PKs : EXEC dbo.usp_EventAPI_Ins_EventUsers '113,114,115'
--                    Example 2 - Single PK : EXEC dbo.usp_EventAPI_Ins_EventUsers '113'
--                    Example 3 - Multiple PKs with other optional parameters:
--                            EXEC dbo.usp_EventAPI_Ins_EventUsers '113,114,115','AravindaV','+5.5'
--                                                                                                              
--   VERSION HISTORY:
--   VER	DATE           DEVELOPER               COMMENTS
--   ===    ===========    ================        =================
--   1.0    23-Oct-2009    Aravinda, Infosys	   First version.
--	 1.1	17-Feb-2021	   alejandramed			   Allow @MaxStaffUsers and @MaxAdminUsers from 100 to 999
--***********************************************************************************************************
CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_EventUsers] (
    @EventPKs VARCHAR(MAX),
    @MainUser VARCHAR(200) = 'SandhyaP',
    @timeZone NUMERIC(5, 2) = '-8',
    @MaxStaffUsers INT = 99,
    @MaxAdminUsers INT = 20
)

AS
BEGIN

SET NOCOUNT ON

-- Declare the required variables
DECLARE @Pos INT
DECLARE @tblEventPKS TABLE(PK_Event INT)
DECLARE @PK VARCHAR(10)
DECLARE @PK_Event INT
DECLARE @BeginUserID INT
DECLARE @EndUserID INT
DECLARE @StartDate DATETIME
DECLARE @SQL NVARCHAR(4000)
DECLARE @Len INT 

SET @StartDate = GETDATE()

-- TRIM the Input string
SET @EventPKs = LTRIM(RTRIM(@EventPKs)) + ','

-- Get First position of ','
SET @Pos = CHARINDEX(',', @EventPKs, 1)

-- If atleast one ',' in the string
WHILE @Pos > 0
BEGIN
    -- Extract Left most PK
    SET @PK = LTRIM(RTRIM(LEFT(@EventPKs, @Pos - 1)))

    -- If Event PK is NOT NULL
    IF @PK <> ''
    BEGIN
        -- Insert into table variable, this will be used later
        INSERT INTO @tblEventPKs (PK_Event) VALUES (CAST(@PK AS INT))
    END
    -- Remove the inserted PK from String
    SET @EventPKs = RIGHT(@EventPKs, LEN(@EventPKs) - @Pos)
    -- Get Position again after removing processed PK
    SET @Pos = CHARINDEX(',', @EventPKs, 1)
END

-- Previously generated table variable will be used in cursor
DECLARE eq_cursor CURSOR STATIC FOR 
	SELECT
		PK_Event
	FROM
		dbo.Event WITH (NOLOCK)
    WHERE
        PK_Event IN (SELECT PK_Event FROM @tblEventPKs)
	
OPEN eq_cursor
FETCH NEXT FROM eq_cursor INTO @PK_Event

WHILE @@FETCH_STATUS = 0
BEGIN

DECLARE @i INT
DECLARE @j VARCHAR(3)

SET @i = 1
SET @j = 0

/* Delete the entries in EventSecurityRoles */
DELETE FROM dbo.EventSecurityRoles WHERE PK_Event = @PK_Event

/* Delete the entries in SecurityUsers for Staff & Admin */
SET @SQL = 'DELETE FROM dbo.SecurityUsers WHERE UserID LIKE ''S%-' + LTRIM(STR(@PK_Event)) + ''''
EXEC sp_executesql @SQL
SET @SQL = 'DELETE FROM dbo.SecurityUsers WHERE UserID LIKE ''A%-' + LTRIM(STR(@PK_Event)) + ''''
EXEC sp_executesql @SQL

/* Insert the staff Users in SecurityUsers */
WHILE @i <= @MaxStaffUsers
BEGIN

SET @Len = IIF(@i < 100, 2,3)

INSERT INTO dbo.SecurityUsers(
    UserID,
    UserPassword,
    CreatedDateUTC,
    UserTimeZone,
    CreatedBy,
    ModifiedDateUTC,
    ModifiedBy
)
VALUES(
    'S' + RIGHT(LTRIM(@j) + LTRIM(STR(@i)),@Len) + '-' + LTRIM(STR(@PK_Event)),
    'herbalife',
    @StartDate,
    @timeZone,
    @MainUser,
    @StartDate,
    @MainUser
)

SET @i = @i + 1

END

/* Insert the Admin in SecurityUsers */

SET @i = 1

WHILE @i <= @MaxAdminUsers
BEGIN

SET @Len = IIF(@i < 100, 2,3)

INSERT INTO dbo.SecurityUsers(
    UserID,
    UserPassword,
    CreatedDateUTC,
    UserTimeZone,
    CreatedBy,
    ModifiedDateUTC,
    ModifiedBy
)
VALUES(
    'A' + RIGHT(LTRIM(@j) + LTRIM(STR(@i)),@Len) + '-' + LTRIM(STR(@PK_Event)), 
    'herbalife',
    @StartDate,
    @timeZone,
    @MainUser,
    @StartDate,
    @MainUser
)

SET @i = @i + 1

END

/* Get all the pk values for staff users  of the event */

IF OBJECT_ID('tempdb..##Users') IS NOT NULL
DROP TABLE ##Users

SET @SQL = 'SELECT MIN(PK_SecurityUser) as Beginuserid, MAX(PK_SecurityUser) as Enduserid INTO ##Users FROM dbo.SecurityUsers (NOLOCK) where UserID like ''S%-' + LTRIM(STR(@PK_Event)) + ''''
EXEC sp_executesql @SQL

SELECT
    @BeginUserId = Beginuserid,
    @Enduserid = EndUserId
FROM ##Users

/* Insert the Staff Users in EventSecurityRoles */
INSERT INTO dbo.EventSecurityRoles(PK_SecurityRole,PK_Event,PK_SecurityUser)
SELECT 1, @PK_Event, PK_SecurityUser
FROM dbo.SecurityUsers WITH (NOLOCK)
WHERE PK_SecurityUser BETWEEN @BeginUserID AND @EndUserID 

/* Get all the pk values for Admin  of the event */

IF OBJECT_ID('tempdb..##Users') IS NOT NULL
DROP TABLE ##Users

SET @SQL = 'SELECT MIN(PK_SecurityUser) as Beginuserid, MAX(PK_SecurityUser) as Enduserid INTO ##Users FROM dbo.SecurityUsers (NOLOCK) where UserID like ''A%-' + ltrim(str(@PK_Event)) + ''''
EXEC sp_executesql @SQL

SELECT
    @BeginUserId = Beginuserid,
    @Enduserid = EndUserId
FROM ##Users

/* Insert the Admin in EventSecurityRoles */
INSERT INTO dbo.EventSecurityRoles(PK_SecurityRole,PK_Event,PK_SecurityUser)
SELECT 2, @PK_Event, PK_SecurityUser
FROM dbo.SecurityUsers WITH (NOLOCK)
WHERE PK_SecurityUser BETWEEN @BeginUserID AND @EndUserID 


/* Access the BI team Members */

SET @BeginUserId = 143
SET @Enduserid = 149

INSERT INTO dbo.EventSecurityRoles(PK_SecurityRole,PK_Event,PK_SecurityUser)
SELECT 2, @PK_Event, PK_SecurityUser
FROM dbo.SecurityUsers WITH (NOLOCK)
WHERE PK_SecurityUser BETWEEN @BeginUserID AND @EndUserID 

FETCH NEXT FROM eq_cursor INTO @PK_Event
END

CLOSE eq_cursor
DEALLOCATE eq_cursor

END
GO
