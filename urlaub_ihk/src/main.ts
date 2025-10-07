interface Urlaub {
  name: string;
  start: string;
  end: string;
  grund: string;
}

const form = document.getElementById('urlaubForm') as HTMLFormElement;
const urlaubListeEl = document.getElementById('urlaubListe') as HTMLUListElement;
const urlaubsListe: Urlaub[] = [];

form.addEventListener('submit', (event) => {
  event.preventDefault();

  const name = (document.getElementById('name') as HTMLInputElement).value;
  const start = (document.getElementById('start') as HTMLInputElement).value;
  const end = (document.getElementById('end') as HTMLInputElement).value;
  const grund = (document.getElementById('grund') as HTMLTextAreaElement).value;

  const neuerUrlaub: Urlaub = { name, start, end, grund };
  urlaubsListe.push(neuerUrlaub);

  // Liste aktualisieren
  renderUrlaubsListe();

  // Formular zurücksetzen
  form.reset();
});

function renderUrlaubsListe() {
  urlaubListeEl.innerHTML = '';
  for (const urlaub of urlaubsListe) {
    const li = document.createElement('li');
    li.textContent = `${urlaub.name} | ${urlaub.start} - ${urlaub.end} | ${urlaub.grund}`;
    urlaubListeEl.appendChild(li);
  }
}
