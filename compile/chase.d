BEGIN CHASE

IF "True()" THEN CHASE_START
SAY "Hello... well... I was about to tell you not to come any closer, but that never seems to work, does it? Well, regardless, I should remain true to the genre. Don't come any closer or I'll JUMP! Yeah, you heard me, and I'll do it, too! So... don't come any closer... again. And don't try to stop me!"
IF "" THEN REPLY "Okay." GOTO CHASE_OK
IF "CheckStatLT(LastTalkedToBy, 15, CHR)" THEN REPLY "No, by all the gods do not do such a thing! There is so much to live for!" GOTO CHASE_NOTJUMP
IF "CheckStatGT(LastTalkedToBy, 14, CHR)" THEN REPLY "No, by all the gods do not do such a thing! There is so much to live for!" GOTO CHASE_NOTJUMP_REWARD
IF "CheckStatLT(LastTalkedToBy, 17, CHR)" THEN REPLY "By all means, jump if you must. More air for the rest of us." GOTO CHASE_JUMP_NOPE
IF "CheckStatGT(LastTalkedToBy, 16, CHR)" THEN REPLY "By all means, jump if you must. More air for the rest of us." GOTO CHASE_JUMP_REALLY
END

IF "" THEN CHASE_NOTJUMP
SAY "You're right, of course. What a fool I was to think this would solve anything. It didn't solve anything the last time I stood here and was stopped, nor the time before that. I really should develop a better method of dealing with adversity. It's such a long walk as well. Hmm, perhaps if I had mumsey construct a cliff closer to town. Ah well, thanks for your concern. Ta."
IF "" THEN DO "EscapeArea()" EXIT
END

IF "" THEN CHASE_NOTJUMP_REWARD
SAY "You're right, of course. What a fool I was to think this would solve anything. It didn't solve anything the last time I stood here and was stopped, nor the time before that. I really should develop a better method of dealing with adversity. It's such a long walk as well. Hmm, perhaps if I left you this bag of coins the journey would be lighter."
IF "" THEN DO "GivePartyGold(90) AddExperienceParty(300) EscapeArea()" EXIT
END

IF "" THEN CHASE_JUMP_NOPE
SAY "HOW could you be so CALLOUS? I am so obviously in PAIN here! Have you no care for MY needs? No, of course not. No one does. Not Mumsey, not Daddums, not Jeeves. I bet they'd be glad I was gone. If fact, I'd probably be doing them a favor! That's it, I'll stay alive just to spite them! I'll be the most miserable, selfish, upstart of a child! Actually, this won't be much of a change, but now I'm justified! Life is good."
IF "" THEN DO "EscapeArea()" EXIT
END

IF "" THEN CHASE_JUMP_REALLY
SAY "HOW could you be so CALLOUS?" = "I am so obviously in PAIN here!" = "Have you no care for MY needs?" = "No, of course not." = "No one does." = "My life is worth nothing!" = "Not even Mumsey will listen to me!" = "Why nobody cares for me!" = "I must jump!" = "Goodbye cruel world."
IF "" THEN DO "Kill(Myself)  AddExperienceParty(300)" EXIT
END

CHAIN CHASE CHASE_OK
"Okay...? You aren't going to do a thing? Wow. You... you must have incredible faith in my will to live. No one has ever shown such trust in me, not ever! Not even mumsey! Thank you so much for your quiet faith! I choose to live! I CHOOSE TO LIVE! Oh, no! I have to get home before mumsey finds the note! She has no stomach for such things. I'll have Jeeves double her usual cocktails and tell her of my new resolve! Thank you so much. Tra la! Life is grand once again!"
== IMOENJ IF %IsValidForPartyDialogue("Imoen")% THEN "What a tool."
END
IF "" THEN DO %ActionOverride("Chase",EscapeArea())% EXIT
