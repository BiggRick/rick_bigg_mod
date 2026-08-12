BEGIN TB#SCALP

IF ~Global("tb#collectInnocentScalps","GLOBAL", 0)
    PartyHasItem("tb#scalp")~ THEN startscalp
    SAY ~You have collect innocents' scalps. Do you want to try to pass them off as bandit scalps to Officer Vai?~
    IF ~~ THEN REPLY ~Yes, she will never be able to tell.~ DO ~SetGlobal("tb#collectInnocentScalps","GLOBAL", 2)~ EXIT
    IF ~~ THEN REPLY ~No, I don't want to risk angering the law.~ DO ~SetGlobal("tb#collectInnocentScalps","GLOBAL", 1)~ EXIT
END

