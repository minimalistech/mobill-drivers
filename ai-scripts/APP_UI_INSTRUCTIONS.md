Now that we have the critical display management working, we need to put together the mobill drivers app ui.

This UI has four screens for which you can find screenshots under the folder /Users/juan/tmp/mobill-drivers-rn/mockups, files landing.png, login.png, access-location.png and home.png.
The first screen the users sees is the one specified in landing.png. This screen has a login button which takes you to the login screen.

The login screen is specified in login.png. This screen allows users to login to the app. To perform login, you need to send the credentials
in a json as a POST to https://api.mobill.com/api/v1/users/login which returns a “refresh” and “access” token.
To refresh the access token you should provide the refresh token to the endpoint https://api.mobill.com/api/v1/users/token/refresh
The login screen should only show up when there is no refresh token or when a new it fails to refresh it.

After login, the user gets the screen specified in access-location.png. This screen triggers the permission to use location in the background.
Users need to allow this in order to continue.
Always show the location screen if access to location has not been granted
Once the user grants access to location in background, then do not show the location screen again

After allowing permission to use location, the user gets to the Home Screen, specified in the file home.png. This is the main screen.
On this screen the user can turn the display on, which triggers the connection with the LED display using the DisplayManager functionality.
When successfully connected to the display the button turns to “Turn off the display”.
Once the display is turned on, you should start a background process that runs every 15 seconds.
This process invokes the endpoint https://api.mobill.com/api/v1/core/serve_ad where you should use the token provided at login to authenticate the call by using the Authentication header and setting it to “Bearer <token>”.
This endpoint expects geolocation coordinates. 
This endpoint returns a json with details that should be used to setup the content on the display through the DisplayManager.
This json also contains todays earnings and this month’s earning, which should be displayed in the two boxes below the Turn on/off button.
The background process should continue running even when the app is in the backgound.
The backgound process should be terminated when the user turns off the display.
For now the serve_ad returns an imageUrl so we should use that as contentUrl for an image program, and use the following settings:
displaySize: { width: 96, height: 16 }
programType: 'image'
templateMode: 'full'
mode: 9
speed: 5
stayTime: 150

Use the image /Users/juan/tmp/mobill-drivers-rn/MobillDrivers/images/landing_logo.png for the landing screen
Use the image /Users/juan/tmp/mobill-drivers-rn/MobillDrivers/images/home_logo.png for the Home Screen
Use the image /Users/juan/tmp/mobill-drivers-rn/MobillDrivers/images/home_background_on.png when the display is connected
Use the image /Users/juan/tmp/mobill-drivers-rn/MobillDrivers/images/home_background_off.png when the display is disconnected
Use the color #1E1E1E for the background of all screens

Please use a correct React Native project structure, maybe have a file for each screen under the src folder. And maybe App.tsx should not have any UI.

API ENDPOINTS:
User Login
- **Endpoint**: `POST /api/v1/users/login`
- **Purpose**: Authenticate user and obtain access/refresh tokens
- **Request Body**:
  ```json
  {
    "username": "user@example.com",
    "password": "user_password"
  }
  ```
- **Success Response**:
  ```json
  {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  }
  ```

Token Refresh
- **Endpoint**: `POST /api/v1/users/token/refresh`
- **Purpose**: Refresh expired access token using refresh token
- **Request Body**:
  ```json
  {
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  }
  ```
- **Success Response**:
  ```json
  {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  }
  ```


Ad Serving (Critical Endpoint)
- **Endpoint**: `GET /api/v1/core/serve-ad`
- **Purpose**: Retrieve location-targeted advertisement for display
- **Authentication**: Required (Bearer token)
- **Query Parameters** (optional):
  - `latitude`: Current GPS latitude (decimal degrees)
  - `longitude`: Current GPS longitude (decimal degrees)
- **Example Request**: `GET /api/v1/core/serve-ad?latitude=37.7749&longitude=-122.4194`
- **Success Response**:
  ```json
  {
    "image_url": "https://cdn.mobill.com/ads/campaign_123/ad_456.png",
    "ad_id": "ad_456",
    "campaign_id": "campaign_123",
    "display_duration": 15,
    "driver_earnings": {
      "today": "25.75",
      "this_month": "651.00"
    }
  }
  ```
