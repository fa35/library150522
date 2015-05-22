-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- check positive zahl

USE[Library]
GO
CREATE FUNCTION CheckPositiveZahl (@wert SMALLINT)
RETURNS BIT
AS
BEGIN
DECLARE @result bit = 1;
IF(@wert < 0)
	BEGIN 
		-- Wert ist negativ
		SET @result = 0;
	END
	RETURN @result;
END
GO

-- begleiche gebuehr

USE[Library]
GO
CREATE PROCEDURE sp_BegleicheGebuehr (@ausweisNr int, @betrag smallint)
AS
DECLARE @b bit = Library.dbo.CheckPositiveZahl(@betrag)

IF(@b = 0)
BEGIN
	PRINT 'Negative Beitraege werden nicht angenommen'
END
ELSE
	BEGIN
		DECLARE @personenId int, @currKontostand smallint;
		SET @personenId = (select pf_personen_id from Ausweise where ausweisnr = @ausweisNr)
		SET @currKontostand = (select top(1) kontostand from Nutzer where p_personen_id = @personenId)

		IF(@personenId >= 0)
			BEGIN
				UPDATE [dbo].[Nutzer]
					SET kontostand = (@currKontostand-@betrag)
					WHERE p_personen_id = @personenId
			END
		ELSE
			BEGIN
				PRINT 'Person konnte nicht gefunden werden.'
			END
	END
GO