USE [SIIID_PORTFOLIO];
GO
CREATE OR ALTER PROCEDURE dbo.usp_DemoReclassify
    @Period char(7),
    @VictimId varchar(40),
    @NewOffense varchar(20),
    @Reason nvarchar(200),
    @ExpectedRevision bigint
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @NewOffense IS NULL OR @NewOffense NOT IN ('DESAPARICION', 'OTRO', 'NO_DELITO')
        THROW 50002, 'Clasificación inválida.', 1;
    IF NULLIF(LTRIM(RTRIM(@Reason)), '') IS NULL
        THROW 50003, 'Se requiere motivo.', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Revision bigint, @PreviousOffense varchar(20);
        -- Serializa cambios del mismo corte y evita aprobar sobre una revisión obsoleta.
        SELECT @Revision = Revision FROM dbo.DemoPeriod WITH (UPDLOCK, HOLDLOCK) WHERE Period = @Period;
        IF @Revision IS NULL OR @ExpectedRevision IS NULL OR @Revision <> @ExpectedRevision
            THROW 50004, 'El periodo no existe o cambió su revisión.', 1;
        SELECT @PreviousOffense = Offense FROM dbo.DemoRegistryVictim WHERE Period = @Period AND VictimId = @VictimId;
        IF @PreviousOffense IS NULL
            THROW 50005, 'La víctima no existe en este periodo.', 1;
        IF @PreviousOffense = @NewOffense
            THROW 50006, 'La clasificación ya tiene ese valor.', 1;
        IF @PreviousOffense <> 'DESAPARICION' AND @NewOffense <> 'DESAPARICION'
            THROW 50007, 'Revierta la reclasificación antes de cambiarla a otra.', 1;
        UPDATE dbo.DemoRegistryVictim SET Offense = @NewOffense, Reason = @Reason
        WHERE Period = @Period AND VictimId = @VictimId;
        INSERT dbo.DemoReclassification (Period, VictimId, PreviousOffense, NewOffense, Reason)
        VALUES (@Period, @VictimId, @PreviousOffense, @NewOffense, @Reason);
        UPDATE dbo.DemoPeriod SET Revision = Revision + 1 WHERE Period = @Period;
        INSERT dbo.DemoAudit (Period, Revision, Kind)
        VALUES (@Period, @Revision + 1, CASE WHEN @NewOffense = 'DESAPARICION' THEN 'REVERT' ELSE 'RECLASSIFY' END);
        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO
