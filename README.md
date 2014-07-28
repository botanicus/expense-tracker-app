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

# Implementation Notes

- Normally I'd put API on a separate subdomain. I think it's a good practise especially considering we always return the app.html (unless it's under /api/).
