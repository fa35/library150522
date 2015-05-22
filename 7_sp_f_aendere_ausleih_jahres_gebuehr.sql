-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- aendere die jahres gebuehr

USE[Library]
GO
CREATE PROCEDURE sp_AendereJahresGebuehr @ausweisNr int, @gebuehr SMALLINT, @bibname nvarchar(max)
AS
DECLARE @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		UPDATE [dbo].[Bibliotheken] SET [gebuehren_jahr] = @gebuehr WHERE name = @bibname
	END
GO

-- andere die ausleih gebuehr

USE[Library]
GO
CREATE PROCEDURE sp_AendereLeihGebuehr @ausweisNr int, @gebuehr SMALLINT, @bibname nvarchar(max)
AS
DECLARE @mitarbeiter bit = Library.dbo.GetMitarbeiterRecht(@ausweisNr);
IF (@mitarbeiter = 0)
	BEGIN 
		PRINT 'Sie sind nicht berechtigt'
	END
ELSE
	BEGIN
		UPDATE [dbo].[Bibliotheken] SET [gebuehren_leihfrist] = @gebuehr WHERE name = @bibname
	END
GO
