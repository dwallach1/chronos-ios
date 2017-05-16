# Chronos 

This project is meant to be a proof-of-concept IoT based system. This project models an automated alarm system based on when the
user enters and exits their home.

# How It Works

1. The user downloads the iOS application that tracks their location and notifies the system when the user 
	enters or exits thier home. The user is able to input their home address and update their sleeping preferences in order to let the system better determine their wake up time.

2. The system will be using ngrok to expose our local server (local host 5000) to the web to allow our iOS application to post location events to the system. 

3. The inner system will be running on Flask to execute a python module (chronos.py) to then check the user's Google calendar and see their events for the next day and set their alarm based on their schedule as well as user defined preferences. 

4. The python module generates two wav files: (1) a wake file to trigger Alexa to litsen and (2) a content file with command for Alexa. It then sends the audio of these files from the computer to the Echo. Here the Echo plays the files, firstly the wake file, which triggers the Echo to begin litsening. It then plays the second file (the command) which tells Alexa what to do.


# Limitations

Because Amazon does not support 3rd party applications accessing Echo's alarms, this project had to be implemeneted in a very hackish manner. I hope that soon Amazon allows its users more access to the core of the Echo's to make them more programmable. This project would be able to be run easily on a Raspberry Pi running Pylexa or something of that sort, however, I wanted to develop a project that utilzed the traditional Echo. 


# To Do