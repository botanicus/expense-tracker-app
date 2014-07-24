# Requirements

- ✔ User must be able to create an account and log in.
- ✔ User should be able to create an account in the system via an interface, probably a signup/register screen.
- ✔ You need to be able to pass credentials to both the webpage and the API.
- ✔ In any case you should be able to explain how a REST API works and demonstrate that by creating functional tests that use the REST Layer directly.
- ✔ You need to login to the application to enter expenses.
- ✔ When logged in, user can see, edit and delete expenses he entered.
- ✔ When entered, each expense has: datetime, description, comment.
- ✔ User can filter expenses.
- ✔ User can print expenses per week with total amount and average day spending.

# Implementation Notes

- Normally I'd put API on a separate subdomain. I think it's a good practise especially considering we always return the app.html (unless it's under /api/).
