(() => {
  "use strict";

  // ---- i18n basics ----
  const I18N_FILES = {
    "zh-Hant": "/assets/i18n/zh-Hant.json",
    "en": "/assets/i18n/en.json"
  };
  const ls = window.localStorage;
  const langSel = () => document.getElementById("lang");
  let dict = {};
  function pickDefaultLang() {
    const saved = ls.getItem("lang");
    if (saved && I18N_FILES[saved]) return saved;
    const nav = (navigator.language || "zh-Hant").toLowerCase();
    if (nav.startsWith("zh")) return "zh-Hant";
    return "en";
  }
  async function loadLang(lang) {
    const url = I18N_FILES[lang] || I18N_FILES["zh-Hant"];
    const res = await fetch(url, {cache:"no-store"});
    dict = await res.json();
    document.documentElement.lang = lang;
    // apply to [data-i18n]
    document.querySelectorAll("[data-i18n]").forEach(el => {
      const k = el.getAttribute("data-i18n");
      if (dict[k]) el.textContent = dict[k];
    });
  }
  function t(k){ return dict[k] || k; }

  // ---- UI refs ----
  const runBtn = document.getElementById('runBtn');
  const autoChk = document.getElementById('autoscroll');
  const startEl = document.getElementById('start');
  const statusEl = document.getElementById('status');
  const bar = document.getElementById('bar');
  const cards = document.getElementById('cards');
  const fullLog = document.getElementById('fullLog');

  const steps = ["System","CPU / Memory","Disk","Network Info"];
  const stepPct = { "System":25, "CPU / Memory":50, "Disk":75, "Network Info":100 };

  let sectionMap = {};
  let currentSection = null;
  let es = null;

  function resetUI() {
    startEl.textContent = new Date().toLocaleString();
    statusEl.textContent = t("status.standby");
    bar.classList.remove('indet'); bar.style.width = '0%';
    cards.innerHTML = ""; fullLog.textContent = "";
    sectionMap = {}; currentSection = null;
  }

  function ensureSection(name){
    if (sectionMap[name]) return sectionMap[name];
    const card = document.createElement('div'); card.className = 'card';
    const h2 = document.createElement('h2'); h2.textContent = name; // server decides section label
    const sec = document.createElement('div'); sec.className = 'section';
    const table = document.createElement('div'); table.className = 'kv';
    const bullets = document.createElement('ul'); bullets.className = 'bullets';
    const mono = document.createElement('div'); mono.className = 'mono';
    sec.appendChild(table); sec.appendChild(bullets); sec.appendChild(mono);
    card.appendChild(h2); card.appendChild(sec);
    if (steps.includes(name)) {
      const idx = steps.indexOf(name);
      let anchor = null;
      for (const el of Array.from(cards.children)) {
        const t2 = el.querySelector('h2')?.textContent || "";
        const pos = steps.indexOf(t2);
        if (pos !== -1 && pos > idx) { anchor = el; break; }
      }
      cards.insertBefore(card, anchor);
    } else {
      cards.appendChild(card);
    }
    return (sectionMap[name] = { card, kv: table, bullets, mono });
  }

  function addKV(section, key, value){
    const {kv} = ensureSection(section);
    const dk = document.createElement('div'); dk.className = 'key'; dk.textContent = key;
    const dv = document.createElement('div'); dv.className = 'val'; dv.textContent = value;
    kv.appendChild(dk); kv.appendChild(dv);
  }
  function addBullet(section, text){
    const {bullets} = ensureSection(section);
    const li = document.createElement('li'); li.textContent = text.replace(/^•\s*/, '');
    bullets.appendChild(li);
  }
  function addBodyLine(section, text){
    const {mono} = ensureSection(section);
    mono.append(document.createTextNode(text + "\n"));
  }
  function scrollBottom(){
    if (!autoChk.checked) return;
    window.scrollTo({ top: document.body.scrollHeight, behavior: 'instant' });
  }
  function setProgressByStep(name){
    const pct = stepPct[name];
    if (pct) { bar.classList.remove('indet'); bar.style.width = pct + '%'; }
  }
  function isSeparator(line){
    return /^[\s\u2500-\u257F\-─—]{5,}$/.test(line.trim());
  }

  function processLine(line){
    fullLog.append(document.createTextNode(line + "\n"));
    const mTitle = line.match(/^■\s+(.*)$/);
    if (mTitle) {
      currentSection = mTitle[1].trim();
      ensureSection(currentSection);
      statusEl.textContent = t("status.exec") + currentSection;
      setProgressByStep(currentSection);
      scrollBottom(); return;
    }
    if (!currentSection || isSeparator(line)) return;
    const mKV = line.match(/^\s*([^\s].*?[^\s])\s{2,}(.+)\s*$/);
    if (mKV) { addKV(currentSection, mKV[1], mKV[2]); scrollBottom(); return; }
    if (line.startsWith('• ')) { addBullet(currentSection, line); scrollBottom(); return; }
    if (line.trim().length) { addBodyLine(currentSection, line); scrollBottom(); }
  }

  function runOnce() {
    if (es) { try{ es.close(); }catch(e){} es = null; }
    resetUI(); statusEl.textContent = "…";
    bar.classList.add('indet');
    es = new EventSource(`/cgi-bin/bench.sse.py?ts=${Date.now()}`);
    es.onmessage = (ev) => processLine(ev.data);
    es.addEventListener('done', () => {
      statusEl.textContent = t('status.done');
      bar.classList.remove('indet');
      bar.style.width = '100%';
      bar.style.background = 'linear-gradient(90deg,#22c55e,#34d399)';
      scrollBottom(); es.close(); es = null;
    });
    es.addEventListener('error', () => {
      statusEl.textContent = t('status.error');
      bar.classList.remove('indet'); es && es.close(); es = null;
    });
  }

  async function boot() {
    const defaultLang = pickDefaultLang();
    const sel = langSel();
    sel.value = defaultLang;
    await loadLang(defaultLang);
    // change handlers
    sel.addEventListener("change", async () => {
      const lang = sel.value;
      ls.setItem("lang", lang);
      await loadLang(lang);
    });
    // button
    document.getElementById('runBtn').addEventListener('click', (e)=>{ e.preventDefault(); runOnce(); });
  }

  boot();
})();