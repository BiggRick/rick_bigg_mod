ADD_TRANS_TRIGGER ~AOLN~ 2 ~CheckStatLT(LastTalkedToBy,15,CHR)~
REPLACE_STATE_TRIGGER ~AOLN~ 0 ~NumTimesTalkedTo(0) Global("tb#AolnEscort","GLOBAL",0)~

EXTEND_BOTTOM ~AOLN~ 2
  IF ~CheckStatGT(LastTalkedToBy,14,CHR)~ REPLY ~I could use the help. What do you think about traveling with me to the Friendly Arm?~ GOTO tb#aoln_escort
  IF ~CheckStatGT(LastTalkedToBy,14,CHR)~ REPLY ~Thanks for the warning. Farewell.~ GOTO tb#aoln_leave
END

APPEND ~AOLN~
  IF ~Global("tb#AolnAfterTarnesh","GLOBAL",1)~ THEN BEGIN tb#aoln_after_tarnesh
    SAY ~It seems your life is far more interesting than what I bargained for. I wish you luck.~
    IF ~~ THEN DO ~SetGlobal("tb#AolnAfterTarnesh","GLOBAL",2) SetGlobal("tb#AolnEscort","GLOBAL",4) EscapeArea()~ EXIT
  END

  IF ~Global("tb#AolnEscort","GLOBAL",0) NumTimesTalkedToGT(0)~ THEN BEGIN tb#aoln_retalk
    SAY ~It was nice talking to you.~
    IF ~~ THEN DO ~EscapeArea()~ EXIT
  END

  IF ~!Global("tb#AolnEscort","GLOBAL",0) AreaCheck("BG2700")~ THEN BEGIN tb#aoln_retalk_follow
    SAY ~On to the Friendly Arm Inn.~
    IF ~~ THEN EXIT
  END

  IF ~!Global("tb#AolnEscort","GLOBAL",0) AreaCheck("BG6100")~ THEN BEGIN tb#aoln_retalk_follow
    SAY ~Life on the road is never boring, am I right?~
    IF ~~ THEN EXIT
  END

  IF ~AreaCheck("BG2300") Global("tb#AolnEscort","GLOBAL",2) Global("tb#AolnAfterTarnesh","GLOBAL",0)~ THEN BEGIN tb#aoln_at_fai
    SAY ~Here we are, Friendly Arm Inn. Let's head inside, I could use a warm bath for once...~
    IF ~~ THEN DO ~SetGlobal("tb#AolnEscort","GLOBAL",3)
      Ally()~ EXIT
  END

  IF ~~ THEN BEGIN tb#aoln_escort
    SAY ~I normally don't travel with strangers, but you look really wet behind your ears; it would not do to leave you to die by yourself.~
    IF ~~ THEN DO ~SetGlobal("tb#AolnEscort","GLOBAL",1)
      Ally()~ EXIT
  END

  IF ~~ THEN BEGIN tb#aoln_leave
    SAY ~Aye. Travel safely, then.~
    IF ~~ THEN DO ~EscapeArea()~ EXIT
  END
END

