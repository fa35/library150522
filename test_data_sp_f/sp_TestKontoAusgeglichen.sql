-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis


USE[Library]
GO
CREATE PROCEDURE sp_TestKontoAusgeglichen
AS
DECLARE @personenId int = (select top(1) p_personen_id from Nutzer)
PRINT CONCAT('PersonenId= ', @personenId)
DECLARE @b bit = Library.dbo.CheckKontoAusgeglichen (@personenId)
IF(@b = 0) -- = false = Kontostand > 0
	BEGIN
		PRINT 'Kontostand nicht ausgeglichen (> 0)'
	END
ELSE
BEGIN
	PRINT 'Kontostand ausgeglichen (= 0)'
END
DECLARE @stand SMALLINT = (select kontostand from Nutzer where p_personen_id = @personenId)
PRINT CONCAT('Kontostand = ', @stand)

EXECUTE sp_TestKontoAusgeglichen
