-- @license: GPLv2
-- @author: luxfinis
-- @source: github/luxfinis

USE[Library]
GO
CREATE PROCEDURE sp_TestPositiveZahlCheck @zahl SMALLINT
AS
DECLARE @b bit = Library.dbo.CheckPositiveZahl (@zahl)
IF(@b = 0) -- = false
BEGIN
	PRINT 'Zahl ist nicht positiv oder keine Ganzzahl'
END
ELSE
BEGIN
	PRINT 'Zahl ist positiv'
END
PRINT CONCAT('Kontostand = ', @zahl)
GO

EXEC sp_TestPositiveZahlCheck 15