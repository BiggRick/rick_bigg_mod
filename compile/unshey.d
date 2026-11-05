
REPLACE_SAY unshey 1 ~Have you heard? There's a rogue ogre with a belt fetish to the south of the Friendly Arm Inn. I had to bargain my lucky girdle for my life out there. Wasn't even interested in an autographed copy of my book. Hey, if you can get that belt back to me, I'd be mighty grateful.~

REPLACE_STATE_TRIGGER unshey 2 ~  !NumTimesTalkedTo(0) !PartyHasItem("BDBELT01")~
REPLACE_STATE_TRIGGER unshey 4 ~PartyHasItem("BDBELT01") ReactionLT(LastTalkedToBy,FRIENDLY_LOWER)~
REPLACE_STATE_TRIGGER unshey 5 ~PartyHasItem("BDBELT01") ReactionGT(LastTalkedToBy,NEUTRAL_UPPER)~
REPLACE_ACTION_TEXT unshey ~TakePartyItem("BELT04")~ ~TakePartyItem("BDBELT01")~