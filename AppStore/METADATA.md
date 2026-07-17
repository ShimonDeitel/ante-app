# Ante - App Store metadata (v2)

App ID: 6791556912 | Bundle: com.shimondeitel.ante | SKU: ante001

## Name (30 max)
Ante - Pay to Wake

## Subtitle (30 max)
The alarm with real stakes

## Category
Primary: Lifestyle. Secondary: Health & Fitness.

## Keywords (100 max)
alarm,wake up,snooze,accountability,habit,early,riser,challenge,money,bed,grass,water

## Promotional text (170 max)
Set the stakes, prove you did the task, AI checks it instantly. Skipping costs you the ante you chose. The alarm that finally makes snoozing expensive.

## Description
Ante is an alarm clock with skin in the game.

Every night you have an ante on the table: a fixed amount you chose, from one dollar to ten thousand. When the alarm rings, you have one job: complete the task you picked (make your bed, get outside, or drink a glass of water) and show it to the camera. Ante's AI checks your photo instantly - no setup photo, no reference shot, just the real thing, every morning. Pass, and the alarm is settled and your ante is safe.

Stop the alarm without checking in, and the ante is forfeit. Want to snooze? That has a price too, and you set it yourself - charged the moment you tap it.

HOW IT WORKS
- Sign in with Apple. Your stakes and history sync privately across your own devices via iCloud.
- Pick your task: make your bed, touch grass, or drink water.
- Set your wake time and the days it repeats.
- Choose your stakes from a fixed list: the fine for skipping, and the cost of each snooze.
- When the alarm rings, do the task and photograph it. Pass the AI check and you're done, free.
- Stop the alarm without passing the check, and the app collects the fine you agreed to.

YOUR PHOTOS AREN'T KEPT
Each task photo is analyzed to produce a pass/fail result, then discarded - never stored by Ante.

TRACK THE HABIT
Streaks, mornings kept, and every dollar you've forfeited, laid out plainly and synced across your devices.

Ante is for adults (18+) only, and requires you to read and explicitly agree to the Terms of Use - which state plainly that charges are final and non-refundable - before your first stake takes effect.

## Review notes
Ante uses AlarmKit (iOS 26) for its alarm and requires Sign in with Apple to create an account (real-money charges need an identity to attribute them to). To test: sign in with any Apple ID (or a Sandbox Apple ID), complete onboarding including reading and checking the Terms of Use / Privacy Policy consent box (the "I Agree" button stays disabled until it's checked), set a wake time 2-3 minutes ahead, let the alarm fire, then either tap "I'm Up" and photograph a real example of the chosen task (an AI vision check judges the photo, no setup/reference photo needed), or stop the alarm without checking in and observe the app blocks on a pay-the-fine screen the next time it's opened - this is enforced by the app itself (a local deadline check), not by anything AlarmKit runs automatically, since Apple's alarm framework does not invoke app code when its own Stop button is tapped. Payments in this build are processed by a clearly-labeled sandbox processor; no real card is ever charged. Contact: Shimon Deitel, +972533495227, s0533495227@gmail.com.

## URLs
Privacy: https://shimondeitel.github.io/ante-app/privacy.html
Terms: https://shimondeitel.github.io/ante-app/terms.html
Marketing: https://shimondeitel.github.io/ante-app/
Support: https://shimondeitel.github.io/ante-app/

## App Privacy
Data collected: none stored by Ante's own servers. Task photos are transmitted to an on-demand verification service for a single pass/fail judgment and are not retained. Settings/history sync via the user's own private iCloud account (Ante's operator cannot read it). Sign in with Apple identifier used only for account/sync. Update the App Privacy questionnaire in ASC accordingly before resubmitting v2 (previous submission was "Data Not Collected", which is no longer accurate now that photos leave the device for AI verification, even though nothing is stored).

## Age rating
18+ (unrestricted web access: NO; gambling: NO - fixed self-imposed fines, no chance element, no winnings; frequent/intense: none). App is real-money accountability, not gambling: no chance, no payout, deterministic consequence of the user's own action.

## Copyright
2026 Shimon Deitel

## Content rights
Does not use third-party content.

## Pricing
Free (the fines are real-money charges through the app's own payment processor when live; ships with sandbox processor and no IAP).
