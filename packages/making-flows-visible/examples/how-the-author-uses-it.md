# How the author uses it

The author runs a personal assistant called Jarvis on top of Claude Code. This is how the flow board is used there. Adapt it to your own environment.

## Two boards, one framework

There are two boards built from the same page code and generator.

- **The home-lab board** describes the flows between the owner and the agents: a firewall change and publishing a package to this catalogue. It is the leading version. The package here is a generalised copy of it, with the two flows in the model rewritten in English and stripped of names.
- **The work board** describes the flows of a department: who knows which system, where requests wait, which dependency has a single expert. Its data stays private. Only the page code and the generator are copied there from the home-lab board.

Never mix the data of the two. The rule is that frameworks and knowledge travel between them, data does not.

## One direction for changes

Changes to `index.html` and the generator are made once, on the leading board. They are then copied to the work board and to this package, and the board version in the footer says which copy you are looking at. This is what keeps the copies from drifting apart.

## How a flow gets on the board

1. The owner tells the story of a flow in plain words, including the waiting.
2. The agent turns that into a flow file, with hours as estimates and the source of each estimate written down. An estimate is fine as long as it says it is one.
3. The generator checks the files. Errors name the file and the place, so the agent fixes them without asking.
4. The agent renders the page to a screenshot and looks at it before giving the owner the link.
5. The owner reads the red marks first: those are the dependencies only one person or agent knows.

## What it showed

- Ten of the seventeen dependencies of the two home-lab flows had exactly one knower: six the owner, four the agent. Knowledge held only by the agent is a risk in its own right, because it lives in instructions that nobody else reads.
- The waiting steps, mostly for a decision or a review by the owner, were by far the largest part of the lead time. The owner's own time was a small part.

## What went wrong at first

- The first page had its texts hard-coded in one language. Adding a translation table later was cheap, but only because all texts were first moved into one object.
- Early dependencies were named after products. Generic names read better on the board and survive a change of product.
