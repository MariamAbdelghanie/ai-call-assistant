import json
import os
import uuid
from pathlib import Path
from aiohttp import web
from dotenv import load_dotenv
from livekit import api
from backend.access import is_authorized_request
from backend.config_store import JsonConfigStore
from backend.records import RecordNotFound, StorageError
from config_validation import validate_configuration
from services import CALL_LOG_REPOSITORY

load_dotenv()

CALL_LOGS_FILE = Path(__file__).parent / "call_logs.json"
CONFIG_FILE = Path(__file__).parent / "agent_config.json"

DEFAULT_CONFIG = {
    "preset": "natural_emel",
    "stt_model": "whisper-large-v3-turbo",
    "llm_model": "openai/gpt-oss-120b",
    "tts_voice": "edge-emel",
    "stt_language": "auto",
    "assistant_mode": "hybrid",
    "owner_language": "tr",
    "work_start": "09:00",
    "work_end": "17:00",
    "assistant_enabled": True,
    "greeting_text": "",
    "architecture": "cascade",
    "realtime_model": "",
    "realtime_voice": "Puck",
}

CONFIG_STORE = JsonConfigStore(CONFIG_FILE, DEFAULT_CONFIG)

HTML_PAGE = """<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI Çağrı Asistanı</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/livekit-client/dist/livekit-client.umd.min.js"></script>
<style>
:root{
  --bg:#f4f7fb; --surface:#ffffff; --surface-2:#f0f4f9; --border:#e2e8f0;
  --text:#0f172a; --muted:#64748b; --primary:#2e95d3; --primary-dark:#1e6fa3;
  --primary-soft:#e6f4fc; --danger:#e5484d; --danger-soft:#fdecec;
  --success:#2f9e6b; --success-soft:#e7f6ef; --warn:#d9822b; --warn-soft:#fdf1e4;
  --shadow:0 1px 2px rgba(15,23,42,.04),0 8px 24px rgba(15,23,42,.06);
}
@media (prefers-color-scheme: dark){
  :root{
    --bg:#0b1220; --surface:#121a2b; --surface-2:#18233a; --border:#24314a;
    --text:#e6edf7; --muted:#94a3b8; --primary:#4ba3d9; --primary-dark:#7cc0ea;
    --primary-soft:#14304a; --danger:#f2686c; --danger-soft:#3a1d22;
    --success:#4cc38a; --success-soft:#14352a; --warn:#f0a35c; --warn-soft:#3a2a18;
    --shadow:0 1px 2px rgba(0,0,0,.3),0 8px 24px rgba(0,0,0,.25);
  }
}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Inter,system-ui,-apple-system,"Segoe UI",sans-serif;background:var(--bg);color:var(--text);min-height:100vh}
button{font-family:inherit;cursor:pointer}
header{background:var(--surface);border-bottom:1px solid var(--border);position:sticky;top:0;z-index:10}
.bar{max-width:1080px;margin:0 auto;padding:14px 20px;display:flex;align-items:center;gap:16px}
.brand{display:flex;align-items:center;gap:10px;font-weight:700;font-size:16px}
.logo{width:34px;height:34px;border-radius:10px;background:var(--primary);display:grid;place-items:center}
.logo svg{width:18px;height:18px;fill:#fff}
nav{display:flex;gap:4px;margin-left:auto;background:var(--surface-2);padding:4px;border-radius:10px}
nav button{border:0;background:transparent;color:var(--muted);padding:8px 14px;border-radius:8px;font-size:14px;font-weight:600}
nav button.active{background:var(--surface);color:var(--text);box-shadow:var(--shadow)}
.icon-btn{border:1px solid var(--border);background:var(--surface);color:var(--text);width:38px;height:38px;border-radius:10px;display:grid;place-items:center}
.icon-btn svg{width:18px;height:18px;fill:currentColor}
main{max-width:1080px;margin:0 auto;padding:24px 20px 48px}
.view{display:none}.view.active{display:block}

/* Arama ekranı */
.call-grid{display:grid;grid-template-columns:380px 1fr;gap:20px}
@media (max-width:860px){.call-grid{grid-template-columns:1fr}}
.card{background:var(--surface);border:1px solid var(--border);border-radius:16px;box-shadow:var(--shadow)}
.phone{padding:28px 24px;display:flex;flex-direction:column;align-items:center;text-align:center}
.status{display:inline-flex;align-items:center;gap:8px;font-size:13px;font-weight:600;color:var(--muted);background:var(--surface-2);padding:6px 12px;border-radius:999px}
.dot{width:8px;height:8px;border-radius:50%;background:var(--muted)}
.status.live{color:var(--success);background:var(--success-soft)}
.status.live .dot{background:var(--success);animation:blink 1.4s infinite}
@keyframes blink{50%{opacity:.35}}
.orb{width:150px;height:150px;border-radius:50%;margin:30px 0 22px;position:relative;display:grid;place-items:center;
  background:radial-gradient(circle at 35% 30%,#8fd0f5,var(--primary) 60%,var(--primary-dark))}
.orb::before,.orb::after{content:"";position:absolute;inset:-10px;border-radius:50%;border:2px solid var(--primary);opacity:0}
.orb.talking::before{animation:ring 1.6s infinite}
.orb.talking::after{animation:ring 1.6s .8s infinite}
@keyframes ring{0%{transform:scale(.9);opacity:.6}100%{transform:scale(1.25);opacity:0}}
.orb svg{width:54px;height:54px;fill:#fff}
.headline{font-size:20px;font-weight:700}
.sub{color:var(--muted);font-size:14px;margin-top:6px;min-height:20px}
.chips{display:flex;gap:8px;justify-content:center;margin-top:14px;flex-wrap:wrap}
.chip{font-size:12px;font-weight:600;padding:5px 10px;border-radius:999px;background:var(--surface-2);color:var(--muted)}
.chip.lang{background:var(--primary-soft);color:var(--primary-dark)}
.timer{font-variant-numeric:tabular-nums;font-size:28px;font-weight:600;margin-top:20px}
.controls{display:flex;gap:14px;margin-top:22px;align-items:center}
.round{width:56px;height:56px;border-radius:50%;border:1px solid var(--border);background:var(--surface);color:var(--text);display:grid;place-items:center}
.round svg{width:22px;height:22px;fill:currentColor}
.round.muted{background:var(--warn-soft);color:var(--warn);border-color:transparent}
.btn-call{border:0;height:56px;padding:0 28px;border-radius:999px;font-size:15px;font-weight:700;color:#fff;background:var(--success);display:flex;align-items:center;gap:10px}
.btn-call svg{width:20px;height:20px;fill:#fff}
.btn-call.end{background:var(--danger)}
.hint{color:var(--muted);font-size:12px;margin-top:18px;line-height:1.5}

.transcript{display:flex;flex-direction:column;min-height:520px}
.t-head{padding:16px 20px;border-bottom:1px solid var(--border);display:flex;justify-content:space-between;align-items:center}
.t-head h2{font-size:15px;font-weight:700}
.t-body{flex:1;overflow-y:auto;padding:18px 20px;display:flex;flex-direction:column;gap:10px;max-height:560px}
.empty{color:var(--muted);font-size:14px;text-align:center;margin:auto;max-width:280px;line-height:1.6}
.msg{max-width:78%;padding:10px 14px;border-radius:14px;font-size:14px;line-height:1.5;unicode-bidi:plaintext}
.msg .who{display:block;font-size:11px;font-weight:600;opacity:.7;margin-bottom:3px}
.msg.ai{background:var(--primary-soft);color:var(--text);align-self:flex-start;border-top-left-radius:4px}
.msg.user{background:var(--surface-2);align-self:flex-end;border-top-right-radius:4px}
.msg.sys{align-self:center;background:transparent;color:var(--muted);font-size:12px;padding:2px}
.link-btn{border:0;background:transparent;color:var(--muted);font-size:13px;font-weight:600}

/* Özetler */
.logs-head{display:flex;justify-content:space-between;align-items:center;gap:12px;margin-bottom:16px;flex-wrap:wrap}
.logs-head h2{font-size:20px}
.filters{display:flex;gap:6px;flex-wrap:wrap}
.filters button{border:1px solid var(--border);background:var(--surface);color:var(--muted);padding:7px 12px;border-radius:999px;font-size:13px;font-weight:600}
.filters button.active{background:var(--primary);border-color:var(--primary);color:#fff}
.stats{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:16px}
.stat{padding:16px}.stat b{display:block;font-size:24px}.stat span{color:var(--muted);font-size:13px}
.log-list{display:flex;flex-direction:column;gap:12px}
.log{padding:16px 18px}
.log.urgent{border-left:4px solid var(--danger)}
.log-top{display:flex;justify-content:space-between;gap:10px;align-items:flex-start}
.log-name{font-weight:700;font-size:15px}
.log-meta{color:var(--muted);font-size:12px;margin-top:2px}
.badges{display:flex;gap:6px;flex-wrap:wrap;justify-content:flex-end}
.badge{font-size:11px;font-weight:700;padding:4px 8px;border-radius:6px;background:var(--surface-2);color:var(--muted)}
.badge.red{background:var(--danger-soft);color:var(--danger)}
.badge.orange{background:var(--warn-soft);color:var(--warn)}
.badge.green{background:var(--success-soft);color:var(--success)}
.badge.blue{background:var(--primary-soft);color:var(--primary-dark)}
.log-purpose{font-weight:600;font-size:14px;margin-top:10px;unicode-bidi:plaintext}
.log-summary{font-size:14px;line-height:1.55;margin-top:4px;color:var(--text);unicode-bidi:plaintext}
.log-appt{font-size:13px;margin-top:8px;color:var(--primary-dark);font-weight:600}
.log-actions{display:flex;gap:8px;margin-top:12px}
.small{border:1px solid var(--border);background:var(--surface);color:var(--text);padding:6px 12px;border-radius:8px;font-size:12px;font-weight:600}
.small.danger{color:var(--danger)}

/* Ayarlar */
.modal{position:fixed;inset:0;background:rgba(15,23,42,.45);display:none;align-items:center;justify-content:center;padding:16px;z-index:20}
.modal.open{display:flex}
.sheet{width:100%;max-width:480px;padding:22px;max-height:90vh;overflow-y:auto}
.sheet h3{font-size:17px;margin-bottom:16px;display:flex;justify-content:space-between;align-items:center}
.field{margin-bottom:14px}
.field label{display:block;font-size:13px;font-weight:600;margin-bottom:6px}
.field select,.field input{width:100%;height:40px;border:1px solid var(--border);background:var(--surface);color:var(--text);border-radius:10px;padding:0 12px;font-size:14px;font-family:inherit}
.row2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.note{font-size:12px;color:var(--muted);line-height:1.5}
.btn-primary{border:0;background:var(--primary);color:#fff;height:40px;padding:0 18px;border-radius:10px;font-weight:700;font-size:14px}
.arch{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:16px}
.arch button{text-align:left;border:1px solid var(--border);background:var(--surface);color:var(--text);border-radius:12px;padding:12px}
.arch button b{display:block;font-size:14px}
.arch button span{display:block;font-size:11px;color:var(--muted);margin-top:3px}
.arch button.active{border-color:var(--primary);background:var(--primary-soft)}
.presets{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:16px}
.presets button{text-align:left;border:1px solid var(--border);background:var(--surface);color:var(--text);border-radius:12px;padding:10px 12px}
.presets button b{display:block;font-size:13px}
.presets button span{display:block;font-size:11px;color:var(--muted);margin-top:3px}
.presets button.active{border-color:var(--primary);background:var(--primary-soft)}
.cfg-line{font-size:12px;color:var(--muted);margin-top:10px}
.sheet-foot{display:flex;justify-content:space-between;align-items:center;margin-top:8px;gap:10px}
</style>
</head>
<body>
<header>
  <div class="bar">
    <div class="brand">
      <div class="logo"><svg viewBox="0 0 24 24"><path d="M6.6 10.8a15.1 15.1 0 0 0 6.6 6.6l2.2-2.2a1 1 0 0 1 1-.25 11.4 11.4 0 0 0 3.6.57 1 1 0 0 1 1 1V20a1 1 0 0 1-1 1A17 17 0 0 1 3 4a1 1 0 0 1 1-1h3.5a1 1 0 0 1 1 1c0 1.25.2 2.45.57 3.57a1 1 0 0 1-.25 1z"/></svg></div>
      AI Çağrı Asistanı
    </div>
    <nav>
      <button class="active" data-view="call" onclick="showView('call')">Arama</button>
      <button data-view="logs" onclick="showView('logs')">Çağrı Özetleri</button>
    </nav>
    <button class="icon-btn" title="Ayarlar" onclick="openSettings()">
      <svg viewBox="0 0 24 24"><path d="M19.4 13a7.6 7.6 0 0 0 0-2l2-1.6-2-3.4-2.4 1a7.4 7.4 0 0 0-1.7-1l-.4-2.6h-4l-.4 2.6a7.4 7.4 0 0 0-1.7 1l-2.4-1-2 3.4 2 1.6a7.6 7.6 0 0 0 0 2l-2 1.6 2 3.4 2.4-1c.5.4 1.1.7 1.7 1l.4 2.6h4l.4-2.6c.6-.3 1.2-.6 1.7-1l2.4 1 2-3.4zM12 15.5a3.5 3.5 0 1 1 0-7 3.5 3.5 0 0 1 0 7z"/></svg>
    </button>
  </div>
</header>

<main>
  <section class="view active" id="view-call">
    <div class="call-grid">
      <div class="card phone">
        <div class="status" id="status"><span class="dot"></span><span id="statusText">Hazır</span></div>
        <div class="orb" id="orb"><svg viewBox="0 0 24 24"><path d="M12 15a3 3 0 0 0 3-3V6a3 3 0 0 0-6 0v6a3 3 0 0 0 3 3zm5-3a5 5 0 0 1-10 0H5a7 7 0 0 0 6 6.9V21h2v-2.1a7 7 0 0 0 6-6.9z"/></svg></div>
        <div class="headline" id="headline">Test araması başlatın</div>
        <div class="sub" id="sub">Asistan Türkçe karşılar, siz hangi dilde konuşursanız o dilde devam eder.</div>
        <div class="chips">
          <span class="chip lang" id="langChip">Dil: —</span>
          <span class="chip">Türkçe · العربية · English</span>
        </div>
        <div class="timer" id="timer">00:00</div>
        <div class="controls">
          <button class="round" id="muteBtn" title="Mikrofon" onclick="toggleMute()" disabled>
            <svg viewBox="0 0 24 24"><path d="M12 15a3 3 0 0 0 3-3V6a3 3 0 0 0-6 0v6a3 3 0 0 0 3 3zm5-3a5 5 0 0 1-10 0H5a7 7 0 0 0 6 6.9V21h2v-2.1a7 7 0 0 0 6-6.9z"/></svg>
          </button>
          <button class="btn-call" id="callBtn" onclick="toggleCall()">
            <svg viewBox="0 0 24 24"><path d="M6.6 10.8a15.1 15.1 0 0 0 6.6 6.6l2.2-2.2a1 1 0 0 1 1-.25 11.4 11.4 0 0 0 3.6.57 1 1 0 0 1 1 1V20a1 1 0 0 1-1 1A17 17 0 0 1 3 4a1 1 0 0 1 1-1h3.5a1 1 0 0 1 1 1c0 1.25.2 2.45.57 3.57a1 1 0 0 1-.25 1z"/></svg>
            <span id="callLabel">Aramayı Başlat</span>
          </button>
        </div>
        <div class="cfg-line">Aktif: <span id="cfgLine">—</span></div>
        <p class="hint">Görüşme bitince özet, konuşulan dilde kaydedilir ve bildirim gönderilir.</p>
      </div>

      <div class="card transcript">
        <div class="t-head">
          <h2>Canlı görüşme</h2>
          <button class="link-btn" onclick="clearTranscript()">Temizle</button>
        </div>
        <div class="t-body" id="transcript">
          <div class="empty" id="emptyState">Arama başladığında konuşma burada canlı olarak görünecek.</div>
        </div>
      </div>
    </div>
  </section>

  <section class="view" id="view-logs">
    <div class="logs-head">
      <h2>Çağrı Özetleri</h2>
      <div class="filters" id="filters">
        <button class="active" data-f="all">Tümü</button>
        <button data-f="urgent">Acil</button>
        <button data-f="callback">Geri dönüş bekleyen</button>
        <button data-f="done">Geri dönüldü</button>
      </div>
    </div>
    <div class="stats">
      <div class="card stat"><b id="stTotal">0</b><span>Toplam çağrı</span></div>
      <div class="card stat"><b id="stUrgent">0</b><span>Acil</span></div>
      <div class="card stat"><b id="stPending">0</b><span>Geri dönüş bekleyen</span></div>
    </div>
    <div class="log-list" id="logList"></div>
  </section>
</main>

<div class="modal" id="settings" onclick="if(event.target===this)closeSettings()">
  <div class="card sheet">
    <h3>Ayarlar <button class="link-btn" onclick="closeSettings()">Kapat</button></h3>
    <div class="arch" id="arch">
      <button data-a="cascade"><b>Cascade</b><span>STT → LLM → TTS (ayrı servisler)</span></button>
      <button data-a="realtime"><b>Realtime</b><span>Gemini Live (tek model, sesten sese)</span></button>
    </div>
    <div id="cascadeBox">
    <div class="presets" id="presets">
      <button data-p="original_piper" data-stt="whisper-large-v3-turbo" data-llm="openai/gpt-oss-120b" data-tts="piper-dfki">
        <b>1. Yerel Piper</b><span>Whisper Turbo · GPT-OSS 120B · Piper</span></button>
      <button data-p="natural_emel" data-stt="whisper-large-v3-turbo" data-llm="openai/gpt-oss-120b" data-tts="edge-emel">
        <b>2. Doğal kadın sesi</b><span>Whisper Turbo · GPT-OSS 120B · Neural</span></button>
      <button data-p="qwen_high_acc" data-stt="whisper-large-v3" data-llm="qwen/qwen3.8-27b" data-tts="edge-emel">
        <b>3. Qwen · tam doğruluk</b><span>Whisper v3 · Qwen 3.8 27B · Neural</span></button>
      <button data-p="fast_ahmet" data-stt="whisper-large-v3-turbo" data-llm="openai/gpt-oss-20b" data-tts="edge-ahmet">
        <b>4. Hızlı erkek sesi</b><span>Whisper Turbo · GPT-OSS 20B · Neural</span></button>
    </div>
    <div class="field">
      <label>1. Konuşma tanıma (STT)</label>
      <select id="cfgStt">
        <option value="whisper-large-v3-turbo">Groq Whisper Large v3 Turbo — hızlı, dil algılar</option>
        <option value="whisper-large-v3">Groq Whisper Large v3 — daha doğru, dil algılar</option>
        <option value="google-stt">Google Speech-to-Text — yalnızca Türkçe</option>
      </select>
    </div>
    <div class="field">
      <label>2. Dil modeli (LLM)</label>
      <select id="cfgLlm">
        <option value="openai/gpt-oss-120b">OpenAI GPT-OSS 120B</option>
        <option value="openai/gpt-oss-20b">OpenAI GPT-OSS 20B — hızlı</option>
        <option value="qwen/qwen3.8-27b">Alibaba Qwen 3.8 27B</option>
        <option value="llama-3.3-70b-versatile">Meta Llama 3.3 70B</option>
      </select>
    </div>
    <div class="field">
      <label>3. Ses sentezi (TTS)</label>
      <select id="cfgTts">
        <option value="edge-emel">Microsoft Edge Neural — kadın sesi</option>
        <option value="edge-ahmet">Microsoft Edge Neural — erkek sesi</option>
        <option value="google-tts">Google TTS (gTTS)</option>
        <option value="piper-dfki">Piper ONNX — yerel, çevrimdışı</option>
      </select>
    </div>
    </div>
    <div id="realtimeBox" style="display:none">
      <div class="field">
        <label>Gemini Live modeli</label>
        <select id="cfgRtModel">
          <option value="">Varsayılan (eklentinin önerdiği model)</option>
          <option value="gemini-3.8-live">gemini-3.8-live</option>
          <option value="gemini-3.1-flash-live-preview">gemini-3.1-flash-live-preview</option>
        </select>
      </div>
      <div class="field">
        <label>Ses</label>
        <select id="cfgRtVoice">
          <option>Puck</option><option>Charon</option><option>Kore</option><option>Fenrir</option>
          <option>Aoede</option><option>Leda</option><option>Orus</option><option>Zephyr</option>
        </select>
      </div>
      <p class="note" style="margin-bottom:14px">Konuşmayı tanıma, cevap üretme ve seslendirme tek modelde yapılır. Ücretsiz katman geliştirme için yeterlidir; gerçek kişisel veriyle test etmeyin.</p>
    </div>
    <div class="field">
      <label>Çalışma modu</label>
      <select id="cfgMode">
        <option value="hybrid">Mesaj + randevu</option>
        <option value="personal">Yalnızca mesaj</option>
        <option value="business">Randevu</option>
      </select>
    </div>
    <div class="row2">
      <div class="field"><label>Mesai başlangıcı</label><input id="cfgWorkStart" type="time" value="09:00"></div>
      <div class="field"><label>Mesai bitişi</label><input id="cfgWorkEnd" type="time" value="17:00"></div>
    </div>
    <div class="sheet-foot">
      <span class="note" id="cfgStatus">Değişiklikler bir sonraki aramada uygulanır.</span>
      <button class="btn-primary" onclick="saveConfig()">Kaydet</button>
    </div>
  </div>
</div>

<div id="audioContainer" hidden></div>

<script>
const LANG_LABEL = { tr: 'Türkçe', ar: 'العربية', en: 'English' };
let room = null, timerInt = null, seconds = 0, muted = false;
let allLogs = [], filter = 'all';

function showView(v){
  document.querySelectorAll('.view').forEach(e => e.classList.toggle('active', e.id === 'view-' + v));
  document.querySelectorAll('nav button').forEach(b => b.classList.toggle('active', b.dataset.view === v));
  if (v === 'logs') loadLogs();
}

function esc(s){ return String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

function setStatus(live, text){
  document.getElementById('status').classList.toggle('live', live);
  document.getElementById('statusText').innerText = text;
}

function addMsg(role, text){
  const box = document.getElementById('transcript');
  const empty = document.getElementById('emptyState');
  if (empty) empty.remove();
  const d = document.createElement('div');
  d.className = 'msg ' + role;
  if (role === 'sys') d.textContent = text;
  else d.innerHTML = `<span class="who">${role === 'ai' ? 'Asistan' : 'Arayan'}</span>${esc(text)}`;
  box.appendChild(d);
  box.scrollTop = box.scrollHeight;
}

function clearTranscript(){
  document.getElementById('transcript').innerHTML = '<div class="empty" id="emptyState">Arama başladığında konuşma burada canlı olarak görünecek.</div>';
}

function fmt(s){ return String(Math.floor(s/60)).padStart(2,'0') + ':' + String(s%60).padStart(2,'0'); }

async function toggleCall(){ room ? await room.disconnect() : await startCall(); }

async function startCall(){
  try{
    setStatus(false, 'Bağlanıyor…');
    document.getElementById('headline').innerText = 'Bağlanıyor…';
    const data = await (await fetch('/token')).json();
    room = new LivekitClient.Room({ adaptiveStream: true, dynacast: true });

    room.on(LivekitClient.RoomEvent.TrackSubscribed, track => {
      if (track.kind === LivekitClient.Track.Kind.Audio){
        document.getElementById('audioContainer').appendChild(track.attach());
        setStatus(true, 'Görüşmede');
        document.getElementById('headline').innerText = 'Asistan bağlandı';
        document.getElementById('sub').innerText = 'Konuşabilirsiniz.';
      }
    });
    room.on(LivekitClient.RoomEvent.DataReceived, payload => {
      try{
        const msg = JSON.parse(new TextDecoder().decode(payload));
        if (msg.type === 'lang' && LANG_LABEL[msg.lang]){
          document.getElementById('langChip').innerText = 'Dil: ' + LANG_LABEL[msg.lang];
        }
      }catch(e){}
    });
    room.on(LivekitClient.RoomEvent.TranscriptionReceived, (segments, participant) => {
      for (const seg of segments){
        if (seg.final && seg.text.trim()){
          const isAgent = participant && participant.identity && participant.identity.startsWith('agent');
          addMsg(isAgent ? 'ai' : 'user', seg.text);
        }
      }
    });
    room.on(LivekitClient.RoomEvent.ActiveSpeakersChanged, speakers => {
      const agentTalking = (speakers || []).some(p => p.identity && p.identity.startsWith('agent'));
      document.getElementById('orb').classList.toggle('talking', agentTalking);
    });
    room.on(LivekitClient.RoomEvent.Disconnected, () => {
      resetUI();
      addMsg('sys', 'Görüşme bitti. Özet hazırlanıyor…');
      setTimeout(loadLogs, 3000);
    });

    await room.connect(data.ws_url, data.token);
    await room.localParticipant.setMicrophoneEnabled(true);
    clearTranscript();
    addMsg('sys', 'Görüşme başladı');
    seconds = 0; document.getElementById('timer').innerText = '00:00';
    timerInt = setInterval(() => { seconds++; document.getElementById('timer').innerText = fmt(seconds); }, 1000);
    document.getElementById('callBtn').classList.add('end');
    document.getElementById('callLabel').innerText = 'Aramayı Bitir';
    document.getElementById('muteBtn').disabled = false;
  }catch(e){
    resetUI();
    addMsg('sys', 'Bağlantı hatası: ' + e.message);
  }
}

function resetUI(){
  room = null;
  if (timerInt) clearInterval(timerInt);
  setStatus(false, 'Hazır');
  document.getElementById('orb').classList.remove('talking');
  document.getElementById('headline').innerText = 'Test araması başlatın';
  document.getElementById('sub').innerText = 'Asistan Türkçe karşılar, siz hangi dilde konuşursanız o dilde devam eder.';
  document.getElementById('langChip').innerText = 'Dil: —';
  document.getElementById('callBtn').classList.remove('end');
  document.getElementById('callLabel').innerText = 'Aramayı Başlat';
  const mb = document.getElementById('muteBtn'); mb.disabled = true; mb.classList.remove('muted'); muted = false;
}

async function toggleMute(){
  if (!room) return;
  muted = !muted;
  await room.localParticipant.setMicrophoneEnabled(!muted);
  document.getElementById('muteBtn').classList.toggle('muted', muted);
}

/* ---- Özetler ---- */
document.getElementById('filters').addEventListener('click', e => {
  const b = e.target.closest('button'); if (!b) return;
  filter = b.dataset.f;
  document.querySelectorAll('#filters button').forEach(x => x.classList.toggle('active', x === b));
  renderLogs();
});

async function loadLogs(){
  try{ allLogs = await (await fetch('/logs')).json(); }catch(e){ allLogs = []; }
  renderLogs();
}

function renderLogs(){
  const logs = (allLogs || []).slice().reverse();
  document.getElementById('stTotal').innerText = logs.length;
  document.getElementById('stUrgent').innerText = logs.filter(l => l.is_urgent).length;
  document.getElementById('stPending').innerText = logs.filter(l => l.callback_requested && !l.called_back).length;

  const shown = logs.filter(l =>
    filter === 'urgent' ? l.is_urgent :
    filter === 'callback' ? (l.callback_requested && !l.called_back) :
    filter === 'done' ? l.called_back : true);

  const list = document.getElementById('logList');
  if (!shown.length){ list.innerHTML = '<div class="card log"><div class="empty">Henüz kayıt yok.</div></div>'; return; }

  list.innerHTML = shown.map(l => {
    const when = l.timestamp ? new Date(l.timestamp).toLocaleString('tr-TR', {dateStyle:'medium', timeStyle:'short'}) : '';
    const badges = [
      l.is_urgent ? '<span class="badge red">Acil</span>' : '',
      l.callback_requested && !l.called_back ? '<span class="badge orange">Geri dönüş bekliyor</span>' : '',
      l.called_back ? '<span class="badge green">Geri dönüldü</span>' : '',
      LANG_LABEL[l.lang] ? `<span class="badge blue">${LANG_LABEL[l.lang]}</span>` : ''
    ].join('');
    return `<div class="card log ${l.is_urgent ? 'urgent' : ''}">
      <div class="log-top">
        <div><div class="log-name">${esc(l.caller_name || 'Arayan')}</div>
          <div class="log-meta">${esc(when)} · ${esc(l.caller_number || '')}</div></div>
        <div class="badges">${badges}</div>
      </div>
      ${l.caller_purpose ? `<div class="log-purpose">${esc(l.caller_purpose)}</div>` : ''}
      <div class="log-summary">${esc(l.summary_tr || '')}</div>
      ${l.appointment_info ? `<div class="log-appt">Randevu: ${esc(l.appointment_info)}</div>` : ''}
      <div class="log-actions">
        <button class="small" onclick="markReturned('${esc(l.call_id)}', ${!l.called_back})">${l.called_back ? 'Geri dönülmedi olarak işaretle' : 'Geri dönüldü'}</button>
        <button class="small danger" onclick="deleteLog('${esc(l.call_id)}')">Sil</button>
      </div>
    </div>`;
  }).join('');
}

async function markReturned(id, val){
  await fetch('/logs/returned', {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({call_id:id, called_back:val})});
  loadLogs();
}
async function deleteLog(id){
  if (!confirm('Bu kayıt silinsin mi?')) return;
  await fetch('/logs/delete', {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({call_id:id, confirmed:true})});
  loadLogs();
}

/* ---- Ayarlar ---- */
let currentPreset = '';
let currentArch = 'cascade';
function setArch(a){
  currentArch = a === 'realtime' ? 'realtime' : 'cascade';
  document.querySelectorAll('#arch button').forEach(b => b.classList.toggle('active', b.dataset.a === currentArch));
  document.getElementById('cascadeBox').style.display = currentArch === 'cascade' ? '' : 'none';
  document.getElementById('realtimeBox').style.display = currentArch === 'realtime' ? '' : 'none';
}
document.getElementById('arch').addEventListener('click', e => {
  const b = e.target.closest('button'); if (b) setArch(b.dataset.a);
});
function markPreset(){
  const stt = document.getElementById('cfgStt').value, llm = document.getElementById('cfgLlm').value, tts = document.getElementById('cfgTts').value;
  currentPreset = '';
  document.querySelectorAll('#presets button').forEach(b => {
    const on = b.dataset.stt === stt && b.dataset.llm === llm && b.dataset.tts === tts;
    b.classList.toggle('active', on); if (on) currentPreset = b.dataset.p;
  });
}
document.getElementById('presets').addEventListener('click', e => {
  const b = e.target.closest('button'); if (!b) return;
  document.getElementById('cfgStt').value = b.dataset.stt;
  document.getElementById('cfgLlm').value = b.dataset.llm;
  document.getElementById('cfgTts').value = b.dataset.tts;
  markPreset();
});
['cfgStt','cfgLlm','cfgTts'].forEach(id => document.getElementById(id).addEventListener('change', markPreset));
async function showActiveConfig(){
  try{
    const c = await (await fetch('/api/config')).json();
    document.getElementById('cfgLine').innerText = c.architecture === 'realtime'
      ? `Realtime · Gemini Live ${c.realtime_model || '(varsayılan)'} · ${c.realtime_voice}`
      : `Cascade · ${c.stt_model} · ${c.llm_model} · ${c.tts_voice}`;
  }catch(e){}
}
async function openSettings(){
  try{
    const c = await (await fetch('/api/config')).json();
    document.getElementById('cfgStt').value = c.stt_model;
    document.getElementById('cfgLlm').value = c.llm_model;
    document.getElementById('cfgTts').value = c.tts_voice;
    document.getElementById('cfgMode').value = c.assistant_mode;
    document.getElementById('cfgWorkStart').value = c.work_start;
    document.getElementById('cfgWorkEnd').value = c.work_end;
    document.getElementById('cfgRtModel').value = c.realtime_model || '';
    document.getElementById('cfgRtVoice').value = c.realtime_voice || 'Puck';
    setArch(c.architecture);
    markPreset();
  }catch(e){}
  document.getElementById('cfgStatus').innerText = 'Değişiklikler bir sonraki aramada uygulanır.';
  document.getElementById('settings').classList.add('open');
}
function closeSettings(){ document.getElementById('settings').classList.remove('open'); }
async function saveConfig(){
  const body = {
    architecture: currentArch,
    realtime_model: document.getElementById('cfgRtModel').value,
    realtime_voice: document.getElementById('cfgRtVoice').value,
    preset: currentPreset || 'custom',
    stt_model: document.getElementById('cfgStt').value,
    llm_model: document.getElementById('cfgLlm').value,
    tts_voice: document.getElementById('cfgTts').value,
    assistant_mode: document.getElementById('cfgMode').value,
    work_start: document.getElementById('cfgWorkStart').value,
    work_end: document.getElementById('cfgWorkEnd').value,
  };
  await fetch('/api/config', {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify(body)});
  document.getElementById('cfgStatus').innerText = 'Kaydedildi ✓';
  showActiveConfig();
  setTimeout(closeSettings, 700);
}

if (location.pathname === '/ozetler') showView('logs');
showActiveConfig();
loadLogs();
setInterval(() => { if (document.getElementById('view-logs').classList.contains('active')) loadLogs(); }, 5000);
</script>
</body>
</html>
"""


