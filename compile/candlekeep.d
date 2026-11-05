REPLACE_TRANS_TRIGGER ~nobw4~ BEGIN 0 END BEGIN 3 END ~ReactionLT(LastTalkedToBy(Myself),FRIENDLY_LOWER)~ ~CheckStatLT(LastTalkedToBy, 15, CHR)~
REPLACE_TRANS_TRIGGER ~nobw4~ BEGIN 0 END BEGIN 4 END ~ReactionGT(LastTalkedToBy(Myself),NEUTRAL_UPPER)~ ~CheckStatGT(LastTalkedToBy, 14, CHR)~

REPLACE_STATE_TRIGGER ~fuller~ 5 ~CheckStatGT(LastTalkedToBy, 16, CHR) Global("HelpFuller","GLOBAL",2)~
REPLACE_STATE_TRIGGER ~fuller~ 6 ~CheckStatLT(LastTalkedToBy, 17, CHR) Global("HelpFuller","GLOBAL",2)~

ADD_TRANS_TRIGGER ~poghm4~ 0 ~CheckStatGT(LastTalkedToBy, 15, CHR)~ DO 1
EXTEND_BOTTOM ~poghm4~ 0
    IF ~CheckStatLT(LastTalkedToBy, 16, CHR)~ REPLY ~Yes, that would be nice of you.~ GOTO poghm4_nope
END

APPEND ~poghm4~
    IF ~~ THEN poghm4_nope
    SAY ~You are not a good liar. Go play with your friends and leave me to my job.~
    IF ~~ THEN EXIT
    END
END
