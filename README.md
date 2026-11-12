# Bloxo

**Bloxo** — لعبة بلوكات أصلية معمولة بـ **Godot 4**. الخطة الكاملة في [PLAN.md](PLAN.md).

## ▶️ إزاي تشغّلها
1. نزّل **Godot 4.4 أو أحدث** (Standard) من https://godotengine.org/download
2. افتح Godot → **Import** → اختار ملف `project.godot` من الفولدر ده → **Import & Edit**
3. أول مرة هياخد ثواني يجهّز الملفات
4. دوس **▶️** (فوق على اليمين) أو **F5**
5. العب بالماوس: اسحب القطع من تحت وحطها على الشبكة

لو ظهر أي خطأ أحمر في الـ **Output** تحت، صوّره أو انسخه وابعتهولي.

## 🧪 تشغيل الاختبارات
من فولدر المشروع في الترمينال:
```
godot --headless --path . --import
godot --headless --path . -s tests/test_runner.gd
```
لازم يطلع في الآخر `0 failed`.

## 🎨 أغيّر إيه منين؟
| عايز تغيّر | الملف |
|---|---|
| اسم اللعبة (Bloxo) | `project.godot` ← `config/name` |
| الألوان | `autoload/palette.gd` |
| أشكال القطع | `logic/shapes.gd` (ارسم بـ X و .) |
| النقاط والكومبو | `logic/scoring.gd` |
| الصعوبة | `logic/piece_generator.gd` و `logic/game_state.gd` |
| شكل الخانة | `effects/cell_painter.gd` |
| الأصوات | حط ملف بنفس الاسم في `assets/sounds/` |
| موسيقى خلفية | حط `assets/sounds/music.ogg` |
| أيقونة | `icon.svg` |
