# Usage

## Working with The API Server

```
cd server
bundle
```

### Running the API Server

```
./config.ru
```

### Running API Tests

_For this you need to have the API server running._

```
bundle exec rspec
```

### Using The Web Interface

Go to the [app](http://localhost:5000/).

# Requirements

- List expenses per week.
- created_at -> createdAt
- Extract middlewares into gems.
- Tests.

# Implementation Notes

- Normally I'd put API on a separate subdomain. I think it's a good practise especially considering we always return the app.html (unless it's under /api/).

# This is not a typical way people usually
# write tests in Ruby. I'm a strong believer
# in integration tests though. I'm very pleased
# that you guys included it as a requirement!
