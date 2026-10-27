-- Ejecutar después de 03 en una base de laboratorio. No deja cambios: termina en ROLLBACK.
USE [SIIID_PORTFOLIO];
GO
SET XACT_ABORT ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DemoPeriod WHERE Period = '2026-09' AND Revision = 0)
    THROW 50009, 'Se necesita el corte sintético recién instalado.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.usp_DemoReclassify '2026-09', 'DEMO-V001', 'NO_DELITO', N'Motivo ficticio', 0;
    IF (SELECT COUNT(*) FROM dbo.vw_DemoActiveDisappearance WHERE Period = '2026-09') <> 1
        THROW 50010, 'La reclasificación debe afectar solo una víctima.', 1;
    IF (SELECT COUNT(*) FROM dbo.DemoMonthlyVictim WHERE Period = '2026-09') <> 2
        THROW 50011, 'La reclasificación no debe modificar el mensual.', 1;
    EXEC dbo.usp_DemoReclassify '2026-09', 'DEMO-V001', 'DESAPARICION', N'Reversión ficticia', 1;
    IF (SELECT COUNT(*) FROM dbo.vw_DemoActiveDisappearance WHERE Period = '2026-09') <> 2
        THROW 50012, 'La reversión debe restaurar la desaparición vigente.', 1;
    IF (SELECT COUNT(*) FROM dbo.DemoReclassification WHERE Period = '2026-09') <> 2
        THROW 50013, 'Se deben conservar ambos eventos.', 1;
    ROLLBACK;
    SELECT N'Comprobaciones correctas; cambios revertidos' AS Resultado;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    THROW;
END CATCH;
GO
