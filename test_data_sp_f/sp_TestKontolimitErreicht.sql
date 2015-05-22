-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis


USE[Library]
GO
CREATE PROCEDURE sp_TestKontolimitErreicht
AS

DECLARE @personenId int = (select top(1) p_personen_id from Nutzer)

PRINT CONCAT('PersonenId= ', @personenId)

DECLARE @b bit = Library.dbo.CheckKontolimit(@personenId)

IF(@b = 0) -- = false = Kontostand >= 10000
BEGIN
	PRINT 'Kontostand-Limit erreicht (>= 10000)'
END
ELSE
BEGIN
	PRINT 'Kontostand-Limit nicht erreicht (< 10000)'
END

DECLARE @stand SMALLINT = (select kontostand from Nutzer where p_personen_id = @personenId)
PRINT CONCAT('Kontostand= ', @stand)

GO


EXEC sp_TestKontolimitErreicht