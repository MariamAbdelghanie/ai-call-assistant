"""Derleyici olmadan yapilabilecek statik kontroller.

flutter analyze yerine gecmez; amaci dosya duzenlerken gozden kacan
tipik hatalari (eksik metin anahtari, tanimsiz renk, tekrar eden
anahtar) hizlica yakalamaktir.
"""
import collections
import glob
import io
import re
import sys

errs = []


def fail(msg):
    errs.append(msg)


sdart = io.open("lib/l10n/strings.dart", encoding="utf-8").read()
lines = sdart.split("\n")
bounds = []
for i, ln in enumerate(lines):
    m = re.match(r"^    '(tr|ar|en)': \{$", ln)
    if m:
        bounds.append((m.group(1), i))
bounds.append(("END", len(lines)))

keys = {}
for idx in range(len(bounds) - 1):
    lang, st = bounds[idx]
    en = bounds[idx + 1][1]
    seen = []
    for i in range(st + 1, en):
        m = re.match(r"^      '([^']+)':", lines[i])
        if m:
            seen.append(m.group(1))
    dup = sorted({k for k in seen if seen.count(k) > 1})
    if dup:
        fail(f"strings.dart {lang}: tekrar eden anahtar {dup}")
    keys[lang] = set(seen)

for lang in ("ar", "en"):
    miss = sorted(keys["tr"] - keys.get(lang, set()))
    if miss:
        fail(f"strings.dart {lang} dilinde eksik: {miss}")

used = collections.defaultdict(set)
for f in glob.glob("lib/**/*.dart", recursive=True):
    if f.endswith("strings.dart"):
        continue
    src = io.open(f, encoding="utf-8").read()
    # .t('x') ve .t(kosul ? 'x' : 'y') gibi kullanimlari birlikte tarar:
    # .t( ... ) parantezinin icindeki tum tek tirnakli dizgileri alir.
    for call in re.findall(r"\.t\(([^()]*)\)", src):
        for m in re.findall(r"'([A-Za-z_][A-Za-z0-9_]*)'", call):
            used[m].add(f)
for k, fs in sorted(used.items()):
    if "$" in k:
        continue  # dinamik olarak kurulan anahtar
    if k not in keys["tr"]:
        fail(f"eksik metin anahtari '{k}' -> {', '.join(sorted(fs))}")

theme = io.open("lib/theme/app_theme.dart", encoding="utf-8").read()
pal = set(re.findall(r"static const (?:Color|List<Color>) (\w+)\s*=", theme))
tok = set(re.findall(r"^  final (?:[\w<>]+) (\w+);", theme, re.M))
tok |= set(re.findall(r"(?:LinearGradient|List<BoxShadow>) get (\w+)", theme))
for f in glob.glob("lib/**/*.dart", recursive=True):
    src = io.open(f, encoding="utf-8").read()
    for m in sorted(set(re.findall(r"AppPalette\.(\w+)", src)) - pal):
        fail(f"{f}: AppPalette.{m} tanimsiz")
    for m in sorted(set(re.findall(r"tokens\.(\w+)", src)) - tok):
        fail(f"{f}: tokens.{m} tanimsiz")

for f in sorted(glob.glob("lib/**/*.dart", recursive=True)):
    src = io.open(f, encoding="utf-8").read()
    for a, b in (("(", ")"), ("{", "}"), ("[", "]")):
        if src.count(a) != src.count(b):
            print(f"  not: {f} {a}{b} dengesiz (duz metin icinde olabilir)")

print(f"metin anahtari: {len(keys['tr'])} | kontrol edilen dosya: "
      f"{len(glob.glob('lib/**/*.dart', recursive=True))}")
if errs:
    for e in errs:
        print("  HATA:", e)
    print("SONUC: %d hata" % len(errs))
    sys.exit(1)
print("SONUC: temiz")
