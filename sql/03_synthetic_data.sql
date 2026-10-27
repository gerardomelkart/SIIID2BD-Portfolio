USE [SIIID_PORTFOLIO];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF EXISTS (SELECT 1 FROM dbo.DemoPeriod WHERE Period = '2026-09')
    THROW 50008, 'El corte sintético ya existe. No se modificaron sus datos.', 1;
INSERT dbo.DemoPeriod (Period) VALUES ('2026-09');
INSERT dbo.DemoFolder (Period, FolderId) VALUES ('2026-09', 'DEMO-C001');
INSERT dbo.DemoMonthlyVictim (Period, VictimId, FolderId, Offense)
VALUES ('2026-09', 'DEMO-V001', 'DEMO-C001', 'DESAPARICION'), ('2026-09', 'DEMO-V002', 'DEMO-C001', 'DESAPARICION');
INSERT dbo.DemoRegistryVictim (Period, VictimId, FolderId, Offense, Status)
VALUES ('2026-09', 'DEMO-V001', 'DEMO-C001', 'DESAPARICION', 'NO_LOCALIZADA'),
       ('2026-09', 'DEMO-V002', 'DEMO-C001', 'DESAPARICION', 'NO_LOCALIZADA');
COMMIT;
GO