async def index(request: web.Request):
    return web.Response(text=HTML_PAGE, content_type="text/html")


def require_admin(request: web.Request) -> None:
    configured_token = os.getenv("ADMIN_API_TOKEN", "")
    authorization = request.headers.get("Authorization", "")
    presented_token = request.headers.get("X-Admin-Token", "")
    if authorization.startswith("Bearer "):
        presented_token = authorization.removeprefix("Bearer ").strip()
    if not is_authorized_request(request.remote, presented_token, configured_token):
        raise web.HTTPForbidden(text="Yönetim API'si için yetki gerekli.")


async def get_config_endpoint(request: web.Request):
    require_admin(request)
    return web.json_response(CONFIG_STORE.read())


async def save_config_endpoint(request: web.Request):
    require_admin(request)
    try:
        body = await request.json()
        cfg = CONFIG_STORE.update(body)
    except (ValueError, RuntimeError, json.JSONDecodeError) as e:
        return web.json_response({"ok": False, "error": str(e)}, status=400)
    return web.json_response({"ok": True, "config": cfg})


async def mark_returned_endpoint(request: web.Request):
    require_admin(request)
    try:
        body = await request.json()
        call_id = str(body.get("call_id") or request.match_info.get("call_id", "")).strip()
        if not call_id:
            return web.json_response({"ok": False, "error": "call_id zorunludur."}, status=400)
        called_back = bool(body.get("called_back", True))
        record = CALL_LOG_REPOSITORY.mark_called_back(call_id, called_back)
        return web.json_response({"ok": True, "record": record.to_dict()})
    except RecordNotFound:
        return web.json_response({"ok": False, "error": "Çağrı kaydı bulunamadı."}, status=404)
    except (StorageError, json.JSONDecodeError) as e:
        return web.json_response({"ok": False, "error": str(e)}, status=400)


