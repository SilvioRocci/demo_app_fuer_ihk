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

app.get('/api/urlaubsantraege', async (req, res) => {
  const conn = await getConnection();
  const [rows] = await conn.execute("SELECT * FROM urlaubsantraege");
  await conn.end();
  res.json(rows);
});

app.post('/api/urlaubsantraege', async (req, res) => {
  const { name, start, end, grund } = req.body;
  const conn = await getConnection();
  await conn.execute(
    "INSERT INTO urlaubsantraege (name, start, end, grund) VALUES (?, ?, ?, ?)",
    [name, start, end, grund]
  );
  await conn.end();
  res.status(201).send("Urlaub gespeichert");
});

app.delete('/api/urlaubsantraege/:id', async (req, res) => {
  const { id } = req.params;
  const conn = await getConnection();
  await conn.execute("DELETE FROM urlaubsantraege WHERE id = ?", [id]);
  await conn.end();
  res.send("Urlaub gelöscht");
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist/browser/index.html'));
});

app.listen(PORT, () => {
  console.log(`Server läuft auf Port ${PORT}`);
});
