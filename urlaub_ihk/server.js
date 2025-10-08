const express = require('express');
const path = require('path');
const mysql = require('mysql2/promise');

const app = express();
const PORT = process.env.PORT || 8080;

const DB_HOST = process.env.DB_HOST;
const DB_USER = process.env.DB_USER;
const DB_PASSWORD = process.env.DB_PASSWORD;
const DB_NAME = process.env.DB_NAME;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'dist/browser')));

async function getConnection() {
  return mysql.createConnection({
    host: DB_HOST,
    user: DB_USER,
    password: DB_PASSWORD,
    database: DB_NAME
  });
}

// Hilfsfunktion: undefined → null
function sanitize(value) {
  return value === undefined ? null : value;
}

// Hilfsfunktion: Datum ins Format YYYY-MM-DD umwandeln
function normalizeDate(value) {
  if (!value) return null;
  // Direktes YYYY-MM-DD → passt schon
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return value;
  }
  // ISO-String oder Date-Objekt
  const date = new Date(value);
  if (!isNaN(date.getTime())) {
    return date.toISOString().slice(0, 10); // YYYY-MM-DD
  }
  return null;
}

// GET alle Urlaubsanträge
app.get('/api/urlaubsantraege', async (req, res) => {
  try {
    const conn = await getConnection();
    const [rows] = await conn.execute("SELECT * FROM urlaubsantraege");
    await conn.end();
    res.json(rows);
  } catch (err) {
    console.error("❌ Fehler beim SELECT:", err);
    res.status(500).json({ error: "DB-Select fehlgeschlagen", details: err.message });
  }
});

// POST neuer Urlaubsantrag
app.post('/api/urlaubsantraege', async (req, res) => {
  try {
    const { name, start, ende, grund } = req.body;
    console.log("📥 Request Body:", req.body); // Debugging-Ausgabe

    const conn = await getConnection();
    const [result] = await conn.execute(
      "INSERT INTO urlaubsantraege (name, start, ende, grund) VALUES (?, ?, ?, ?)",
      [sanitize(name), normalizeDate(start), normalizeDate(ende), sanitize(grund)]
    );
    await conn.end();

    console.log("✅ Insert erfolgreich:", result);
    res.status(201).json({ message: "Urlaub gespeichert", id: result.insertId });
  } catch (err) {
    console.error("❌ Fehler beim INSERT:", err);
    res.status(500).json({ error: "DB-Insert fehlgeschlagen", details: err.message });
  }
});

// DELETE Antrag
app.delete('/api/urlaubsantraege/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const conn = await getConnection();
    const [result] = await conn.execute("DELETE FROM urlaubsantraege WHERE id = ?", [id]);
    await conn.end();

    console.log("🗑️ Delete:", result);
    res.json({ message: "Urlaub gelöscht" });
  } catch (err) {
    console.error("❌ Fehler beim DELETE:", err);
    res.status(500).json({ error: "DB-Delete fehlgeschlagen", details: err.message });
  }
});

// Fallback für Angular/React/Vue SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist/browser/index.html'));
});

app.listen(PORT, () => {
  console.log(`🚀 Server läuft auf Port ${PORT}`);
  console.log(`DB_HOST=${DB_HOST}, DB_USER=${DB_USER}, DB_NAME=${DB_NAME}`);
});
