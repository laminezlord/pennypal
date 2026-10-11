# SRS improvement pass — 11 Oct 2026

Changes made after a full manual test of the web build against the PennyPal SRS.
A copy of the project before these changes is in
`../PennyPal_BACKUP_before_SRS_pass_2026-10-11`, and the project folder is now a
git repository (`git log` / `git diff` show exactly what changed).

> **AI acknowledgement:** these changes were made with the help of an AI coding
> assistant (Claude Code). The SRS requires AI tools to be acknowledged in the
> project documentation, and judges may ask you to explain the code, so review
> each change below before submission.

## Data bugs fixed
- **Older records disappeared after a reload.** Lists were read from the local
  Firestore cache whenever it held anything. They now load from the server and
  use the cache only when offline or when the server is slow (`_safeQuery`).
- **Deleting a transaction did not delete it in Firestore.** Every transaction
  uses an `offline_…` id, and delete treated that prefix as "local only". Delete
  now removes the queued copy and the cloud document (`deleteTransaction`).
- Queued copies that already reached the cloud are no longer listed twice.
- Lists stayed stale after save/edit/delete on web (post-frame refreshes waited
  for the next user interaction). New helper: `afterNextFrame` in `penny_widgets.dart`.
- Tabs now reload when opened (`refreshSignal` on Activity, Budget, Goals, Learn).

## SRS gaps closed
| SRS requirement | Change |
|---|---|
| Income with source, amount, date, description | Income form has a **Source** list and a date picker; income is no longer saved as "Food" |
| Expense with category, amount, date, description | Date picker added to the expense form |
| History search and filter by date, category, type | Search fixed; **month filter** and "Clear filters" added |
| View, edit and delete records | Edit dialog also edits the date and has a **Delete** button (swipe is hard with a mouse or screen reader) |
| Update or delete an existing budget | "Remove this limit" in the budget editor; alert threshold (50–90%) selectable |
| Show remaining budget and overspending clearly | "₦X left" / "Over budget by ₦X", colour-coded bars |
| Dashboard quick navigation to Budget, History, Learning, Feedback, Support | Added to Quick actions (plus Reports) |
| Dashboard message when there is no data | Shown when income, expenses and budget are all empty |
| Learning topics: budgeting, saving, income, necessary/optional expenses | Six built-in lessons (`services/core_lessons.dart`), shown alongside admin lessons |
| Goals: current savings, remaining amount, history of completed goals | "Saved so far" field, "₦X to go", **Goal history** section, delete confirmation |
| Registration: password rules, mobile, duplicate accounts | Mobile format and letter+number password checks; friendly Firebase error messages |
| Reports | This month / All time switch, insight sentence, fixed monthly chart axis |
| Accessibility | Semantic labels on charts, quick actions and transactions; errors announced as live regions |

## Smaller fixes
- Validation errors now appear inside bottom sheets (they were hidden behind them).
- Negative money shows as `-₦57,800.00` instead of `₦-57,800.00`.
- Assistant receives this month's spending per category and active goals, and
  is asked for plain text without Markdown symbols.
- Deprecated `withOpacity` calls replaced.

## Still to do before submission
- Test on a real iPhone / iOS simulator (needs a Mac).
- Admin account testing (no admin login was available during this pass).
- Release APK, SQL scripts, MP4 demo and the written report (SRS 1.9).
