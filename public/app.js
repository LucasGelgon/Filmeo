const GENRE_LABELS = {
  action: "Action", sci_fi: "Science-fiction", drama: "Drame", crime: "Policier",
  thriller: "Thriller", horror: "Horreur", comedy: "Comedie", romance: "Romance",
  animation: "Animation", fantasy: "Fantastique", family: "Familial", mystery: "Mystere",
};

const MOOD_LABELS = {
  intense: "Intense", thought_provoking: "Qui fait reflechir", epic: "Epique",
  emotional: "Emouvant", dark: "Sombre", scary: "Effrayant", feelgood: "Feel-good",
  funny: "Drole", relaxing: "Reposant",
};

const QUALITY_LABELS = {
  top_rated: "Une valeur sure, tres bien notee",
  any: "Peu importe la note",
};

const BREAKDOWN_LABELS = {
  genre: "Genres", mood: "Ambiance", director: "Realisateur",
  actor: "Acteurs", quality: "Qualite", learned: "Appris de vos votes",
};

const GENRE_VISUALS = {
  action: { gradient: "linear-gradient(135deg, #ff5f6d, #ffab5c)", emoji: "💥" },
  sci_fi: { gradient: "linear-gradient(135deg, #4e54c8, #8f94fb)", emoji: "🚀" },
  drama: { gradient: "linear-gradient(135deg, #485563, #29323c)", emoji: "🎭" },
  crime: { gradient: "linear-gradient(135deg, #232526, #4b4b52)", emoji: "🔫" },
  thriller: { gradient: "linear-gradient(135deg, #0f2027, #2c5364)", emoji: "🔪" },
  horror: { gradient: "linear-gradient(135deg, #350000, #6f0000)", emoji: "👻" },
  comedy: { gradient: "linear-gradient(135deg, #f7971e, #ffd200)", emoji: "😂" },
  romance: { gradient: "linear-gradient(135deg, #e0648b, #f3a6c1)", emoji: "💕" },
  animation: { gradient: "linear-gradient(135deg, #11998e, #38ef7d)", emoji: "🎨" },
  fantasy: { gradient: "linear-gradient(135deg, #654ea3, #c67fd6)", emoji: "🧙" },
  family: { gradient: "linear-gradient(135deg, #56ab2f, #a8e063)", emoji: "👨‍👩‍👧" },
  mystery: { gradient: "linear-gradient(135deg, #16222a, #3a6073)", emoji: "🔍" },
};
const DEFAULT_VISUAL = { gradient: "linear-gradient(135deg, #3a3f58, #23263a)", emoji: "🎬" };

function label(map, key) {
  return map[key] || key;
}

function posterFor(genres) {
  const key = genres && genres[0];
  return GENRE_VISUALS[key] || DEFAULT_VISUAL;
}

function getSessionId() {
  const KEY = "cinelogic_session_id";
  let id = localStorage.getItem(KEY);
  if (!id) {
    id = (crypto.randomUUID ? crypto.randomUUID() : `s-${Date.now()}-${Math.random().toString(16).slice(2)}`);
    localStorage.setItem(KEY, id);
  }
  return id;
}

const SESSION_ID = getSessionId();

const state = {
  mode: "criteria",
  genres: [],
  moods: [],
  movies: [],
  selectedGenres: new Set(),
  selectedAvoidGenres: new Set(),
  selectedMoods: new Set(),
  likedMovies: new Set(),
  votes: {},
  dialogue: { question: null, step: 0, total: 0, remaining: 0, done: false },
  group: { people: [] },
};

let personIdCounter = 0;

async function fetchJSON(url, options) {
  const res = await fetch(url, options);
  if (!res.ok) throw new Error(`Requete echouee (${res.status})`);
  return res.json();
}