async def delete_log_endpoint(request: web.Request):
    require_admin(request)
    try:
        body = await request.json()
        call_id = str(body.get("call_id", "")).strip()
        if not call_id:
            return web.json_response({"ok": False, "error": "call_id zorunludur."}, status=400)
        if body.get("confirmed") is not True:
            return web.json_response({"ok": False, "error": "Silme işlemi için confirmed=true gerekli."}, status=400)
        CALL_LOG_REPOSITORY.delete(call_id)
        return web.json_response({"ok": True})
    except RecordNotFound:
        return web.json_response({"ok": False, "error": "Çağrı kaydı bulunamadı."}, status=404)
    except (StorageError, json.JSONDecodeError) as e:
        return web.json_response({"ok": False, "error": str(e)}, status=400)


async def token_endpoint(request: web.Request):
    require_admin(request)
    api_key = os.getenv("LIVEKIT_API_KEY", "devkey")
    api_secret = os.getenv("LIVEKIT_API_SECRET", "secret")
    room_name = f"call-web-{uuid.uuid4().hex[:6]}"
    identity = f"caller-{uuid.uuid4().hex[:4]}"

    token = (
        api.AccessToken(api_key, api_secret)
        .with_identity(identity)
        .with_name("Arayan Kisi")
        .with_grants(
            api.VideoGrants(
                room_join=True,
                room=room_name,
                can_publish=True,
                can_subscribe=True,
            )
        )
        .to_jwt()
    )

    host = request.host.split(":")[0]
    ws_url = f"ws://{host}:7880"
    return web.json_response({"token": token, "ws_url": ws_url, "room": room_name})


