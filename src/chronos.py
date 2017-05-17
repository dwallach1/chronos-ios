"""

Run this program whenever the user leaves or enters their home triggered by companion iOS application
Start Flask at local port 5000 (default) by running this module
Run "ngrok http 5000" to broadcast the local port 
configure iOS app settings to use the ngrok port 
"""
__author__ = "David Wallach"
__license__ = "MIT"


from flask import Flask, request, jsonify
import httplib2
import os

from chronos_calendar import get_events

import datetime
from dateutil import parser
import time
import subprocess

from gtts import gTTS
from pydub import AudioSegment
import wave

import random
import json


app = Flask(__name__)




# -------------------
#
#   Wav File Manipulation
#
# --------------------

def speak(fname):
    # rewriteWav(fname)
    # increase_vol(fname)
    os.system("afplay alexa_wake.wav")
    os.system("afplay "+ fname)


def increase_vol(fname):
    os.system("afplay "+ fname)
    speech = AudioSegment.from_wav(fname)
    speech = speech + 10 # add 10 db to boost volume 
    speech.export(fname, format="wav")
    os.system("afplay "+ fname)

def textToWav(fname, text, alarm_time=None):
    if alarm_time:
        time = parser.parse(alarm_time)
        starter = 'Alexa, please set alarm at '
        if time.minute < 10:
            alarm_time =  str(time.hour) + ':' + '0' + str(time.minute) + ' ' + 'am'
        else:
            alarm_time =  str(time.hour) + ':' + str(time.minute) + ' ' + 'am'
        print ("setting alarm time to ", alarm_time)
        text = starter + alarm_time

    subprocess.call(["espeak", "-w"+fname+".wav", text])

# This is gotten from resepaker library --
# we want to emulate this save as wav for our text to voice 
#
#  can we change the current 
def save_as_wav(data, prefix):
    prefix = prefix.replace(' ', '_')
    filename = prefix + '.wav'
    f = wave.open(filename, 'wb')
    f.setframerate(22050)
    f.setsampwidth(2)
    f.setnchannels(1)
    f.writeframes(data)
    f.close()
    print ('Save audio as %s' % filename)


def get_bytes_of_wav(fname):
    __location__ = os.path.realpath(
    os.path.join(os.getcwd(), os.path.dirname(__file__)))
    path = os.path.join(__location__, fname)
    with open(path, 'rb') as fd:  # open the file    
        data = fd.read()
        h = [b for b in data]
    return h



def change_samplerate(infile, outfile):
    NEW_SAMPLERATE = 16000
    old_samplerate, old_audio = wav.read(infile)

    duration = old_audio.shape[0] / old_samplerate

    time_old  = np.linspace(0, duration, old_audio.shape[0])
    time_new  = np.linspace(0, duration, int(old_audio.shape[0] * NEW_SAMPLERATE / old_samplerate))

    interpolator = interpolate.interp1d(time_old, old_audio.T)
    new_audio = interpolator(time_new).T

    wav.write(outfile, NEW_SAMPLERATE, np.round(new_audio).astype(old_audio.dtype))
    print ("saved file as ",outfile)

def amplify(infile, outfile):
    from scipy.io.wavfile import read, write 
    from scipy.fftpack import rfft, irfft 
    import numpy as np 
    rate, input = read(infile) 
    transformed = rfft(input) 
    output = irfft(transformed) 
    write(outfile, rate, output) #- See more at: http://www.joinphp.com/content/nptnllqt-rfft-or-irfft-increasing-wav-file-volume-in-python.html#sthash.D0N2dKEH.dpuf


def rewriteWav(fname):
    b = get_bytes_of_wav(fname)
    print (b)
    b_str = ''.join(b)
    print (b_str)
    save_as_wav(b_str, fname[:len(fname)-4]) # take off thw .wav part
    # save_as_wav(b_str, 'alexa_command_2')



# -----------------------
#
#   Alarm manager 
#   
# -----------------------
# class ChronosManager:
#     def __init__(self, preferences, alarm_time, home):
#         self.preferences = preferences
#         self.alarm_time = alarm_time





def alarm_manager(time, delete=False):
    """
    takes in a time object (either datetime.date() or datetime.time()) and creates an mp3 
    file with the correct saying for alexa and also tells the computer to say it out loud

    Returns:
        True if successful, otherwise False 
    """
    if delete:
        starter = 'Alexa, please delete alarm at '
    else:
        starter = 'Alexa, please set alarm at '
    
    unit_number = {0: 'zero', 1: 'one', 2: 'two', 3: 'three', 4: 'four', 
           5: 'five', 6: 'six', 7: 'seven', 8: 'eight', 9: 'nine'}

    teen_number = {11: 'eleven', 12: 'twelve', 13: 'thirteen', 14: 'fourteen', 15: 'fifteen', 
           16: 'sixteen', 17: 'seventeen', 18: 'eighteen', 19: 'nineteen'}

    big_number =  {2: 'twenty', 3: 'thirty', 4: 'fourty', 5: 'fifty'}

    if time.minute == 0:
        alarm_time =  unit_number[time.hour] + ' a m tomorrow' 
    elif time.minute < 10:
        alarm_time =  unit_number[time.hour] + ' oh ' + unit_number[time.minute] + ' a m tomorrow' 
    elif time.minute < 20 and time.minute > 10:
        alarm_time =  unit_number[time.hour] + ' ' + teen_number[time.minute] + ' a m tomorrow' 
    else:
        alarm_time =  unit_number[time.hour] + ' ' + big_number[time.minute / 10] + ' ' + unit_number[time.minute - ((time.minute/10)*10)] + ' ' + 'a m tomorrow'
    print ("setting alarm time to ", alarm_time)
    text = starter + alarm_time
    # textToWav('alexa_command', text)
    tts = gTTS(text= text, lang='en')
    tts.save("alexa_command.wav")
    speak("alexa_command.wav")
    return alarm_time

