REPLACE_ACTION_TEXT silke ~ReputationInc(-2)~ ~ReputationInc(-1) AddExperienceParty(400)~

ADD_TRANS_TRIGGER ~marl~ 6 ~CheckStatGT(LastTalkedToBy,14,CHR)~ DO 2

ADD_TRANS_TRIGGER ~marl~ 12 ~PartyGoldGT(14)~ DO 0
ADD_TRANS_ACTION ~marl~ BEGIN 12 END BEGIN 0 END ~TakePartyGold(15)~


REPLACE_ACTION_TEXT karlat ~Enemy()~ ~Enemy() ActionOverride("tb#kar01", Enemy()) ActionOverride("tb#kar02", Enemy())~