function postJSON(url, body) {
  return fetchJSON(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

function toast(message) {
  const stack = document.getElementById("toast-stack");
  const el = document.createElement("div");
  el.className = "toast";
  el.textContent = message;
  stack.appendChild(el);
  setTimeout(() => el.remove(), 3000);
}

function announceLearned(learned) {
  if (!learned) return;
  const parts = [];
  if (learned.genres && learned.genres.length) {
    parts.push(learned.genres.map((g) => label(GENRE_LABELS, g)).join(", "));
  }
  if (learned.moods && learned.moods.length) {
    parts.push(learned.moods.map((m) => label(MOOD_LABELS, m)).join(", "));
  }
  if (parts.length) toast(`Le moteur a appris que vous aimez : ${parts.join(" / ")}`);
}

function scoreToPercent(score, maxScore) {
  if (maxScore <= 0) return 0;
  return Math.min(100, Math.round((score / maxScore) * 100));
}

// ---------------------------------------------------------------------------
// Chips generiques
// ---------------------------------------------------------------------------

function renderSimpleChips(container, values, labelMap, selectedSet) {
  container.innerHTML = "";
  values.forEach((value) => {
    const chip = document.createElement("button");
    chip.type = "button";
    chip.className = "chip" + (selectedSet.has(value) ? " active" : "");
    chip.textContent = label(labelMap, value);
    chip.addEventListener("click", () => {
      if (selectedSet.has(value)) selectedSet.delete(value);
      else selectedSet.add(value);
      renderSimpleChips(container, values, labelMap, selectedSet);
    });
    container.appendChild(chip);
  });
}

function setupGenreAvoidChips(genreContainer, avoidContainer, values, labelMap, genreSet, avoidSet) {
  function renderSide(container, selfSet, otherSet) {
    container.innerHTML = "";
    values.forEach((value) => {
      const chip = document.createElement("button");
      chip.type = "button";
      chip.className = "chip" + (selfSet.has(value) ? " active" : "");
      chip.textContent = label(labelMap, value);
      chip.addEventListener("click", () => {
        if (selfSet.has(value)) selfSet.delete(value);
        else { selfSet.add(value); otherSet.delete(value); }
        render();
      });
      container.appendChild(chip);
    });
  }
  function render() {
    renderSide(genreContainer, genreSet, avoidSet);
    renderSide(avoidContainer, avoidSet, genreSet);
  }
  render();
}

// ---------------------------------------------------------------------------
// Selecteur de films aimes (panneau "Par criteres")
// ---------------------------------------------------------------------------

function renderMoviePicker(filterText = "") {
  const container = document.getElementById("movie-picker");
  container.innerHTML = "";
  const filtered = state.movies.filter((m) => m.title.toLowerCase().includes(filterText.toLowerCase()));

  if (filtered.length === 0) {
    container.innerHTML = `<div class="movie-row"><span class="title">Aucun resultat</span></div>`;
    return;
  }

  filtered.forEach((movie) => {
    const row = document.createElement("div");
    row.className = "movie-row" + (state.likedMovies.has(movie.id) ? " liked" : "");
    row.innerHTML = `
      <span><span class="title">${movie.title}</span><span class="year">${movie.year}</span></span>
      <span class="heart">${state.likedMovies.has(movie.id) ? "♥" : "♡"}</span>
    `;
    row.addEventListener("click", () => {
      if (state.likedMovies.has(movie.id)) state.likedMovies.delete(movie.id);
      else state.likedMovies.add(movie.id);
      renderMoviePicker(document.getElementById("movie-search").value);
      renderLikedSummary();
    });
    container.appendChild(row);
  });
}

function renderLikedSummary() {
  const el = document.getElementById("liked-summary");
  if (state.likedMovies.size === 0) {
    el.textContent = "Aucun film selectionne pour le moment.";
    return;
  }
  const titles = state.movies.filter((m) => state.likedMovies.has(m.id)).map((m) => m.title);
  el.textContent = `${titles.length} film(s) aime(s) : ${titles.join(", ")}`;
}

// ---------------------------------------------------------------------------
// Cartes de resultats (mode "criteres" et "dialogue")
// ---------------------------------------------------------------------------

function buildResultCard(r, index, maxScore) {
  const card = document.createElement("div");
  card.className = "card";

  const genreTags = r.genres.map((g) => `<span class="genre-tag">${label(GENRE_LABELS, g)}</span>`).join("");
  const vote = state.votes[r.id];

  const breakdownRows = Object.entries(r.breakdown || {})
    .filter(([, v]) => v > 0)
    .map(([k, v]) => `
      <div class="breakdown-row">
        <span>${BREAKDOWN_LABELS[k] || k}</span>
        <span class="bar-track"><span class="bar-fill" style="width:${Math.min(100, v * 10)}%"></span></span>
        <span>+${v}</span>
      </div>
    `).join("");
  const reasonsHtml = (r.reasons || []).map((reason) => `<li>${reason}</li>`).join("");
  const visual = posterFor(r.genres);

  card.innerHTML = `
    <div class="card-poster" style="background:${visual.gradient}">
      <span class="rank">#${index + 1} · score ${r.score}</span>
      <span>${visual.emoji}</span>
    </div>
    <div class="card-body">
      <h3>${r.title} <span class="year">(${r.year})</span></h3>
      <div class="meta">Note : ${r.rating} / 10</div>
      <div class="score-bar-track"><div class="score-bar-fill" style="width:${scoreToPercent(r.score, maxScore)}%"></div></div>
      <p class="desc">${r.description || ""}</p>
      <div class="genre-tags">${genreTags}</div>
      <div class="card-actions">
        <button class="vote-btn${vote === 1 ? " voted-up" : ""}" data-vote="1" ${vote ? "disabled" : ""}>👍</button>
        <button class="vote-btn${vote === -1 ? " voted-down" : ""}" data-vote="-1" ${vote ? "disabled" : ""}>👎</button>
        <button class="why-btn">Pourquoi ce film ?</button>
      </div>
      <div class="breakdown">
        ${breakdownRows}
        ${reasonsHtml ? `<ul class="reasons">${reasonsHtml}</ul>` : ""}
      </div>
    </div>
  `;

  card.querySelector(".why-btn").addEventListener("click", () => {
    card.querySelector(".breakdown").classList.toggle("open");
  });

  card.querySelectorAll(".vote-btn").forEach((btn) => {
    btn.addEventListener("click", async () => {
      const voteValue = parseInt(btn.dataset.vote, 10);
      card.querySelectorAll(".vote-btn").forEach((b) => (b.disabled = true));
      btn.classList.add(voteValue === 1 ? "voted-up" : "voted-down");
      state.votes[r.id] = voteValue;
      try {
        const data = await postJSON("/api/feedback", { session_id: SESSION_ID, movie_id: r.id, vote: voteValue });
        announceLearned(data.learned);
      } catch (err) {
        toast(`Erreur lors de l'envoi du vote : ${err.message}`);
      }
    });
  });

  return card;
}

function renderResults(results) {
  const grid = document.getElementById("results");
  const hint = document.getElementById("results-hint");
  grid.innerHTML = "";

  if (!results || results.length === 0) {
    hint.textContent = "Aucune recommandation trouvee. Essayez d'ajouter plus de genres, d'ambiances ou de films aimes.";
    grid.innerHTML = `<div class="empty-state">Aucun film ne correspond a vos criteres pour le moment.</div>`;
    return;
  }

  hint.textContent = `${results.length} film(s) recommande(s), du meilleur score au moins bon.`;
  const maxScore = Math.max(...results.map((r) => r.score));
  results.forEach((r, index) => grid.appendChild(buildResultCard(r, index, maxScore)));
}

function renderGroupResults(results) {
  const grid = document.getElementById("results");
  const hint = document.getElementById("results-hint");
  grid.innerHTML = "";

  if (!results || results.length === 0) {
    hint.textContent = "Aucun film ne convient a tout le groupe. Essayez d'assouplir les genres a eviter.";
    grid.innerHTML = `<div class="empty-state">Aucun film ne convient a tout le groupe avec ces criteres.</div>`;
    return;
  }

  hint.textContent = `${results.length} film(s) qui conviennent a tout le groupe, classes par equite (personne n'est sacrifie).`;
  const maxScore = Math.max(...results.flatMap((r) => r.per_person.map((p) => p.score)));

  results.forEach((r, index) => {
    const card = document.createElement("div");
    card.className = "card";
    const genreTags = r.genres.map((g) => `<span class="genre-tag">${label(GENRE_LABELS, g)}</span>`).join("");
    const personRows = r.per_person.map((p) => `
      <div class="per-person-row">
        <span>${p.name}</span>
        <span class="bar-track"><span class="bar-fill" style="width:${scoreToPercent(p.score, maxScore)}%"></span></span>
        <span>${p.score}</span>
      </div>
    `).join("");

    const visual = posterFor(r.genres);
    card.innerHTML = `
      <div class="card-poster" style="background:${visual.gradient}">
        <span class="rank"><span class="group-score-label">#${index + 1} · groupe ${r.group_score}</span></span>
        <span>${visual.emoji}</span>
      </div>
      <div class="card-body">
        <h3>${r.title} <span class="year">(${r.year})</span></h3>
        <div class="meta">Note : ${r.rating} / 10</div>
        <p class="desc">${r.description || ""}</p>
        <div class="genre-tags">${genreTags}</div>
        <div class="per-person">${personRows}</div>
      </div>
    `;
    grid.appendChild(card);
  });
}

// ---------------------------------------------------------------------------
// Mode "Par criteres"
// ---------------------------------------------------------------------------

async function handleRecommend() {
  const btn = document.getElementById("recommend-btn");
  btn.disabled = true;
  btn.textContent = "Recherche en cours...";

  const payload = {
    genres: Array.from(state.selectedGenres),
    moods: Array.from(state.selectedMoods),
    liked_movies: Array.from(state.likedMovies),
    avoid_genres: Array.from(state.selectedAvoidGenres),
    session_id: SESSION_ID,
    top_n: 6,
  };

  try {
    const data = await postJSON("/api/recommend", payload);
    renderResults(data.results);
    announceLearned(data.learned);
  } catch (err) {
    document.getElementById("results").innerHTML = `<div class="error-state">Erreur lors de l'appel au moteur : ${err.message}</div>`;
  } finally {
    btn.disabled = false;
    btn.textContent = "Obtenir mes recommandations";
  }
}

// ---------------------------------------------------------------------------
// Mode "Dialogue guide"
// ---------------------------------------------------------------------------

async function startDialogue() {
  state.dialogue = { question: null, step: 0, total: 0, remaining: 0, done: false };
  try {
    const data = await postJSON("/api/dialogue/start", { session_id: SESSION_ID });
    applyDialogueReply(data);
  } catch (err) {
    document.getElementById("dialogue-question").innerHTML = `<div class="error-state">Erreur : ${err.message}</div>`;
  }
}

async function answerDialogue(questionId, value) {
  try {
    const data = await postJSON("/api/dialogue/answer", { session_id: SESSION_ID, question_id: questionId, value });
    applyDialogueReply(data);
  } catch (err) {
    document.getElementById("dialogue-question").innerHTML = `<div class="error-state">Erreur : ${err.message}</div>`;
  }
}

function applyDialogueReply(data) {
  if (data.done) {
    state.dialogue.done = true;
    state.dialogue.remaining = data.remaining;
    renderDialogueDone(data);
    renderResults(data.results);
  } else {
    state.dialogue.question = data.question;
    state.dialogue.step = data.step;
    state.dialogue.total = data.total;
    state.dialogue.remaining = data.remaining;
    renderDialogueQuestion();
  }
}

function renderDialogueQuestion() {
  const q = state.dialogue.question;
  const progress = document.getElementById("dialogue-progress");
  const pct = Math.round(((state.dialogue.step - 1) / state.dialogue.total) * 100);
  progress.innerHTML = `
    <div>Question ${state.dialogue.step} / ${state.dialogue.total} — ${state.dialogue.remaining} film(s) correspondent encore</div>
    <div class="bar-track"><div class="bar-fill" style="width:${pct}%"></div></div>
  `;

  const container = document.getElementById("dialogue-question");
  container.innerHTML = `<h3>${q.text}</h3>`;

  if (q.type === "quality") {
    const wrap = document.createElement("div");
    wrap.className = "dialogue-options";
    [["top_rated", QUALITY_LABELS.top_rated], ["any", QUALITY_LABELS.any]].forEach(([value, text]) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "chip";
      btn.textContent = text;
      btn.addEventListener("click", () => answerDialogue(q.id, value));
      wrap.appendChild(btn);
    });
    container.appendChild(wrap);
  } else if (q.type === "liked_movie") {
    const searchInput = document.createElement("input");
    searchInput.type = "text";
    searchInput.placeholder = "Rechercher un film...";
    const list = document.createElement("div");
    list.className = "movie-picker";
    container.appendChild(searchInput);
    container.appendChild(list);

    const renderList = (filterText = "") => {
      list.innerHTML = "";
      const filtered = state.movies.filter((m) => m.title.toLowerCase().includes(filterText.toLowerCase())).slice(0, 30);
      filtered.forEach((m) => {
        const row = document.createElement("div");
        row.className = "movie-row";
        row.innerHTML = `<span><span class="title">${m.title}</span><span class="year">${m.year}</span></span>`;
        row.addEventListener("click", () => answerDialogue(q.id, m.id));
        list.appendChild(row);
      });
    };
    searchInput.addEventListener("input", (e) => renderList(e.target.value));
    renderList();
  } else {
    const labelMap = q.type === "mood" ? MOOD_LABELS : GENRE_LABELS;
    const wrap = document.createElement("div");
    wrap.className = "dialogue-options";
    q.options.forEach((value) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "chip";
      btn.textContent = label(labelMap, value);
      btn.addEventListener("click", () => answerDialogue(q.id, value));
      wrap.appendChild(btn);
    });
    container.appendChild(wrap);
  }

  document.getElementById("dialogue-skip").hidden = false;
}

