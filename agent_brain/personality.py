"""Arayanın diline göre tutarlı ve kısa asistan üslubu."""

from __future__ import annotations

from .models import Language


def personality_rule(language: Language) -> str:
    return {
        Language.TURKISH: (
            "Arayanla doğal, sakin ve saygılı Türkçe konuş. Kısa cümleler kullan; "
            "kesin olmayan bilgiyi kesinmiş gibi söyleme."
        ),
        Language.ENGLISH: (
            "Speak in warm, concise and respectful English. Use short sentences and never present "
            "unverified information as certain."
        ),
        Language.ARABIC: (
            "تحدث بالعربية الفصحى بأسلوب ودود ومحترم وبجمل قصيرة. لا تقدم أي معلومة غير مؤكدة كحقيقة."
        ),
    }[language]
