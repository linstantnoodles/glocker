Initial workflow:

glocker ls # Shows all tickets in the backlog
glocker cb 1 -t chore # Creates your branch with formatted branch name
glocker cpr # Creates # Creates a pull request with formatted title. Fill in body and save (uses git template if it exists)


Okay, so the jira bullshit is too annoying to work with. Here's the new workflow:

glocker new-branch ticket-link
# fetches all the data it needs to make PR

Next:
update
* Automate glocking in when you SSH into the branch and glock out when you're done (or can be called speciically). Each is a session basically.
