# How the author uses it

The author runs a personal assistant called Jarvis on top of Claude Code. This is how presenting-decisions is set up there. Adapt it to your own environment.

## The owner reads only the table

The owner often runs two or three agent sessions at the same time. They switch between them, skim, and read the table rather than the text around it. That is why every decision has to stand on its own: when they land on a session, the table is the one thing they need to read.

## The start-up overview uses the format

At the start of a session Jarvis gives a "where were we" overview of the open points from the previous session. That overview is given in this format. Each point carries a ticket number, a title, what is going on and a proposed next step, so it can be understood without the previous session in mind. Before presenting it, Jarvis checks the open points against the current state of the repository and the tracker, because a session log may have been written halfway through the session and be out of date.

## Large decisions become a page

When a decision needs more than about 1500 characters of explanation, the table row stays compact and the detail goes on a separate page, published through the cockpit package in this catalog. The row points to the page. The same threshold decides when a drawing is added, together with the rule for routes between three or more parties.

## The answer is recorded on the ticket

After the owner answers, Jarvis writes the decision and the reason as a comment on the ticket. A decision that only lives in the chat is lost as soon as the session ends, and the next session would ask the same question again.

## Numbering runs through a session

Numbers do not restart and tables are not re-posted. A new decision gets the next number, and an unanswered one is referred to as "decision #3 is still open". That keeps the number meaningful when the owner returns after an hour with other sessions in between.

## What went wrong at first

- Questions were phrased as bare lines, so the owner had to ask for context.
- Options were packed into one cell and could not be read.
- The advice said "agree", which only repeated the question.
- Partial tables were sent while reports were still coming in, and then re-posted in a different shape.

Each of these is now a rule or a line in the skill's list of common mistakes.
