# دليل رفع Bloxo على Google Play خطوة بخطوة

كل اللي محتاجه موجود جوه المشروع:

| الحاجة | مكانها |
|---|---|
| ملف الرفع (AAB) | `build/bloxo-release.aab` |
| APK للتجربة على موبايلك | `build/bloxo-release.apk` |
| مفتاح التوقيع + الباسورد | `secrets/` (⚠️ اعمل له نسخة احتياطي) |
| الأيقونة 512×512 | `store/graphics/icon-512.png` |
| الصورة الكبيرة 1024×500 | `store/graphics/feature-graphic-1024x500.png` |
| 8 سكرين شوت 1080×1920 | `store/screenshots/` |
| الاسم والوصف بـ 6 لغات + Release notes | `store/listing.md` |
| صفحة سياسة الخصوصية | `docs/privacy-policy.html` |

> أسماء الأزرار تحت مكتوبة بالإنجليزي زي ما هتلاقيها في Play Console بالظبط.

---

## 0) قبل أي حاجة: جرّب اللعبة على موبايلك
وصّل `build/bloxo-release.apk` لموبايلك (كابل، أو تليجرام، أو درايف) وسطّبه.
ممكن الموبايل يقولك "Install unknown apps"، اسمح بيها مرة واحدة.
العب شوية، اقفل اللعبة وافتحها تاني، واتأكد إن السكور اتحفظ.

---

## 1) حط سياسة الخصوصية على النت (لازم يبقى عندك لينك)
جوجل محتاجة **لينك** لصفحة سياسة الخصوصية. اختار طريقة من الاتنين دول:

**أ) GitHub Pages:** دي تنفع لو الريبو Public. لو Private هتحتاج GitHub Pro.
1. افتح الريبو على GitHub، وادخل **Settings ← Pages**.
2. في Source اختار **Deploy from a branch**، وبعدين **Branch: main** وفولدر **/docs**، واضغط **Save**.
3. استنى دقيقتين. اللينك هيبقى بالشكل ده:
   `https://abdelrhmn-ismail.github.io/Bloxo-Game/privacy-policy.html`

**ب) Google Sites:** دي مجانية وتنفع حتى لو الريبو Private.
1. ادخل sites.google.com واعمل موقع جديد باسم Bloxo Privacy Policy.
2. افتح `docs/privacy-policy.html` في المتصفح، وانسخ الكلام اللي فيه والزقه في الموقع.
3. اضغط **Publish** وخد اللينك.

افتح اللينك من موبايلك واتأكد إنه شغال قبل ما تكمّل.

---

