-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- sperre ausweis

USE[Library]
GO
CREATE PROCEDURE sp_SperreAusweis @ausweisNr int, @personenId int
AS
DECLARE @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		UPDATE [dbo].[Ausweise] SET [gesperrt] = 1 WHERE pf_personen_id = @personenId
	END
GO

-- entsperre ausweis

USE[Library]
GO
CREATE PROCEDURE sp_EntsperreAusweis @ausweisNr int, @personenId int
AS
DECLARE @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		UPDATE [dbo].[Ausweise] SET [gesperrt] = 0 WHERE pf_personen_id = @personenId
	END
GO
