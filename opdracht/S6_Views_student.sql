-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S6: Views
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
-- ------------------------------------------------------------------------


-- S6.1.
--
-- 1. Maak een view met de naam "deelnemers" waarmee je de volgende gegevens uit de tabellen inschrijvingen en uitvoering combineert:
--    inschrijvingen.cursist, inschrijvingen.cursus, inschrijvingen.begindatum, uitvoeringen.docent, uitvoeringen.locatie
CREATE OR REPLACE VIEW deelnemers AS
SELECT i.cursist, i.cursus, i.begindatum, u.docent, u.locatie FROM inschrijvingen i
JOIN uitvoeringen u on i.cursus = u.cursus and i.begindatum = u.begindatum;

-- 2. Gebruik de view in een query waarbij je de "deelnemers" view combineert met de "personeels" view (behandeld in de les):
     CREATE OR REPLACE VIEW personeel AS
 	     SELECT mnr, voorl, naam as medewerker, afd, functie
       FROM medewerkers;

SELECT * FROM personeel p
JOIN deelnemers d ON d.cursist = p.mnr;

-- 3. Is de view "deelnemers" updatable ? Waarom ?

-- Nee. Deelnemers kan je niet updaten, deze bestaat namelijk uit meerdere tabellen.
-- Als je het wel probeert krijg je deze error:
--[55000] ERROR: cannot update view "deelnemers"
-- Detail: Views that do not select from a single table or view are not automatically updatable.

-- S6.2.
--
-- 1. Maak een view met de naam "dagcursussen". Deze view dient de gegevens op te halen: 
--      code, omschrijving en type uit de tabel cursussen met als voorwaarde dat de lengte = 1. Toon aan dat de view werkt.
CREATE OR REPLACE VIEW dagcursussen AS
SELECT code, omschrijving, type FROM cursussen
WHERE lengte = 1;

SELECT * FROM dagcursussen;

-- 2. Maak een tweede view met de naam "daguitvoeringen". 
--    Deze view dient de uitvoeringsgegevens op te halen voor de "dagcurssussen" (gebruik ook de view "dagcursussen"). Toon aan dat de view werkt
CREATE OR REPLACE VIEW daguitvoeringen AS
SELECT * FROM uitvoeringen
WHERE cursus IN (SELECT code FROM dagcursussen);

SELECT * FROM daguitvoeringen;

-- 3. Verwijder de views en laat zien wat de verschillen zijn bij DROP view <viewnaam> CASCADE en bij DROP view <viewnaam> RESTRICT
DROP VIEW dagcursussen RESTRICT;
-- Bij deze kan je de view niet droppen want "daguitvoeringen" depend er op (dit is de default).

DROP VIEW dagcursussen CASCADE;
-- Bij deze kan je wel de view droppen want cascade doet gelijk alles wat er op depend ook droppen.

