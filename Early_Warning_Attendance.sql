DROP TABLE CUSTOM.CUSTOM_EARLY_WARNING_ATTENDANCE;

CREATE TABLE CUSTOM.CUSTOM_EARLY_WARNING_ATTENDANCE (
STUDENT_NUMBER INT,
STUDENTID INT,
STUDENTKEY INT,
SYSTEMSTUDENTID VARCHAR(25),
TERMKEY INT,
ABSENCES INT,
MEMBERSHIP INT,
UNEXCUSED_ABSENCES INT,
TARDIES INT);

CREATE INDEX EW_GRADES ON CUSTOM.CUSTOM_EARLY_WARNING_ATTENDANCE (STUDENT_NUMBER,TERMKEY);

INSERT INTO CUSTOM.CUSTOM_EARLY_WARNING_ATTENDANCE (STUDENT_NUMBER,STUDENTID,STUDENTKEY,SYSTEMSTUDENTID,TERMKEY,ABSENCES,MEMBERSHIP,UNEXCUSED_ABSENCES,TARDIES)
SELECT
S.STUDENT_NUMBER AS STUDENT_NUMBER,
S.ID AS STUDENTID,
DS.STUDENTKEY,
DS.SYSTEMSTUDENTID,
COALESCE(CAST(CAST(T.ID AS VARCHAR) + CAST(E.SCHOOLID AS VARCHAR) AS INT),-1) AS TERMKEY, --CREATE TERMKEY BY CONCATENATING TERMID AND A.SCHOOLID AND CASTING AS INT
SUM(CASE WHEN AC.PRESENCE_STATUS_CD = 'Absent' THEN 1 ELSE 0 END) ABSENCES,
SUM(1) MEMBERSHIP,
SUM(CASE WHEN DESCRIPTION IN ('Absent','Medical Unexcused','Tardy Absent','Released Early Absent') THEN 1 ELSE 0 END) UNEXCUSED_ABSENCES,
SUM(CASE WHEN DESCRIPTION IN ('Tardy','Tardy Excused','Tardy Released Early') THEN 1 ELSE 0 END) TARDIES
--INTO #EW_Attendance
FROM POWERSCHOOL.POWERSCHOOL_STUDENTS S
JOIN (SELECT SCHOOLID, ID AS STUDENTID, ENTRYDATE, EXITDATE, GRADE_LEVEL FROM POWERSCHOOL.POWERSCHOOL_STUDENTS S
		UNION
	  SELECT SCHOOLID, STUDENTID, ENTRYDATE, EXITDATE, GRADE_LEVEL FROM POWERSCHOOL.POWERSCHOOL_REENROLLMENTS R) E ON E.STUDENTID = S.ID
JOIN [custom].[custom_StudentBridge] SB ON SB.STUDENT_NUMBER = S.STUDENT_NUMBER
JOIN DW.DW_DIMSTUDENT DS ON DS.SYSTEMSTUDENTID = SB.SYSTEMSTUDENTID
JOIN POWERSCHOOL.POWERSCHOOL_CALENDAR_DAY CD ON CD.SCHOOLID = E.SCHOOLID AND CD.DATE_VALUE BETWEEN E.ENTRYDATE AND E.EXITDATE
LEFT JOIN [Cust1220].[powerschool].[powerschool_ATTENDANCE] A ON A.SCHOOLID = E.SCHOOLID AND A.STUDENTID = E.STUDENTID AND A.ATT_DATE = CD.DATE_VALUE
LEFT JOIN [powerschool].[powerschool_ATTENDANCE_CODE] AC ON AC.ID = ATTENDANCE_CODEID
LEFT JOIN [powerschool].[powerschool_TERMS] T ON CD.DATE_VALUE BETWEEN T.FIRSTDAY AND T.LASTDAY AND T.SCHOOLID = E.SCHOOLID
WHERE 
	CD.INSESSION = 1 AND
	(ATT_MODE_CODE = 'ATT_ModeDaily' OR ATT_MODE_CODE IS NULL)
GROUP BY
		S.STUDENT_NUMBER,
		T.ID,
		T.YEARID,
		E.SCHOOLID,
		S.ID,
		DS.STUDENTKEY,
		DS.SYSTEMSTUDENTID;