## 2) اعمل الأبلكيشن
1. ادخل [play.google.com/console](https://play.google.com/console) واضغط **Create app**.
2. **App name:** `Bloxo: Block Puzzle`
3. **Default language:** English (United States) – en-US
4. **App or game:** Game
5. **Free or paid:** Free (⚠️ مش هتقدر تغيّرها لـ Paid بعد كده)
6. علّم على الإقرارات (Developer Program Policies وUS export laws) واضغط **Create app**.

---

## 3) صفحة المتجر (Main store listing)
روح **Grow users ← Store presence ← Main store listing**.
- **App name / Short description / Full description:** انسخهم من `store/listing.md`، قسم English.
- **App icon:** `store/graphics/icon-512.png`
- **Feature graphic:** `store/graphics/feature-graphic-1024x500.png`
- **Phone screenshots:** ارفع الصور الـ 8 اللي في `store/screenshots/` بالترتيب.
- سيب Tablet screenshots فاضية، هي اختيارية.
- اضغط **Save**.

**اللغات التانية:** من نفس الصفحة اختار **Manage translations ← Add your own translations**، وعلّم على Arabic وFrench وGerman وSpanish وItalian. بعدين انسخ لكل لغة الاسم والوصف بتوعها من `store/listing.md`. الصور ممكن تسيبها زي ما هي.

**Store settings:** روح **Grow users ← Store presence ← Store settings**:
- **Category:** Game ← **Puzzle**
- **Tags:** اختار Puzzle وBlock puzzle وCasual لو موجودين.
- **Contact details:** الإيميل، وده إجباري وهيظهر للناس في المتجر.

---

## 4) قسم App content (الفورمات الإجبارية)
روح **Policy and programs ← App content**، وكمّل كل فورم بالإجابات دي:

| الفورم | الإجابة |
|---|---|
| **Privacy policy** | اللينك اللي عملته في خطوة 1 |
| **App access** | All functionality is available without any access restrictions |
| **Ads** | No, my app does not contain ads |
| **Content rating** | ابدأ الاستبيان، والإيميل بتاعك، وCategory: **All Other App Types** (أو Game لو ظهرت). جاوب **No** على كل الأسئلة: مفيش عنف ولا دم ولا ألفاظ ولا قمار ولا محتوى جنسي، ومفيش تواصل بين المستخدمين، ومفيش شراء داخل اللعبة. هيطلع غالبًا **PEGI 3 / Everyone**. |
| **Target audience** | اختار **13–15, 16–17, 18+**. لو اختارت أعمار أقل من 13 هتدخل في قواعد Families، ودي أصعب. |
| **Data safety** | Does your app collect or share any of the required user data types? ← **No**. وبعدين **Save** و**Submit**. |
| **Government apps** | No |
| **Financial features** | My app doesn't provide any financial features |
| **Health** | My app does not have any health features |
| **News app** | No |
| **Advertising ID** | No (اللعبة مش بتستخدمه) |

---

## 5) الاختبار المغلق (Closed testing): إجباري للحسابات الشخصية الجديدة
جوجل بتطلب **12 شخص على الأقل** يكونوا مشتركين في الاختبار **14 يوم ورا بعض** قبل ما تقدر تنزّل اللعبة للناس كلها.

1. روح **Test and release ← Testing ← Closed testing** واضغط **Create track** (أو استخدم Alpha الموجود).
2. **Countries / regions:** اختار كل الدول (Add countries ← Select all).
3. **Testers:** اعمل **Create email list** وضيف إيميلات Gmail لـ 12 شخص أو أكتر (أصحاب، أهل). ضيف 15 لو تقدر عشان الاحتياط.
4. اضغط **Create new release**:
   - هيسألك عن **Play App Signing**، اختار **Use Google-generated key** (الموصى بيه). كده جوجل بتمسك مفتاح التوقيع النهائي، والمفتاح اللي في `secrets/` يبقى "upload key". ولو ضاع ينفع تطلب من جوجل تغييره.
   - ارفع `build/bloxo-release.aab`.
   - **Release name:** `1.0.0`
   - **Release notes:** انسخهم من آخر جزء في `store/listing.md`.
   - اضغط **Next** ← **Save** ← **Send for review**.
5. بعد ما الإصدار يتوافق عليه (من ساعات لكام يوم)، هتلاقي **Copy link** في تاب **Testers**. ابعت اللينك للـ 12 شخص.
   - كل واحد يفتح اللينك **بنفس إيميل الـ Gmail اللي ضفته**، ويضغط **Become a tester**، وبعدين ينزّل اللعبة من Play Store.
   - مهم إنهم **ميلغوش الاشتراك** طول الـ 14 يوم. يا ريت كمان يفتحوا اللعبة كل كام يوم.
6. ركّز في الـ 14 يوم دول، وصلّح أي مشكلة يقولولك عليها.

---

## 6) النشر للكل (Production)
1. بعد الـ 14 يوم هيظهر في **Dashboard** زرار **Apply for production**.
2. هيسألوك كام سؤال عن الاختبار، زي "إيه اللي اتعلمته؟" و"إيه اللي غيّرته؟". جاوب بصراحة وباختصار بالإنجليزي، مثلًا:
   *"Testers played daily on different phones. Feedback helped us check performance, saving and the tutorial. The game is stable."*
3. بعد الموافقة روح **Production ← Create new release**، واختار نفس الـ AAB من **Add from library**، وبعدين **Send for review**.
4. المراجعة بتاخد من كام يوم لأسبوع، وبعدها اللعبة تنزل على Google Play 🎉

---

## 🔄 لما تحب تنزّل تحديث بعد كده
1. زوّد `version/code` في الـ preset الاتنين (`Android` و`Android Release`) اللي في `export_presets.cfg`: من 1 لـ 2 لـ 3، وهكذا.
   ممكن كمان تغيّر `version/name` لـ `1.0.1`.
2. شغّل `tools/export_release.sh`.
3. ارفع `build/bloxo-release.aab` الجديد في **Production ← Create new release**.

## ⚠️ مفتاح التوقيع
فولدر `secrets/` مش بيترفع على الجيت عشان مكتوب في `.gitignore`. انسخه **في 3 أماكن** (فلاشة، Google Drive، إيميل لنفسك).
لو المفتاح والباسورد ضاعوا وأنت مش مفعّل Play App Signing، **مش هتقدر تحدّث اللعبة تاني أبدًا**.
