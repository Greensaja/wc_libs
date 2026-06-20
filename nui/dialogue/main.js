'use strict';

// ── Resource name helper ─────────────────────────────────
if (typeof GetParentResourceName === 'undefined') {
  window.GetParentResourceName = function () {
    return (window.parent && typeof window.parent.GetParentResourceName === 'function')
      ? window.parent.GetParentResourceName()
      : 'wc_libs';
  };
}

function resourceName() { return GetParentResourceName(); }

function nuiFetch(endpoint, body) {
  return fetch(`https://${resourceName()}/${endpoint}`, {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify(body || {}),
  });
}

// ── State ────────────────────────────────────────────────
let dialogueActive = false;
let acceptActive   = false;
let currentOptions = [];
let trustValue     = 50;

// ── DOM refs ─────────────────────────────────────────────
const $ = id => document.getElementById(id);
const enc = {
  root:        $('encounter-root'),
  headerTitle: $('enc-header-title'),
  timer:       $('enc-timer'),
  npcInitial:  $('enc-npc-initial'),
  npcName:     $('enc-npc-name'),
  npcMood:     $('enc-npc-mood'),
  speechText:  $('enc-speech-text'),
  trustLabel:  $('enc-trust-label'),
  trustVal:    $('enc-trust-val'),
  trustFill:   $('enc-trust-fill'),
  options:     $('enc-options'),
};

const acc = {
  root:       $('accept-root'),
  headerTitle:$('acc-header-title'),
  npcInitial: $('acc-npc-initial'),
  npcName:    $('acc-npc-name'),
  speechText: $('acc-speech-text'),
  btnAccept:  $('acc-btn-accept'),
  btnDecline: $('acc-btn-decline'),
};

const tip = {
  root:  $('wctip-root'),
  toast: $('wctip-toast'),
  text:  $('wctip-text'),
};

let tipTimer = null;

// ── Typewriter ───────────────────────────────────────────
let typewriterTimer = null;

function typewrite(el, text, onDone) {
  if (typewriterTimer) clearTimeout(typewriterTimer);
  el.classList.add('typing');
  el.textContent = '';
  let i = 0;
  const speed = Math.max(18, Math.min(38, Math.floor(900 / Math.max(text.length, 1))));

  function next() {
    if (i < text.length) {
      el.textContent += text[i++];
      typewriterTimer = setTimeout(next, speed);
    } else {
      el.classList.remove('typing');
      if (onDone) onDone();
    }
  }
  next();
}

// ── Trust bar ────────────────────────────────────────────
function setTrust(val) {
  trustValue = Math.max(0, Math.min(100, val));
  enc.trustFill.style.width = trustValue + '%';
  enc.trustVal.textContent  = trustValue;
  enc.trustFill.classList.remove('low', 'mid', 'high');
  if (trustValue < 35)      enc.trustFill.classList.add('low');
  else if (trustValue < 65) enc.trustFill.classList.add('mid');
  else                      enc.trustFill.classList.add('high');
}

// ── Mood ─────────────────────────────────────────────────
function setMood(mood) {
  enc.npcMood.className = 'enc-npc-mood mood-' + (mood || 'neutral');
  enc.npcMood.textContent = capitalise(mood || 'Neutral');
}

function capitalise(s) {
  return s ? s.charAt(0).toUpperCase() + s.slice(1).replace(/_/g, ' ') : '';
}

// ── Timer display ────────────────────────────────────────
function startTimerDisplay(initial) {
  enc.timer.textContent = initial;
  enc.timer.classList.remove('warning');
}

function updateTimer(val) {
  enc.timer.textContent = val;
  enc.timer.classList.toggle('warning', val <= 10);
}

// ── Options ──────────────────────────────────────────────
function renderOptions(options) {
  enc.options.innerHTML = '';
  currentOptions = options || [];
  currentOptions.forEach((opt, i) => {
    const btn = document.createElement('button');
    btn.className = 'enc-option-btn';
    btn.innerHTML = `<span class="enc-option-num">${String.fromCharCode(65 + i)}.</span>${opt.text}`;
    btn.addEventListener('click', () => selectOption(opt.index ?? i));
    enc.options.appendChild(btn);
  });
}

function disableAllOptions() {
  enc.options.querySelectorAll('.enc-option-btn').forEach(b => { b.disabled = true; });
}

function selectOption(index) {
  if (!dialogueActive) return;
  disableAllOptions();
  nuiFetch('wcdialogue:selectOption', { optionIndex: index });
}

