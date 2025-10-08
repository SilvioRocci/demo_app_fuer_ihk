const apiUrl = "/api/urlaubsantraege";

const form = document.getElementById('urlaubForm') as HTMLFormElement;
const urlaubListeEl = document.getElementById('urlaubListe') as HTMLUListElement;
const loadBtn = document.getElementById('loadBtn') as HTMLButtonElement;

// Formular absenden
form.addEventListener('submit', async (event) => {
  event.preventDefault();

  const name = (document.getElementById('name') as HTMLInputElement).value;
  const start = (document.getElementById('start') as HTMLInputElement).value;
  const end = (document.getElementById('end') as HTMLInputElement).value;
  const grund = (document.getElementById('grund') as HTMLTextAreaElement).value;
  const neuerUrlaub = { name, start, end, grund };
  

  await fetch(apiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(neuerUrlaub),
  });

  form.reset();
});

// Anträge laden (GET)
async function ladeUrlaube() {
  const res = await fetch(apiUrl);
  const urlaube = await res.json();

  urlaubListeEl.innerHTML = "";
  urlaube.forEach((urlaub: any) => {
    const li = document.createElement("li");
    li.textContent = `${urlaub.name} | ${urlaub.start} - ${urlaub.end} | ${urlaub.grund}`;

    // Löschen-Button
    const deleteBtn = document.createElement("button");
    deleteBtn.textContent = "Löschen";
    deleteBtn.style.marginLeft = "10px";
    deleteBtn.addEventListener("click", async () => {
      await fetch(`${apiUrl}/${urlaub.id}`, { method: "DELETE" });
      ladeUrlaube();
    });

    li.appendChild(deleteBtn);
    urlaubListeEl.appendChild(li);
  });
}

// Klick auf „Anträge laden“-Button
loadBtn.addEventListener("click", ladeUrlaube);
