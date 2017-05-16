from __future__ import print_function
from flask import Flask 
import httplib2
import os

from apiclient import discovery
from oauth2client import client
from oauth2client import tools
from oauth2client.file import Storage

import datetime
from dateutil import parser
import time
import subprocess

from gtts import gTTS
from pydub import AudioSegment
import wave
import random


__author__ = "David Wallach"
__license__ = "MIT"


app = Flask(__name__)

"""
Run this program whenever the user leaves or enters their home triggered by companion iOS application

Start Flask at local port 5000 (default) by running this module
Run "ngrok http 5000" to broadcast the local port 
configure iOS app settings to use the ngrok port 
"""

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
    textToWav('alexa_command', text)
    # tts = gTTS(text= text, lang='en')
    # tts.save("alexa_command.wav")
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
    prep_time = user_prefs['prep_time']
    latest_time = user_prefs['latest_time']

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

# ---------------------
#
# GOOGLE CALENDAR API
#
# ----------------------

try:
    import argparse
    flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None

# If modifying these scopes, delete your previously saved credentials
# at ~/.credentials/calendar-python-quickstart.json
SCOPES = 'https://www.googleapis.com/auth/calendar.readonly'
CLIENT_SECRET_FILE = 'client_secret.json'
APPLICATION_NAME = 'Wally'


def get_credentials():
    """
    Gets valid user credentials from storage.

    If nothing has been stored, or if the stored credentials are invalid,
    the OAuth2 flow is completed to obtain the new credentials.

    Returns:
        Credentials, the obtained credential.
    """
    home_dir = os.path.expanduser('~')
    credential_dir = os.path.join(home_dir, '.credentials')
    if not os.path.exists(credential_dir):
        os.makedirs(credential_dir)
    credential_path = os.path.join(credential_dir,
                                   'calendar-python-quickstart.json')

    store = Storage(credential_path)
    credentials = store.get()
    if not credentials or credentials.invalid:
        flow = client.flow_from_clientsecrets(CLIENT_SECRET_FILE, SCOPES)
        flow.user_agent = APPLICATION_NAME
        if flags:
            credentials = tools.run_flow(flow, store, flags)
        else: # Needed only for compatibility with Python 2.6
            credentials = tools.run(flow, store)
        print('Storing credentials to ' + credential_path)
    return credentials

def get_user_prefs():
    """
    Gets users preferences from AWS database  
    
    Returns:
     a dictionary representing the JSON object
    """
    # Make call to API
    # get JSON object

    ## For now, use hardcoded 
    prefs = dict()
    prefs['latest_time'] =  datetime.time(10, 0, 0)#datetime.strptime('10:00', '%H:%M').time()
    prefs['max_time_hr'] = 9
    prefs['max_time_min'] = 30
    prefs['prep_time'] =  datetime.time(1, 0, 0) #datetime.strptime('1:00', '%H:%M').time()
    return prefs

def trigger_communication(events, arriving=False):
    # Condition: user is arriving home
    # Set alarm based on the user preferences
    if not events:
        return 
    first_event = events[0]['start'].get('dateTime', events[0]['start'].get('date'))
    user_prefs = get_user_prefs()
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

def get_events():
    credentials = get_credentials()
    http = credentials.authorize(httplib2.Http())
    service = discovery.build('calendar', 'v3', http=http)

    now = datetime.datetime.utcnow().isoformat() + 'Z' # 'Z' indicates UTC time
    print('Getting the upcoming 10 events')
    eventsResult = service.events().list(
        calendarId='primary', timeMin=now, maxResults=10, singleEvents=True,
        orderBy='startTime').execute()
    events = eventsResult.get('items', [])

    if not events:
        print('No upcoming events found.')
        return 
    for event in events:
        # times are based on the 24 hour clock cycle
        start = event['start'].get('dateTime', event['start'].get('date'))
        print(start, event['summary'])

    return events


@app.route("/Run", methods=['POST'])
def main():

    """
    Triggered when the user either enters or exitis home location.

    If the user enters: set the alarms for the next day based on Google Calendar events
    and user preferences  
    """
    
    # arriving = request.args.get("status")
    # Step 1: get user's events for next day from Google Calendar API 
    events = get_events()


    # Step 2: configure wake audio file
    textToWav('alexa_wake', 'Hey Alexa,')

    # Step 3: generate voice message & communicate with Alexa 
    # trigger_communication(events)
    trigger_communication(events, arriving=False)

    rand_name = str(random.random()) + str(random.random()) + str(random.random()) + str(random.random())
    file = open(rand_name,”w”) 
    file.write("worked arriving was " + str(arriving))
    file.close()
    


if __name__ == '__main__':
    app.run(debug=True)
    # main()