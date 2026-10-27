-- SQL Server 2019+. Ejecutar exclusivamente en una base de laboratorio vacía.
USE [SIIID_PORTFOLIO];
GO
SET XACT_ABORT ON;
GO
IF OBJECT_ID(N'dbo.DemoPeriod') IS NOT NULL
    THROW 50001, 'El modelo ya existe. Este script no elimina ni reemplaza datos.', 1;
GO
BEGIN TRANSACTION;
CREATE TABLE dbo.DemoPeriod (
    Period char(7) NOT NULL PRIMARY KEY,
    Revision bigint NOT NULL CONSTRAINT DF_DemoPeriod_Revision DEFAULT 0,
    CONSTRAINT CK_DemoPeriod_Date CHECK (
        Period LIKE '[12][0-9][0-9][0-9]-[01][0-9]'
        AND TRY_CONVERT(date, Period + '-01', 23) IS NOT NULL)
);
CREATE TABLE dbo.DemoFolder (
    Period char(7) NOT NULL,
    FolderId varchar(40) NOT NULL,
    CONSTRAINT PK_DemoFolder PRIMARY KEY (Period, FolderId),
    CONSTRAINT FK_DemoFolder_Period FOREIGN KEY (Period) REFERENCES dbo.DemoPeriod(Period),
    CONSTRAINT CK_DemoFolder_Id CHECK (FolderId LIKE 'DEMO-%')
);
CREATE TABLE dbo.DemoMonthlyVictim (
    Period char(7) NOT NULL,
    VictimId varchar(40) NOT NULL,
    FolderId varchar(40) NOT NULL,
    Offense varchar(20) NOT NULL,
    CONSTRAINT PK_DemoMonthlyVictim PRIMARY KEY (Period, VictimId),
    CONSTRAINT FK_DemoMonthlyVictim_Folder FOREIGN KEY (Period, FolderId) REFERENCES dbo.DemoFolder(Period, FolderId),
    CONSTRAINT CK_DemoMonthlyVictim_Id CHECK (VictimId LIKE 'DEMO-%'),
    CONSTRAINT CK_DemoMonthlyVictim_Offense CHECK (Offense IN ('DESAPARICION', 'OTRO'))
);
CREATE TABLE dbo.DemoRegistryVictim (
    Period char(7) NOT NULL,
    VictimId varchar(40) NOT NULL,
    FolderId varchar(40) NOT NULL,
    Offense varchar(20) NOT NULL,
    Status varchar(20) NOT NULL,
    Reason nvarchar(200) NULL,
    CONSTRAINT PK_DemoRegistryVictim PRIMARY KEY (Period, VictimId),
    CONSTRAINT FK_DemoRegistryVictim_Folder FOREIGN KEY (Period, FolderId) REFERENCES dbo.DemoFolder(Period, FolderId),
    CONSTRAINT CK_DemoRegistryVictim_Id CHECK (VictimId LIKE 'DEMO-%'),
    CONSTRAINT CK_DemoRegistryVictim_Offense CHECK (Offense IN ('DESAPARICION', 'OTRO', 'NO_DELITO')),
    CONSTRAINT CK_DemoRegistryVictim_Status CHECK (Status IN ('NO_LOCALIZADA', 'LOCALIZADA')),
    CONSTRAINT CK_DemoRegistryVictim_Reason CHECK (Offense = 'DESAPARICION' OR LEN(LTRIM(RTRIM(Reason))) > 0 AND Reason IS NOT NULL)
);
-- BANCI referencia la carpeta histórica, no la fila mensual: una reclasificación puede retirarse del mensual.
CREATE TABLE dbo.DemoReclassification (
    EventId bigint IDENTITY NOT NULL PRIMARY KEY,
    Period char(7) NOT NULL,
    VictimId varchar(40) NOT NULL,
    PreviousOffense varchar(20) NOT NULL,
    NewOffense varchar(20) NOT NULL,
    Reason nvarchar(200) NOT NULL,
    AtUtc datetime2(7) NOT NULL CONSTRAINT DF_DemoReclassification_At DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_DemoReclassification_Victim FOREIGN KEY (Period, VictimId) REFERENCES dbo.DemoRegistryVictim(Period, VictimId)
);
CREATE TABLE dbo.DemoAudit (
    EventId bigint IDENTITY NOT NULL PRIMARY KEY,
    Period char(7) NOT NULL,
    Revision bigint NOT NULL,
    Kind varchar(30) NOT NULL,
    AtUtc datetime2(7) NOT NULL CONSTRAINT DF_DemoAudit_At DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_DemoAudit_Revision UNIQUE (Period, Revision),
    CONSTRAINT FK_DemoAudit_Period FOREIGN KEY (Period) REFERENCES dbo.DemoPeriod(Period)
);
CREATE INDEX IX_DemoRegistryVictim_Offense ON dbo.DemoRegistryVictim(Period, Offense) INCLUDE (VictimId, FolderId);
COMMIT;
GO
CREATE OR ALTER VIEW dbo.vw_DemoActiveDisappearance AS
SELECT Period, VictimId, FolderId, Status
FROM dbo.DemoRegistryVictim
WHERE Offense = 'DESAPARICION';
GO
