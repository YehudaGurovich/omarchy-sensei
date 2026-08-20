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

- [ ] Walkthrough engine works end to end on a default Omarchy install
- [x] 8–12 polished lessons, welcome tour chains the basics (10 lessons, all verified)
- [ ] `omarchy plugin validate` passes
- [ ] Fresh install test: `omarchy plugin add <repo-url> --enable` on a clean setup
- [ ] `preview.png` (screenshot or short GIF-derived frame) in the repo
- [ ] README install command matches the final repo URL
- [ ] Version bumped, repo public, submitted via the form
