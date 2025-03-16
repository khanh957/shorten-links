# Shorten Links Service

## Introduction

Welcome to Shorten Links Service, a service that allows creating short links and using them to go to the original link

## Features
- API to create short links
- API to retrieve original links
- Automatically redirect short links to original URLs
- Use Redis to cache frequently accessed links for faster performance
- Background job to remove expired links older than one month

## Potential attack vectors
- Attackers can create phishing or malware links
    Solution:
    + Allows users to report malicious websites and add to blacklist
    + Implement domain whitelist
    + Create a warning pages before redirection
- Spam Attack
    Solution:
    + Limit link creation per IP

## Scalability
- create user to be able to save their shortcode

### Conflicts When Creating Short URLs
Difficult to choose the best way to create short codes.
- SecureRandom, nanoid: length can be customized but if config length is too short then may be duplicated if there is already a lot of short code in the future
- UUID: length too long
- Snowflake: Difficult to apply, not easy to read, and maintain the code

Current:
- Create short code column in database as unique
- Use ID (auto increment) + Random String + Base62 Encoding to create short code
- If ActiveRecord::RecordNotUnique occurs, retry generating a new code
Advantages: short code is short, almost impossible to duplicate because it's using a unique ID
Disadvantages: slower than others because it's using one more query to get ID from database

### Scalability
- create user to be able to save their shortcode

## Prerequisites

Before you get started, make sure you have the following software and tools installed on your system:

### When Using Docker (Recommended):

- **Docker:** Version 20.10.16 or higher.
- **Docker Compose:** Version 1.29.2 or higher.

### When Not Using Docker:

If you prefer not to use Docker, you'll need to install the following software and tools manually:

- **Ruby:** Version 3.2.2.
- **Ruby on Rails:** Version 7.0.7.2.
- **Bundler:** Version 2.4.10.

Make sure to install these dependencies with the specified versions to ensure compatibility with the application.

## Installation & Configuration

Step-by-step instructions for cloning the repository, installing dependencies, and configuring settings.
* Clone the GitHub repository:
```
git clone https://github.com/khanh957/shorten-links.git
cd shorten-links
```

### Docker Deployment (Recommended):
All you need to do is run the following command and wait until everything is launched
`docker-compose up --build`

* To run the test suite:
`docker-compose exec backend rspec`

### When Not Using Docker:
**Setup Service:**
```
bundle install
```

## Database Setup
```
rails db:create
rails db:migrate
```

## Running the Application

How to start the development server, access the application in a web browser, and run the test suite.
`rails server -p 3000`

* To run the test suite:
```
cd backend
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate
RAILS_ENV=test rspec
```

## Usage

### Get short links
Send request to

URL: http://localhost:3000/encode
Method: POST
Content-Type: application/json
Request Body:
```
{
    "short_url": {
        "original_url": "https://example.com",
        "custom_short_code": "test123",
        "expired_at": "2025-03-20 19:58:38.753"
    }
}
```
- original_url (required): The original URL to be shortened
- custom_short_code (optional): Custom short code for the shortened link (if not provided, the system will generate it)
- expired_at (optional): Expiration date of the shortened link (default is no expiration)

Response:
```
{
    "short_url": "http://localhost:3000/test123"
}
```

### Get original links
Send request to

URL: http://localhost:3000/decode
Method: POST
Content-Type: application/json
Request Body:
```
{
    "url": "http://localhost:3000/test123"
}
```

Response:
```
{
    "original_url": "https://translate.google.com/?sl=en&tl=vi&op=translate"
}
```

### Using short links

Just copy and paste the short link to the browser
