CREATE VIEW [dbo].[v_dimDSLifeCycle] 
AS
SELECT
	PK_LifeCycle
	,LifeCycleCode 
	,LifeCycleName 
	--,IsValid
	,CASE LifeCycleCode 
		WHEN -1 THEN 0
		WHEN -2 THEN 0
		WHEN 220 THEN 1 --Success Builder
		WHEN 221 THEN 2 --Qual Senior Consultant
		WHEN 222 THEN 3 --Qualified Producer
		WHEN 223 THEN 4 --Qual Supervisor
		WHEN 224 THEN 5 --Qual World Team
		WHEN 225 THEN 6 --Qual Get Team
		WHEN 226 THEN 7 --Qual GET Plus
		WHEN 227 THEN 8 --Qual Mill Team
		WHEN 228 THEN 9 --Qual Mill Plus
		WHEN 229 THEN 10 --Qual Pres Team
		WHEN 230 THEN 11 --Qual 15K
		WHEN 231 THEN 12 --Qual Pres A Team
		WHEN 232 THEN 13 --Qual Pres B Team
		WHEN 233 THEN 14 --Qual 40K
		WHEN 234 THEN 15 --Qual Pres C Team
		WHEN 235 THEN 16 --Qual 60K
		WHEN 236 THEN 17 --Qual 70K
		WHEN 237 THEN 18 --Qual 80K
		WHEN 238 THEN 19 --Qual 90K
		WHEN 239 THEN 20 --Qual 100K
		WHEN 240 THEN 21 --Qual Chairman Club
		WHEN 241 THEN 22 --Founders Circle
		WHEN 242 THEN 23 --Qual C25
		WHEN 243 THEN 24 --Qual C35
		WHEN 244 THEN 25 --Qual C42
		WHEN 245 THEN 26 --Qual C50
	END AS SortOrder
FROM
	PubEvents.dbo.dimDSLifeCycle (NOLOCK)