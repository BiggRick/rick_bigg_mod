ADD_TRANS_ACTION ~vai~ BEGIN 6 END BEGIN END
    ~SetGlobal("tb#vaiLeft","GLOBAL",1)~

REPLACE_STATE_TRIGGER ~vai~ 5 ~OR (2)  PartyHasItem("misc86") PartyHasItem("tb#scalp")~

APPEND ~vai~

    IF WEIGHT #0 ~Global("tb#collectInnocentScalps","GLOBAL", 2) !PartyHasItem("MISC86") !PartyHasItem("tb#scalp") GlobalGT("Chapter","GLOBAL",3)~
    BEGIN vaiAngry
    SAY ~Did you take me for a fool? You killed innocents and sold me their scalps as if they were common bandits'! I sentence you to death.~
    IF ~~ DO ~Enemy() SetGlobal("tb#vaiLeft","GLOBAL",1)
            CreateCreature("FLAMPUN",[-1.-1],S)
            CreateCreature("FLAMPUN2",[-1.-1],S)
            CreateCreature("FLAMPUN2",[-1.-1],S)
            CreateCreature("FLAMSCO",[-1.-1],S)
            CreateCreature("FLAMWIZ",[-1.-1],S)
            ~ EXIT
    END
END