-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- konto ausgeglichen ?

USE[Library]
GO
CREATE FUNCTION CheckKontoAusgeglichen (@personenId int)
RETURNS BIT
AS
BEGIN
	DECLARE @result bit = 0
	DECLARE @kontostand SMALLINT = (select kontostand from nutzer where p_personen_id = @personenId)
	IF(@kontostand = 0)
		BEGIN
			SET @result = 1; -- konto ist ausgeglichen
		END
	RETURN @result;
END
GO

-- verlaegere ausweis


USE[Library]
GO
CREATE PROCEDURE sp_VerlaengereAusweis @ausweisNr int, @personenId int
AS
DECLARE @ok bit = 0, @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
		RETURN @ok
	END
ELSE
	BEGIN
		DECLARE @bit bit = Library.dbo.CheckKontoAusgeglichen(@personenId)

		IF(@bit = 0)
			BEGIN
				PRINT 'Das Nutzer-Konto ist nicht ausgeglichen'
				RETURN @ok
			END
		ELSE
			BEGIN
				UPDATE [dbo].[Ausweise] SET [gueltigBis] = DATEADD(YEAR, 10, GETDATE()) WHERE pf_personen_id = @personenId
				SET @ok = 1;
				RETURN @ok
			END
	END
GO