// ── Avatar initial ───────────────────────────────────────
function setAvatar(name, el) {
  el.textContent = (name || '?').charAt(0).toUpperCase();
}

// ─────────────────────────────────────────────────────────
// OPEN MAIN DIALOGUE
// ─────────────────────────────────────────────────────────
function openDialogue(data) {
  dialogueActive = true;

  setTrust(data.trust ?? 50);
  enc.headerTitle.textContent = (data.header || 'Conversation').toUpperCase();
  setAvatar(data.npcName, enc.npcInitial);
  enc.npcName.textContent    = data.npcName    || 'Stranger';
  enc.trustLabel.textContent = data.trustLabel || 'Trust';
  setMood(data.mood || 'neutral');
  startTimerDisplay(data.timeLeft ?? 60);

  acc.root.classList.add('hidden');
  enc.root.classList.remove('hidden');

  typewrite(enc.speechText, data.intro || '', () => {
    renderOptions(data.options || []);
  });
}

// ─────────────────────────────────────────────────────────
// UPDATE DIALOGUE
// ─────────────────────────────────────────────────────────
function updateDialogue(data) {
  if (data.trust !== undefined) setTrust(data.trust);
  if (data.mood)  setMood(data.mood);

  typewrite(enc.speechText, data.response || '', () => {
    if (data.nextOptions && data.nextOptions.length > 0) {
      renderOptions(data.nextOptions);
    } else {
      enc.options.innerHTML = '';
    }
  });
}

// ─────────────────────────────────────────────────────────
// CLOSE
// ─────────────────────────────────────────────────────────
function closeAll() {
  dialogueActive = false;
  acceptActive   = false;
  if (typewriterTimer) clearTimeout(typewriterTimer);
  enc.root.classList.add('hidden');
  acc.root.classList.add('hidden');
}

function showWcTip(data) {
  if (!tip.root || !tip.toast || !tip.text) return;

  if (tipTimer) clearTimeout(tipTimer);

  tip.text.textContent = data.text || '';
  tip.toast.classList.toggle('rtl', data.rtl === true);
  tip.root.className = 'wctip-root ' + (data.placement || 'lower-center');
  if (data.y) tip.root.style.top = data.y;
  else tip.root.style.top = '';

  tip.root.classList.remove('hidden');
  requestAnimationFrame(() => tip.root.classList.add('visible'));

  tipTimer = setTimeout(() => {
    tip.root.classList.remove('visible');
    setTimeout(() => tip.root.classList.add('hidden'), 180);
  }, data.duration || 3000);
}

// ─────────────────────────────────────────────────────────
// ACCEPT / DECLINE PANEL
// ─────────────────────────────────────────────────────────
function openAccept(data) {
  acceptActive = true;

  acc.btnAccept.disabled  = false;
  acc.btnDecline.disabled = false;

  acc.headerTitle.textContent = (data.header || 'Someone needs help!').toUpperCase();
  setAvatar(data.npcName, acc.npcInitial);
  acc.npcName.textContent    = data.npcName || 'Stranger';
  acc.btnAccept.textContent  = data.accept  || 'Help them.';
  acc.btnDecline.textContent = data.decline || 'Walk away.';

  enc.root.classList.add('hidden');
  acc.root.classList.remove('hidden');

  typewrite(acc.speechText, data.intro || '');

  acc.btnAccept.onclick = function () {
    if (!acceptActive) return;
    acc.btnAccept.disabled  = true;
    acc.btnDecline.disabled = true;
    nuiFetch('wcdialogue:acceptMission', { accepted: true });
    closeAll();
  };

  acc.btnDecline.onclick = function () {
    if (!acceptActive) return;
    acc.btnAccept.disabled  = true;
    acc.btnDecline.disabled = true;
    nuiFetch('wcdialogue:acceptMission', { accepted: false });
    closeAll();
  };
}

// ─────────────────────────────────────────────────────────
// Message listener
// ─────────────────────────────────────────────────────────
window.addEventListener('message', function (event) {
  const data = event.data;
  if (!data || !data.type) return;

  switch (data.type) {
    case 'wcdialogue:openDialogue':   openDialogue(data);           break;
    case 'wcdialogue:updateDialogue': updateDialogue(data);         break;
    case 'wcdialogue:timerUpdate':    updateTimer(data.timeLeft);   break;
    case 'wcdialogue:openAccept':     openAccept(data);             break;
    case 'wcdialogue:closeDialogue':  closeAll();                   break;
    case 'wctip:show':                showWcTip(data);              break;
    default: break;
  }
});