function renderDialogueDone(data) {
  document.getElementById("dialogue-progress").innerHTML = `<div>Termine — ${data.remaining} film(s) au total correspondaient a vos reponses</div>`;
  document.getElementById("dialogue-question").innerHTML =
    `<p class="dialogue-done">Vos recommandations sont affichees a droite. Cliquez sur "Recommencer" pour relancer un dialogue.</p>`;
  document.getElementById("dialogue-skip").hidden = true;
}

// ---------------------------------------------------------------------------
// Mode "Soiree entre amis"
// ---------------------------------------------------------------------------

function addPerson() {
  const id = ++personIdCounter;
  state.group.people.push({
    id,
    name: `Personne ${state.group.people.length + 1}`,
    genres: new Set(),
    moods: new Set(),
    avoid: new Set(),
  });
  renderGroupPeople();
}

function removePerson(id) {
  state.group.people = state.group.people.filter((p) => p.id !== id);
  renderGroupPeople();
}

function renderGroupPeople() {
  const container = document.getElementById("group-people");
  container.innerHTML = "";

  state.group.people.forEach((person) => {
    const card = document.createElement("div");
    card.className = "person-card";

    const header = document.createElement("div");
    header.className = "person-card-header";
    const nameInput = document.createElement("input");
    nameInput.type = "text";
    nameInput.className = "person-name-input";
    nameInput.value = person.name;
    nameInput.addEventListener("input", (e) => { person.name = e.target.value; });
    header.appendChild(nameInput);

    if (state.group.people.length > 1) {
      const removeBtn = document.createElement("button");
      removeBtn.type = "button";
      removeBtn.className = "remove-person";
      removeBtn.textContent = "✕";
      removeBtn.addEventListener("click", () => removePerson(person.id));
      header.appendChild(removeBtn);
    }
    card.appendChild(header);

    const genreField = document.createElement("div");
    genreField.className = "person-field";
    genreField.innerHTML = `<p class="person-field-label">Genres aimes</p>`;
    const genreChips = document.createElement("div");
    genreChips.className = "chips";
    genreField.appendChild(genreChips);
    card.appendChild(genreField);

    const avoidField = document.createElement("div");
    avoidField.className = "person-field";
    avoidField.innerHTML = `<p class="person-field-label">A eviter</p>`;
    const avoidChips = document.createElement("div");
    avoidChips.className = "chips chips-avoid";
    avoidField.appendChild(avoidChips);
    card.appendChild(avoidField);

    setupGenreAvoidChips(genreChips, avoidChips, state.genres, GENRE_LABELS, person.genres, person.avoid);

    const moodField = document.createElement("div");
    moodField.className = "person-field";
    moodField.innerHTML = `<p class="person-field-label">Ambiance</p>`;
    const moodChips = document.createElement("div");
    moodChips.className = "chips chips-mood";
    moodField.appendChild(moodChips);
    card.appendChild(moodField);
    renderSimpleChips(moodChips, state.moods, MOOD_LABELS, person.moods);

    container.appendChild(card);
  });

  document.getElementById("group-add-person").disabled = state.group.people.length >= 6;
}

