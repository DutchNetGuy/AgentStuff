# How the author uses it

The author runs a personal assistant called Jarvis on top of Claude Code. This is how the cockpit is set up there. Adapt it to your own environment.

## Serving

The site is served by an nginx container on the author's own network. It is not reachable from outside. Pages are plain static files, so the access rule is the network boundary and nothing else.

## When something becomes a page

A skill tells the agent when to publish a page instead of answering in the chat. The threshold is about 1500 characters, or any comparison, table or report. Below that, the answer stays in the chat. The same skill lists the readability classes and says which one to use for what, so the agent does not have to guess.

## Look before you link

Jarvis renders every page to a screenshot first and looks at it before it gives the link. A page that reads fine as source can still have a table that overflows or a diagram that is cut off. The check happens before the user ever sees the page.

## The list as memory

The list of pages doubles as a record of what was decided. When a topic comes back, the page that holds the earlier decision is one click away, newest first. The agent does not have to reconstruct it from a long chat.

## What went wrong at first

- An output style was tried before the browser channel. It changed how the agent answered, which is why the channel stayed separate.
- Early pages had no manifest. The reader needed the URL of each page; the list came one day after the first pages.
