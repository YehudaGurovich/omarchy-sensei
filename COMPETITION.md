# Omarchy Plugin Competition — entry data

## Facts

- Announcement: https://omarchy.org/news/2026/08/the-first-plugin-competition/
- Deadline: **Monday, August 24, 2026, 09:00 CEST** — plugin must be listed on
  the marketplace before this time.
- Prizes: $2,500 / $1,000 / $500. Judged by the Omarchy Core Team ("may the
  best ideas and execution win"). Winners announced by Friday, August 28.
- Payment: Zelle, Venmo, PayPal, or EU IBAN.

## Submission

Submit through the marketplace issue form:
https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml

Requirements (from SUBMISSION.md of the marketplace repo):

- One **public** GitHub repository
- `manifest.json`, `README.md`, and a license file
- Choose a category and 1–3 tags

Planned listing:

- Category: **Productivity**
- Tags: `learning`, `keybindings`, `onboarding`
- Optional after listing: request automated verification
  (https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/new?template=verify-plugin.yml)

## Checklist before submitting

- [x] Walkthrough engine works end to end (verified on this machine; a pristine-default VM run was not done — bind resolution reads the live config by design)
- [x] 8–12 polished lessons, welcome tour chains the basics (10 lessons, all verified)
- [x] `omarchy plugin validate` passes
- [x] Fresh install test: installed and smoke-tested from the public GitHub URL
- [x] `preview.png` (welcome tour with spotlight) in the repo
- [x] README install command matches the final repo URL
- [x] Version 1.0.0, repo public
- [ ] Submitted via the marketplace form