async def logs_endpoint(request: web.Request):
    require_admin(request)
    try:
        return web.json_response([record.to_dict() for record in CALL_LOG_REPOSITORY.list_records()])
    except StorageError as e:
        return web.json_response({"ok": False, "error": str(e)}, status=500)


async def health_endpoint(request: web.Request):
    require_admin(request)
    issues = validate_configuration(project_dir=Path(__file__).parent, config=CONFIG_STORE.read())
    return web.json_response({
        "ok": not any(issue.severity == "error" for issue in issues),
        "issues": [
            {"severity": issue.severity, "code": issue.code, "message": issue.message}
            for issue in issues
        ],
    })


def create_app() -> web.Application:
    """Web paneli ve yönetim API'si için yeni uygulama örneği oluşturur."""
    application = web.Application()
    application.router.add_get("/", index)
    application.router.add_get("/ozetler", index)
    application.router.add_get("/token", token_endpoint)
    application.router.add_get("/logs", logs_endpoint)
    application.router.add_post("/logs/returned", mark_returned_endpoint)
    application.router.add_post("/logs/delete", delete_log_endpoint)
    application.router.add_get("/api/config", get_config_endpoint)
    application.router.add_post("/api/config", save_config_endpoint)
    application.router.add_get("/api/health", health_endpoint)
    application.router.add_get("/api/calls", logs_endpoint)
    application.router.add_post("/api/calls/{call_id}/returned", mark_returned_endpoint)
    return application


app = create_app()

if __name__ == "__main__":
    web.run_app(app, host=os.getenv("WEB_HOST", "127.0.0.1"), port=8080)
