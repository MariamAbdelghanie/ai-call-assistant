r"""Gemini anahtarını ve Live (Realtime) bağlantısını test eder.
Çalıştır:  .\.venv\Scripts\python.exe test_gemini.py
"""
import os, asyncio
from dotenv import load_dotenv
from google import genai

load_dotenv()
KEY = os.getenv("GOOGLE_API_KEY", "")
print("1) GOOGLE_API_KEY bulundu mu:", bool(KEY), "| uzunluk:", len(KEY))

client = genai.Client(api_key=KEY)

print("2) Anahtar testi (normal istek)...")
try:
    r = client.models.generate_content(model="gemini-3.8-flash", contents="Sadece 'tamam' yaz.")
    print("   OK ->", (r.text or "").strip()[:50])
except Exception as e:
    print("   HATA ->", type(e).__name__, str(e)[:300])

print("3) Live destekleyen modeller:")
live = []
try:
    for m in client.models.list():
        if "bidiGenerateContent" in (getattr(m, "supported_actions", None) or []):
            live.append(m.name)
            print("   -", m.name)
except Exception as e:
    print("   HATA ->", type(e).__name__, str(e)[:300])


async def live_test(model):
    print(f"4) Live bağlantı testi: {model}")
    try:
        async with client.aio.live.connect(model=model, config={"response_modalities": ["AUDIO"]}) as s:
            await s.send_client_content(turns={"role": "user", "parts": [{"text": "Merhaba de."}]}, turn_complete=True)
            async for msg in s.receive():
                if msg.server_content and msg.server_content.turn_complete:
                    break
                if msg.data:
                    print("   OK -> ses verisi geldi")
                    break
    except Exception as e:
        print("   HATA ->", type(e).__name__, str(e)[:300])

for name in ["gemini-2.5-flash-native-audio-preview-12-2025", "gemini-3.8-live", "gemini-3.1-flash-live-preview"]:
    asyncio.run(live_test(name))
