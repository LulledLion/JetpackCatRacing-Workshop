var Hero;
let Project = {
        null: [],
        "jetpackCat": ["dsc.gg/jetpack", "TSB2M", "jetpackcat.racing"],
        "shion": [],
        "doomfist": ["dsc.gg/projectmomentum", "NAPGF", "doom.pk"],
        "genji": ["dsc.gg/genjiparkour", "54CRY", "genji.pk"],
        "lucio": ["discord.com/invite/G9QBCDY", null, "luciosurfleague.com"],
        "mercy": ["discord.gg/mercyparkour", null, "mercyparkour.codes"],
    }
let ProjectHero = Project[Hero in Project? Hero : null]
let Result = `
enum Hero:
	JETPACKCAT = Hero.JETPACK_CAT,
    JUNKERQUEEN = Hero.JUNKER_QUEEN,
    WRECKINGBALL = Hero.WRECKING_BALL,

enum Racer:
    Hero = Hero.${Hero.toUpperCase()}
    String = "${Hero}"
    StringLC = "${Hero.toLowerCase()}"
    StringUC = "${Hero.toUpperCase()}"
    Discord = "${ProjectHero[0] ?? ''}"
    ShareCode = "${ProjectHero[1] ?? 'XXXXX'}"
    Website = "${ProjectHero[2] ?? ''}"
`;
Result;