async function handleGroupRecommend() {
  const btn = document.getElementById("group-recommend-btn");
  btn.disabled = true;
  btn.textContent = "Recherche en cours...";

  const profiles = state.group.people.map((p) => ({
    name: p.name,
    genres: Array.from(p.genres),
    moods: Array.from(p.moods),
    avoid_genres: Array.from(p.avoid),
    liked_movies: [],
  }));

  try {
    const data = await postJSON("/api/group/recommend", { profiles, top_n: 6 });
    renderGroupResults(data.results);
  } catch (err) {
    document.getElementById("results").innerHTML = `<div class="error-state">Erreur lors de l'appel au moteur : ${err.message}</div>`;
  } finally {
    btn.disabled = false;
    btn.textContent = "Trouver un film pour le groupe";
  }
}

// ---------------------------------------------------------------------------
// Navigation entre modes
// ---------------------------------------------------------------------------

function setMode(mode) {
  state.mode = mode;
  document.querySelectorAll(".mode-tab").forEach((btn) => btn.classList.toggle("active", btn.dataset.mode === mode));
  document.querySelectorAll("[data-mode-panel]").forEach((panel) => {
    panel.hidden = panel.dataset.modePanel !== mode;
  });

  document.getElementById("results").innerHTML = "";
  const hint = document.getElementById("results-hint");
  if (mode === "criteria") {
    hint.textContent = "Choisissez vos preferences puis cliquez sur le bouton pour voir vos recommandations.";
  } else if (mode === "dialogue") {
    hint.textContent = "Repondez aux questions a gauche : les recommandations apparaitront ici une fois le dialogue termine.";
    if (!state.dialogue.question && !state.dialogue.done) startDialogue();
  } else if (mode === "group") {
    hint.textContent = "Ajoutez les gouts de chaque personne puis cliquez sur le bouton pour trouver un film qui plait a tout le monde.";
  }
}

