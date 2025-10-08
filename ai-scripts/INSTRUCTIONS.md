#Context
You are an expert programmer and need to provide a React Native application to manage a Bluetooth LED display.
The brand of these displays is CoolLED, and the model we are using is CoolLEDU (it is very important to remember the model we are using)
The display comes in different sizes and provides Bluetooth connectivity
We are currently using a 96x16 display, but eventually can use other sizes
The display manufactuer has a mobile app called CoolLED1248 that provides all possible functions supported by the display
You have access to the manufacturer's source code for their CoolLED1248 native app (both iOS and Android)
The app should be able to send images to the display via Bluetooth
The protocol for interacting with the display is complex, so being able to send content to the display is the most critical aspect of the project

#Resources
- Display specs (in particular section 12.3): ./CoolLEDU-V1.0-2.pdf
- CoolLED1248 iOS app: ./CoolLED1248_IOS-release
- CoolLED1248 Android app: ./CoolLED1248_Android 

#Requirements 
The app name is "mobill-drivers" and the working directory for the app should be this directory, and the bundle identifier is "com.mobill.drivers"
You should use this current directory as the app root directory
You should study how CoolLED1248 iOS and CoolLED1248 Android connect and communicate with the displays
You should create native libraries for managing the display 
You should reuse (copy) as much code as possible from CoolLED1248 to the native library
Both native libraries (iOS and Android) should have a common interface so the React Native code is common to both platforms
This common interface's core functionality should be connecting/disconnecting to/from the display, and for sending programs to the display
It should support all programs provided by the display, and all of the features supported by the programs

#Plan
##Step 1
Read the display's specs document 
Fully understand how the CoolLED1248 app works (inspect both apps, iOS and Android)
Define which classes from CoolLED1248 you will need to reuse (remember, reuse as much code as possible)
Create the React Native app structure for the mobill-drivers app
Create the iOS native library
Create the Android native library
Create the common React Native interface
Provide a simple app (one screen) with one Test screen to test the native library
This app should have two buttons:
  1. A button to connect/disconnect
  2. A button that sends a simple program of type graffiti with one single image in static mode