def is_after(time1, time2):
    """
    takes two datetime.time() objects and checks if time time1 occurs after time2

    Returns:
        true if time1 > time2, otherwise false 
    """
    if time2.hour < time1.hour:
        return True
    if time1.hour == time2.hour and time1.minute > time2.minute:
        return True 
    return False

def sub_time(time1, time2):
    """
    subtracts two times. Needs to convert time1 to a datetime object of today() with the correct time
    and then substracts the hours and minutes of time2 

    Returns:
        datetime object of today() with the time of time1 - time2
    """
    return datetime.datetime.combine(datetime.date.today(), time1) - datetime.timedelta(hours=time2.hour, minutes=time2.minute)

def schedule_alarm(first_event, user_prefs):
    """
    Develops the MP3 recording to send to alexa to set the Alarm
    
    Returns:
        two variables: bool, val |=> true if successful and the time, otherwise false and None
    """
    first_event = parser.parse(first_event) # convert to datetime for comparisons
    prep_time = user_prefs['prefered_preptime']
    latest_time = user_prefs['max_wakeup_time']

    # Case 1: first event minus prep time is past latest_time --> wake up latest_time 
    event_minus_prep_time = sub_time(first_event.time(), prep_time)
    if is_after(event_minus_prep_time.time(), latest_time):
        return latest_time

    # Case 2: event time minus prep time is before latest time --> wake up at event minus prep time
    if is_after(latest_time, event_minus_prep_time.time()):
        return event_minus_prep_time
    
    # Case 3: first event is before latest time --> wake up at event time minus prep time 
    if is_after(latest_time, first_event.time()): 
        return event_minus_prep_time

    return None # if we get here, something went wrong



@app.route("/Prefs/", methods=['POST'])
def set_user_prefs():
    """
    Gets users preferences from AWS database  
    
    Returns:
     a dictionary representing the JSON object
    """
    # Make call to API
    # get JSON object

    keys = ['prefered_sleep_hrs', 'prefered_preptime', 'min_preptime', 'max_wakeup_time']
    defaults = True
    prefs = dict()
    try:
        prefs = request.json
        print(prefs)
        for k in keys:
            prefs[k] = datetime.datetime.strptime(json[k], '%H:%M %p').time()
        print ('prefs are ',prefs)
        defaults = False
    except:
        pass

    # Use defaults
    if defaults:
        print ('using default preferences')
        prefs['max_wakeup_time'] =  datetime.datetime.strptime("10:00 AM" , '%H:%M %p').time()
        prefs['prefered_sleep_hrs'] =  datetime.datetime.strptime("09:00 AM" , '%H:%M %p').time()
        prefs['prefered_preptime'] = datetime.datetime.strptime("01:00 AM" , '%H:%M %p').time()
        prefs['min_preptime'] = datetime.datetime.strptime("00:30 AM" , '%H:%M %p').time()

    PREFERENCES = prefs
    return "Updated user preferrences: Success!"

# def convert_prefs(pref_dict):
#     for key in pref_dict.keys():
#         pref_dict[key] = datetime.datetime.strptime(json[k], '%H:%M %p').time()


def trigger_communication(events, arriving=False):
    # Condition: user is arriving home
    # Set alarm based on the user preferences
    if not events:
        return 
    first_event = events[0]['start'].get('dateTime', events[0]['start'].get('date'))
    set_user_prefs()
    # convert_prefs(user_prefs)
    user_prefs = PREFERENCES
    time = schedule_alarm(first_event, user_prefs)  
    if not time:
        print ('Error setting time -- aborting mission')
        return 
    if arriving:  
        alarm_manager(time)
        print ("alexa successfully set alarm at", time)
    else:
        # Condition: user is leaving home
        alarm_manager(time, delete=True)
        print ("alexa successfully deleted alarm at", time)


PREFERENCES = None 

@app.route("/Run", methods=['GET'])
def main():

    """
    Triggered when the user either enters or exitis home location.

    If the user enters: set the alarms for the next day based on Google Calendar events
    and user preferences  
    """
    s = request.args.get("status")        

    if int(s) == 0:
        status = False
    elif int(s) == 1:
        status = True
    elif int(s) == 3:
        print ("iOS synchronization test Successful")
        # status = False
        return s
    else:
        print ("Unkown GET Request")
        return -1


    # Step 1: get user's events for next day from Google Calendar API 
    events = get_events()


    # Step 2: configure wake audio file
    # textToWav('alexa_wake', 'Hey Alexa,')
    tts = gTTS(text= 'Hey Alexa', lang='en')
    tts.save("alexa_wake.wav")


    # Step 3: generate voice message & communicate with Alexa 
    # trigger_communication(events)
    trigger_communication(events, arriving=status)

    rand_name = "validation_" + str(random.random()) + str(random.random()) + str(random.random()) + str(random.random())
    file = open('validation/'+rand_name,'w') 
    file.write("worked arriving was " + str(status) + '\n' + str(datetime.datetime.now()))
    file.close()

    return status
    

if __name__ == '__main__':
    app.run(debug=True)
    # main()