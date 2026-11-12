class_name Strings
extends RefCounted
## Every piece of text shown in the game, in all supported languages.
## Use it through the Lang autoload: Lang.t("PLAY").
##
## To add a language: add its code to LANGS, its name to NAMES, and a
## translation to every entry in TEXT (the tests check nothing is missing).
## Keys in UPPER_CASE; "%d" is replaced by a number.

const LANGS := ["en", "fr", "de", "es", "it", "ar"]

## Each language's name written in that language (shown on the button).
const NAMES := {
	"en": "English",
	"fr": "Français",
	"de": "Deutsch",
	"es": "Español",
	"it": "Italiano",
	"ar": "العربية",
}

## Right-to-left languages.
const RTL := ["ar"]

const TEXT := {
	# --- menu / splash ---
	"BLOCK_PUZZLE": {"en": "BLOCK PUZZLE", "fr": "PUZZLE DE BLOCS", "de": "BLOCK-PUZZLE",
		"es": "PUZLE DE BLOQUES", "it": "PUZZLE A BLOCCHI", "ar": "ألغاز المكعبات"},
	"BEST": {"en": "BEST", "fr": "RECORD", "de": "REKORD",
		"es": "RÉCORD", "it": "RECORD", "ar": "الأفضل"},
	"PLAY": {"en": "PLAY", "fr": "JOUER", "de": "SPIELEN",
		"es": "JUGAR", "it": "GIOCA", "ar": "العب"},
	"CONTINUE": {"en": "CONTINUE", "fr": "CONTINUER", "de": "WEITER",
		"es": "CONTINUAR", "it": "CONTINUA", "ar": "متابعة"},
	"NEW_GAME": {"en": "NEW GAME", "fr": "NOUVELLE PARTIE", "de": "NEUES SPIEL",
		"es": "NUEVA PARTIDA", "it": "NUOVA PARTITA", "ar": "لعبة جديدة"},

	# --- settings ---
	"SOUND": {"en": "Sound", "fr": "Son", "de": "Ton",
		"es": "Sonido", "it": "Suono", "ar": "الصوت"},
	"MUSIC": {"en": "Music", "fr": "Musique", "de": "Musik",
		"es": "Música", "it": "Musica", "ar": "الموسيقى"},
	"VIBRATION": {"en": "Vibration", "fr": "Vibration", "de": "Vibration",
		"es": "Vibración", "it": "Vibrazione", "ar": "الاهتزاز"},
	"ON": {"en": "ON", "fr": "OUI", "de": "AN",
		"es": "SÍ", "it": "SÌ", "ar": "تشغيل"},
	"OFF": {"en": "OFF", "fr": "NON", "de": "AUS",
		"es": "NO", "it": "NO", "ar": "إيقاف"},
	"THEME": {"en": "Theme", "fr": "Thème", "de": "Design",
		"es": "Tema", "it": "Tema", "ar": "المظهر"},
	"LANGUAGE": {"en": "Language", "fr": "Langue", "de": "Sprache",
		"es": "Idioma", "it": "Lingua", "ar": "اللغة"},

	# --- theme names (key = "THEME_" + theme id in upper case) ---
	"THEME_NEON": {"en": "Neon", "fr": "Néon", "de": "Neon",
		"es": "Neón", "it": "Neon", "ar": "نيون"},
	"THEME_CANDY": {"en": "Candy", "fr": "Bonbons", "de": "Bonbons",
		"es": "Caramelos", "it": "Caramelle", "ar": "حلويات"},
	"THEME_GEMS": {"en": "Gems", "fr": "Gemmes", "de": "Edelsteine",
		"es": "Gemas", "it": "Gemme", "ar": "جواهر"},
	"THEME_NATURE": {"en": "Nature", "fr": "Nature", "de": "Natur",
		"es": "Naturaleza", "it": "Natura", "ar": "طبيعة"},

	# --- pause / game over ---
	"PAUSED": {"en": "Paused", "fr": "Pause", "de": "Pause",
		"es": "Pausa", "it": "Pausa", "ar": "إيقاف مؤقت"},
	"RESUME": {"en": "Resume", "fr": "Reprendre", "de": "Fortsetzen",
		"es": "Reanudar", "it": "Riprendi", "ar": "استئناف"},
	"RESTART": {"en": "Restart", "fr": "Recommencer", "de": "Neustart",
		"es": "Reiniciar", "it": "Ricomincia", "ar": "إعادة البدء"},
	"HOME": {"en": "Home", "fr": "Accueil", "de": "Menü",
		"es": "Inicio", "it": "Menu", "ar": "الرئيسية"},
	"GAME_OVER": {"en": "Game Over", "fr": "Partie terminée", "de": "Spiel vorbei",
		"es": "Fin del juego", "it": "Partita finita", "ar": "انتهت اللعبة"},
	"NEW_BEST": {"en": "NEW BEST!", "fr": "NOUVEAU RECORD !", "de": "NEUER REKORD!",
		"es": "¡NUEVO RÉCORD!", "it": "NUOVO RECORD!", "ar": "رقم قياسي جديد!"},
	"SCORE": {"en": "SCORE", "fr": "SCORE", "de": "PUNKTE",
		"es": "PUNTOS", "it": "PUNTEGGIO", "ar": "النتيجة"},
	"PLAY_AGAIN": {"en": "Play Again", "fr": "Rejouer", "de": "Nochmal",
		"es": "Jugar de nuevo", "it": "Gioca ancora", "ar": "العب مجددًا"},

	# --- in-game pop-ups ---
	"GREAT": {"en": "Great!", "fr": "Super !", "de": "Super!",
		"es": "¡Genial!", "it": "Grande!", "ar": "رائع!"},
	"EXCELLENT": {"en": "Excellent!", "fr": "Excellent !", "de": "Exzellent!",
		"es": "¡Excelente!", "it": "Eccellente!", "ar": "ممتاز!"},
	"AMAZING": {"en": "Amazing!", "fr": "Incroyable !", "de": "Unglaublich!",
		"es": "¡Increíble!", "it": "Incredibile!", "ar": "مذهل!"},
	"COMBO": {"en": "Combo x%d", "fr": "Combo x%d", "de": "Kombo x%d",
		"es": "Combo x%d", "it": "Combo x%d", "ar": "كومبو x%d"},
	"BOARD_CLEAR": {"en": "Board Clear!", "fr": "Plateau vidé !", "de": "Feld leer!",
		"es": "¡Tablero limpio!", "it": "Tavola pulita!", "ar": "اللوحة فارغة!"},
	"NO_SPACE": {"en": "No more space!", "fr": "Plus de place !", "de": "Kein Platz mehr!",
		"es": "¡Sin espacio!", "it": "Spazio finito!", "ar": "لا توجد مساحة!"},

	# --- tutorial / hints ---
	"HOW_TO_PLAY": {"en": "How to play", "fr": "Comment jouer", "de": "Anleitung",
		"es": "Cómo jugar", "it": "Come si gioca", "ar": "طريقة اللعب"},
	"TUT_DRAG": {"en": "Drag the piece onto the board", "fr": "Fais glisser la pièce sur le plateau",
		"de": "Ziehe das Teil auf das Spielfeld", "es": "Arrastra la pieza al tablero",
		"it": "Trascina il pezzo sul tabellone", "ar": "اسحب القطعة إلى اللوحة"},
	"TUT_CLEAR": {"en": "Fill a whole row or column to clear it", "fr": "Remplis une ligne ou une colonne pour la vider",
		"de": "Fülle eine Reihe oder Spalte, um sie zu leeren", "es": "Llena una fila o columna para borrarla",
		"it": "Riempi una riga o colonna per eliminarla", "ar": "املأ صفًا أو عمودًا كاملًا ليختفي"},
	"TUT_TRY_AGAIN": {"en": "Almost! Fill the gap in the row", "fr": "Presque ! Remplis le trou de la ligne",
		"de": "Fast! Fülle die Lücke in der Reihe", "es": "¡Casi! Llena el hueco de la fila",
		"it": "Quasi! Riempi il buco nella riga", "ar": "قربت! املأ الفراغ في الصف"},
	"TUT_END": {"en": "The game ends when no piece fits.\nGood luck!",
		"fr": "La partie se termine quand\nplus aucune pièce ne rentre.\nBonne chance !",
		"de": "Das Spiel endet, wenn\nkein Teil mehr passt.\nViel Glück!",
		"es": "El juego termina cuando\nninguna pieza cabe.\n¡Suerte!",
		"it": "La partita finisce quando\nnessun pezzo entra.\nBuona fortuna!",
		"ar": "تنتهي اللعبة عندما\nلا تجد القطع مكانًا.\nبالتوفيق!"},
	"TUT_START": {"en": "Start", "fr": "Commencer", "de": "Los geht's",
		"es": "Empezar", "it": "Inizia", "ar": "ابدأ"},
	"SKIP": {"en": "Skip", "fr": "Passer", "de": "Überspringen",
		"es": "Saltar", "it": "Salta", "ar": "تخطي"},
	"HINTS": {"en": "Hints", "fr": "Indices", "de": "Tipps",
		"es": "Pistas", "it": "Suggerimenti", "ar": "التلميحات"},

	# --- power-ups & gifts (key = "POWER_" + kind in upper case) ---
	"POWER_HAMMER": {"en": "Hammer", "fr": "Marteau", "de": "Hammer",
		"es": "Martillo", "it": "Martello", "ar": "مطرقة"},
	"POWER_BOMB": {"en": "Bomb", "fr": "Bombe", "de": "Bombe",
		"es": "Bomba", "it": "Bomba", "ar": "قنبلة"},
	"POWER_SHUFFLE": {"en": "Shuffle", "fr": "Mélanger", "de": "Mischen",
		"es": "Mezclar", "it": "Mescola", "ar": "تبديل"},
	"POWER_UNDO": {"en": "Undo", "fr": "Annuler", "de": "Rückgängig",
		"es": "Deshacer", "it": "Annulla", "ar": "تراجع"},
	"TAP_HAMMER": {"en": "Tap a block to break it", "fr": "Touche un bloc pour le casser",
		"de": "Tippe auf einen Block, um ihn zu zerschlagen", "es": "Toca un bloque para romperlo",
		"it": "Tocca un blocco per romperlo", "ar": "المس مكعبًا لتكسره"},
	"TAP_BOMB": {"en": "Tap where the bomb should explode", "fr": "Touche l'endroit où la bombe doit exploser",
		"de": "Tippe, wo die Bombe explodieren soll", "es": "Toca donde debe explotar la bomba",
		"it": "Tocca dove deve esplodere la bomba", "ar": "المس المكان الذي تنفجر فيه القنبلة"},
	"NOTHING_TO_UNDO": {"en": "Nothing to undo", "fr": "Rien à annuler", "de": "Nichts rückgängig zu machen",
		"es": "Nada que deshacer", "it": "Niente da annullare", "ar": "لا يوجد ما يمكن التراجع عنه"},
	"RESCUE": {"en": "Out of moves! Use a power-up", "fr": "Plus de coups ! Utilise un bonus",
		"de": "Keine Züge mehr! Nutze ein Extra", "es": "¡Sin movimientos! Usa un potenciador",
		"it": "Mosse finite! Usa un potenziamento", "ar": "لا توجد حركات! استخدم أداة مساعدة"},
	"KEEP_PLAYING": {"en": "Keep playing", "fr": "Continuer à jouer", "de": "Weiterspielen",
		"es": "Seguir jugando", "it": "Continua a giocare", "ar": "واصل اللعب"},
	"DAILY_GIFT": {"en": "Daily gift!", "fr": "Cadeau du jour !", "de": "Tagesgeschenk!",
		"es": "¡Regalo diario!", "it": "Regalo del giorno!", "ar": "هدية اليوم!"},
	"FREE_GIFT": {"en": "FREE GIFT", "fr": "CADEAU GRATUIT", "de": "GRATIS-GESCHENK",
		"es": "REGALO GRATIS", "it": "REGALO GRATIS", "ar": "هدية مجانية"},
	"NEXT_GIFT": {"en": "Next gift %s", "fr": "Prochain cadeau %s", "de": "Nächstes Geschenk %s",
		"es": "Próximo regalo %s", "it": "Prossimo regalo %s", "ar": "الهدية التالية %s"},
	"YOU_GOT": {"en": "You got", "fr": "Tu as reçu", "de": "Du hast erhalten",
		"es": "Has recibido", "it": "Hai ricevuto", "ar": "حصلت على"},
	"CLAIM": {"en": "Claim", "fr": "Récupérer", "de": "Abholen",
		"es": "Recoger", "it": "Riscatta", "ar": "استلم"},

	# --- settings screen ---
	"SETTINGS": {"en": "Settings", "fr": "Paramètres", "de": "Einstellungen",
		"es": "Ajustes", "it": "Impostazioni", "ar": "الإعدادات"},
	"SECTION_AUDIO": {"en": "Sound & vibration", "fr": "Son et vibration", "de": "Ton & Vibration",
		"es": "Sonido y vibración", "it": "Suono e vibrazione", "ar": "الصوت والاهتزاز"},
	"SECTION_LOOK": {"en": "Look & language", "fr": "Apparence et langue", "de": "Aussehen & Sprache",
		"es": "Apariencia e idioma", "it": "Aspetto e lingua", "ar": "الشكل واللغة"},
	"SECTION_GAME": {"en": "Gameplay", "fr": "Jeu", "de": "Spiel",
		"es": "Juego", "it": "Gioco", "ar": "اللعب"},
	"BACK": {"en": "Back", "fr": "Retour", "de": "Zurück",
		"es": "Volver", "it": "Indietro", "ar": "رجوع"},
}


static func next(code: String) -> String:
	var i := LANGS.find(code)
	return LANGS[(i + 1) % LANGS.size()]


## Best supported language for a device locale like "fr_CA" (else English).
static func from_locale(locale: String) -> String:
	var code := locale.substr(0, 2).to_lower()
	return code if LANGS.has(code) else "en"
