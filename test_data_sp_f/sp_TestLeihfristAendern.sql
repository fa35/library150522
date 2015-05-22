-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

-- aendere leihfrist

USE[Library]
GO
CREATE PROCEDURE sp_TestLeihfristAendern @ausweisNr int, @leihwochen tinyint
AS

PRINT 'Hole Bibliothek-Inforamtionen'
DECLARE @bibId int = (SELECT TOP(1) p_bibliothek_id FROM Bibliotheken)
DECLARE @bibname nvarchar(max) = (SELECT name FROM Bibliotheken WHERE p_bibliothek_id = @bibId)
DECLARE @bibwochen int = (SELECT leihfrist_wochen FROM Bibliotheken WHERE p_bibliothek_id = @bibId)

PRINT CONCAT('ID = ', @bibId, ' Name = ', @bibname, ' aktuelle Leihwochen = ', @bibwochen)
PRINT CONCAT( 'Versuche Leihwochen auf ', @leihwochen, ' Wochen zu setzen')

EXEC sp_AendereLeihfrist @ausweisNr, @leihwochen, @bibname 

PRINT 'Prozedure sp_AendereLeihfrist wurde ausgefuehrt'
PRINT CONCAT('Pruefe ob die aktuelle Leihfrist nun ', @leihwochen, ' Wochen entspricht')

DECLARE @aktuell int = (SELECT leihfrist_wochen FROM Bibliotheken WHERE p_bibliothek_id = @bibId)

IF(@aktuell = @leihwochen)
	BEGIN
		PRINT CONCAT('Aktuell sind ', @aktuell, ' Wochen eingetragen. Prozedur war erfolgreich')
	END
ELSE
	BEGIN
		PRINT CONCAT('Aktuell sind ', @aktuell, ' Wochen eingetragen. Etwas stimmt nicht. Es haette ', @leihwochen, ' Wochen sein muessen')
	END

PRINT CONCAT('Setze Leihwochen wieder auf die urspruenglichen ', @bibwochen, ' Wochen zurueck')
EXEC sp_AendereLeihfrist @ausweisNr, @bibwochen, @bibname
SET @aktuell = (SELECT leihfrist_wochen FROM Bibliotheken WHERE p_bibliothek_id = @bibId)

IF(@aktuell = @bibwochen)
	BEGIN
		PRINT CONCAT('Aktuell sind ', @aktuell, ' Wochen eingetragen. Prozedur war erfolgreich')
	END
ELSE
	BEGIN
		PRINT CONCAT('Aktuell sind ', @aktuell, ' Wochen eingetragen. Etwas stimmt nicht. Es haette ', @bibwochen, ' Wochen sein muessen')
	END
GO


EXEC sp_TestLeihfristAendern 2, 66