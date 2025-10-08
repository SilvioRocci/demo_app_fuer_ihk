-- Datenbank auswählen
CREATE DATABASE IF NOT EXISTS urlaub_app;
USE urlaub_app;

-- Tabelle für Urlaubsanträge
CREATE TABLE IF NOT EXISTS urlaubsantraege (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    start DATE NOT NULL,
    ende DATE NOT NULL,
    grund TEXT
);