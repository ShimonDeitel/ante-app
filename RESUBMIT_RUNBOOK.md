# Ante resubmission runbook (after Apple upload limit resets)

State as of 2026-07-16 ~17:45 UTC:
- Enforcement fix is committed (d1c1b9c) and PROVEN by AnteUITests e2e (TEST SUCCEEDED).
- Fixed dev build is on the owner's iPhone.
- ASC upload of the fixed binary hit error 90383 "Upload limit reached... wait 1 day"
  (account-wide daily cap, burned by the wider app factory).
- Review submission 3ddc9879 (broken build 1) was CANCELED deliberately - the review
  notes tell the reviewer to exercise exactly the flow build 1 fails at; letting it
  reach review risked a 3-strikes rejection.

To finish (one pass, ~30 min of waiting, after ~2026-07-17 17:30 UTC):
1. gh workflow run release.yml --repo ShimonDeitel/ante-app --ref master
2. Wait for run success, then poll until the new build is VALID:
   GET /v1/builds?filter[app]=6791556912 (ascf.py helper, key SSJA634V44)
3. Attach new build to version 1.0 (75a59c65-9aad-49d2-b3ef-d5b9af0a2ab3):
   PATCH /v1/appStoreVersions/{ver}/relationships/build
4. Assign the build to TestFlight group "Owner" (5f7ac189-...):
   POST /v1/betaGroups/{group}/relationships/builds
5. Create reviewSubmission (platform IOS) + reviewSubmissionItem (the version) +
   PATCH submitted=true.
6. VERIFY: GET /v1/apps/6791556912/reviewSubmissions shows WAITING_FOR_REVIEW and
   the build shows VALID/not expired. Never trust the submit call alone.

All metadata/screenshots/privacy/age-rating/pricing are already done and survive
the cancellation untouched.
