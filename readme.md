Chronos | Wally | Apollo | Sage
An IoT System Making your Amazon Alexa Smarter


#Overview
The components for the project consist of an iOS application, light sensor and the AWS backend. The purpose of the project is to determine when a user goes to sleep and trigger the AWS backend to use cloud logic to determine when the user's first event for the next day is and set an alarm accordingly. The system will adhere to a set of rules based on input regarding the users prefrences such as how long it takes them to get ready, latest time they want to wake up and more. 


#Requirements

	* Xcode 7 and later
	* iOS 8 and later
	* Amazon Alexa 
	* Light Sensor

#Work Flow
The user downloads the iOS application and inputs their home address. The application tracks it and updates a variable stored in the cloud that siginifies if the user is home or not. Each change is communicated using the AWS IoT MQTT device shadow API and then logic is applied. 

There are several cases:
	* if the user comes home + the lights detect a change from on to off state + it is past the threshold of possible bedtimes then the system will check the user's calendar and set the alarm
	* if the user comes home, but it is too early then the system waits until past the threshold time 


#To do 
We hope to store user's data in order to implement machine learning and have the system better adhere to each indiviudal user. Furthermore, we are looking into developing better protocol for determining when the user is in a sleep state. 


# Developer Notes

We need to trigger Alexa through voice, this seems to be the biggest hurdle for the proposed Chronos system. 

	"Alexa sends your skill a JSON message with the user’s intent and your code answers with a JSON message that determines what Alexa will answer to the user."

For this to work, we are going to use googles python library gTTS (google text to speach) wich will generate an mp3 file that we will send to Alexa to emulate the action of the user speaking to it. 