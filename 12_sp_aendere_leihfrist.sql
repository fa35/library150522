-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- aendere leihfrist / die ausleihwochen

USE[Library]
GO
CREATE PROCEDURE sp_AendereLeihfrist @ausweisNr int, @leihwochen tinyint, @bibname nvarchar(max)
AS
DECLARE @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		UPDATE [dbo].[Bibliotheken] SET [leihfrist_wochen] = @leihwochen WHERE name = @bibname
	END
GO

-- gebe exemplar zurueck

USE[Library]
GO
CREATE PROCEDURE sp_GebeExemplarZurueck (@signature varchar(10))
AS
DELETE FROM Ausgeliehene_Exemplare
WHERE pf_signatur = @signature
GO

-- check kuerzel

USE[Library]
GO
CREATE PROCEDURE sp_KuerzelPruefung @preKuerzel char(4)
AS

IF (SELECT COUNT(*) FROM Exemplare WHERE SUBSTRING(p_signatur, 0,4) = @preKuerzel) > 0
	BEGIN
		RETURN 1;
	END
ELSE
	BEGIN
		RETURN 0;
	END
