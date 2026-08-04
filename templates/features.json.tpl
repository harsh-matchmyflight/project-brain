{
  "_rules": [
    "An agent may only flip 'passes' from false to true.",
    "It may do so only after running the 'verify' command and seeing it pass.",
    "Never edit 'description'. Never delete an entry. Never set 'passes' back to false to make a task look done.",
    "This file is JSON deliberately: models overwrite markdown far more readily than JSON."
  ],
  "features": [
    {
      "id": "example-feature",
      "area": "payments",
      "description": "A logged-in user can complete a checkout with a saved card",
      "steps": [
        "log in as a user with a saved card",
        "add an item and go to checkout",
        "submit with the saved card",
        "order appears in history with status 'paid'"
      ],
      "verify": "npm test -- checkout",
      "passes": false
    }
  ]
}
