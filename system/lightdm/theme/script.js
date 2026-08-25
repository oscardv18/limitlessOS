// system/lightdm/theme/script.js — tema de lightdm-webkit2-greeter.
//
// API verificada contra el manual de Arch (lightdm-webkit2-greeter.1),
// no de memoria: los tres callbacks que exige el greeter en `window`
// (show_prompt, show_message, authentication_complete) y los métodos
// exactos de `lightdm` (authenticate, respond, start_session_sync,
// cancel_authentication). Ningún nombre de aquí es una suposición.

(function () {
  'use strict';
  const $ = (s) => document.querySelector(s);
  const field = createField($('#field'));

  // ---------------------------------------------------------------- reloj
  function tick() {
    const n = new Date();
    $('.time').textContent =
      String(n.getHours()).padStart(2, '0') + ':' + String(n.getMinutes()).padStart(2, '0');
    $('.date').textContent = n
      .toLocaleDateString('es', { weekday: 'long', day: 'numeric', month: 'long' })
      .toUpperCase();
  }
  tick();
  setInterval(tick, 1000);

  // -------------------------------------------------------- sesiones
  let selectedSession = null;
  function paintSessions() {
    const box = $('#sessions');
    box.innerHTML = '';
    const list = (window.lightdm && lightdm.sessions) || [];
    if (!selectedSession) {
      selectedSession =
        (window.lightdm && lightdm.default_session) ||
        (list[0] && (list[0].key || list[0].id)) ||
        null;
    }
    list.forEach((s) => {
      const key = s.key || s.id || s.name;
      const label = s.name || s.comment || key;
      const chip = document.createElement('span');
      chip.className = 'sess-chip' + (key === selectedSession ? ' on' : '');
      chip.textContent = label;
      chip.onclick = () => {
        selectedSession = key;
        paintSessions();
      };
      box.appendChild(chip);
    });
  }

  // -------------------------------------------------------- autenticación
  const input = $('#prompt-input');
  const row = $('#prompt-row');
  const label = $('#prompt-label');
  const msg = $('#msg');

  function setMsg(text, kind) {
    msg.textContent = text || '';
    msg.className = kind || '';
  }

  function askUsername() {
    // sin argumento: LightDM pide el usuario vía show_prompt()
    if (window.lightdm) lightdm.authenticate();
  }

  // --- callbacks que lightdm-webkit2-greeter invoca en `window` ---------
  window.show_prompt = function (text, type) {
    label.textContent = text;
    input.type = type === 'password' ? 'password' : 'text';
    input.value = '';
    row.classList.add('on');
    input.focus();
  };

  window.show_message = function (text, type) {
    setMsg(text, type === 'error' ? 'err' : 'ok');
  };

  window.authentication_complete = function () {
    row.classList.remove('on');
    if (window.lightdm && lightdm.is_authenticated) {
      setMsg('✓ autenticado', 'ok');
      lightdm.start_session_sync(selectedSession);
    } else {
      setMsg('✗ autenticación fallida', 'err');
      input.value = '';
      setTimeout(askUsername, 300);
    }
  };

  input.addEventListener('keydown', (e) => {
    if (e.key !== 'Enter') return;
    const text = input.value;
    input.value = '';
    if (window.lightdm) lightdm.respond(text);
  });

  // -------------------------------------------------------- energía
  function bindPower(id, canFlag, action) {
    const el = $(id);
    if (!window.lightdm || !lightdm[canFlag]) {
      el.style.display = 'none';
      return;
    }
    el.onclick = () => lightdm[action]();
  }

  // -------------------------------------------------------- arranque
  function init() {
    $('.host').textContent = (window.lightdm && lightdm.hostname) || '';
    paintSessions();
    bindPower('#pw-suspend', 'can_suspend', 'suspend');
    bindPower('#pw-restart', 'can_restart', 'restart');
    bindPower('#pw-shutdown', 'can_shutdown', 'shutdown');
    askUsername();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
