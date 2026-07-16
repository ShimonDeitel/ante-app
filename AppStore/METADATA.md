# Ante - App Store metadata

App ID: 6791556912 | Bundle: com.shimondeitel.ante | SKU: ante001

## Name (30 max)
Ante - Pay to Wake

## Subtitle (30 max)
The alarm with real stakes

## Category
Primary: Lifestyle. Secondary: Health & Fitness.

## Keywords (100 max)
alarm,wake up,snooze,bed,morning,routine,accountability,habit,early,riser,challenge,money

## Promotional text (170 max)
Set the stakes, make your bed, prove it to the camera. Skipping costs you the ante you chose. The alarm that finally makes snoozing expensive.

## Description
Ante is an alarm clock with skin in the game.

Every night you have an ante on the table: an amount you chose, from one dollar to a thousand. When the alarm rings, you have one job: make your bed and show it to the camera. Ante compares your photo to your own reference photo entirely on your device and, if it matches, the alarm is settled and your ante is safe.

Stop the alarm without checking in, and the ante is forfeit. Want to snooze? That has a price too, and you set it yourself.

HOW IT WORKS
- Take one reference photo of your made bed during setup.
- Set your wake time and the days it repeats.
- Choose your stakes: the fine for skipping, and the cost of each snooze.
- When the alarm rings, make your bed and photograph it. Pass the on-device check and you are done.
- Stop the alarm without passing the check, and the app collects the fine you set.

YOUR PHOTOS STAY YOURS
Bed photos are analyzed with Apple's on-device Vision framework. Nothing is uploaded, ever.

TRACK THE HABIT
Streaks, mornings kept, and every dollar you have forfeited, laid out plainly. The forfeit total is designed to be a number you want to keep small.

Ante is for adults (18+). You configure every amount before it can ever be charged, and you can change or disable the stakes at any time in Settings.

## Review notes
Ante uses AlarmKit (iOS 26) for its alarm. To test: complete onboarding (take any photo as the reference, e.g. of a bed or the room), set a wake time 2-3 minutes ahead, let the alarm fire, then either tap "I'm Up" and photograph the same scene (passes and silences), or stop the alarm and observe the app requests settlement of the user-configured fine on next open. Payments in this build are processed by a clearly-labeled sandbox processor; no real card is ever charged. Contact: Shimon Deitel, +972533495227, s0533495227@gmail.com. No sign-in required.

## URLs
Privacy: https://shimondeitel.github.io/ante-app/privacy.html
Terms: https://shimondeitel.github.io/ante-app/terms.html
Marketing: https://shimondeitel.github.io/ante-app/
Support: https://shimondeitel.github.io/ante-app/

## App Privacy
Data not collected (all processing on-device; sandbox payments store nothing off-device in v1).

## Age rating
18+ (unrestricted web access: NO; gambling: NO - fixed self-imposed fines, no chance element, no winnings; frequent/intense: none). Rating questionnaire: all "None", then set age 17+/18+ via the simulated gambling question set to None but "mature themes" none; use 4+ questionnaire results BUT mark app as 18+ via Age Rating override if available. App is real-money accountability, not gambling: no chance, no payout.

## Copyright
2026 Shimon Deitel

## Content rights
Does not use third-party content.

## Pricing
Free (the fines are real-money charges through the app's own payment processor when live; v1 ships with sandbox processor and no IAP).
