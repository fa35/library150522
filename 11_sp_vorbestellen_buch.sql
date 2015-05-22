-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- bestelle buch vor

USE[Library]
GO
CREATE PROCEDURE sp_BestelleBuchVor (@isbn bigint, @ausweisNr int)
AS
DECLARE @gesperrt bit = Library.dbo.GetAusweisGesperrt (@ausweisNr)

IF(@gesperrt = 1)
BEGIN
	PRINT 'Ausweis ist geperrt'
END
ELSE
	BEGIN
		DECLARE @personenId int = (select pf_personen_id from Ausweise where ausweisnr = @ausweisNr)

		INSERT INTO [dbo].[Vorbestellte_Buecher] ([pf_isbn], [pf_personen_id])
			 VALUES (@isbn, @personenId)
	END
GO