// ---------------------------------------------------------------------------
// Initialisation
// ---------------------------------------------------------------------------

async function init() {
  const [genresData, moodsData, moviesData] = await Promise.all([
    fetchJSON("/api/genres"),
    fetchJSON("/api/moods"),
    fetchJSON("/api/movies"),
  ]);

  state.genres = genresData.genres;
  state.moods = moodsData.moods;
  state.movies = moviesData.movies;

  setupGenreAvoidChips(
    document.getElementById("genre-chips"), document.getElementById("avoid-chips"),
    state.genres, GENRE_LABELS, state.selectedGenres, state.selectedAvoidGenres
  );
  renderSimpleChips(document.getElementById("mood-chips"), state.moods, MOOD_LABELS, state.selectedMoods);

  renderMoviePicker();
  renderLikedSummary();
  document.getElementById("movie-search").addEventListener("input", (e) => renderMoviePicker(e.target.value));
  document.getElementById("recommend-btn").addEventListener("click", handleRecommend);

  document.getElementById("dialogue-skip").addEventListener("click", () => {
    if (state.dialogue.question) answerDialogue(state.dialogue.question.id, "skip");
  });
  document.getElementById("dialogue-restart").addEventListener("click", async () => {
    await postJSON("/api/dialogue/reset", { session_id: SESSION_ID });
    document.getElementById("results").innerHTML = "";
    startDialogue();
  });

  document.getElementById("group-add-person").addEventListener("click", () => addPerson());
  document.getElementById("group-recommend-btn").addEventListener("click", handleGroupRecommend);
  addPerson();
  addPerson();

  document.querySelectorAll(".mode-tab").forEach((btn) => btn.addEventListener("click", () => setMode(btn.dataset.mode)));
}

init().catch((err) => {
  document.getElementById("results").innerHTML = `<div class="error-state">Impossible de charger l'application : ${err.message}</div>`;
});
