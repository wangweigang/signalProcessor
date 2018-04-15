""" align.py
    testing steering model, watch data from other apps through file in disk, and process the data from saved datafile
    steering stuff and watching running data inspired from 
    https://cs.iupui.edu/~aharris/pygame/ch09/carVec.py http://engineeringdotnet.blogspot.de/2010/04/simple-2d-car-physics-in-games.html
    and other sources.
    Works with Python 3.4.4
    Built / created by W. Wang in 12.2017
"""
    
import pygame
import numpy as np
#import csv
import collections as cln
import random
import os, sys, time
#import threading
import argparse
#import re
#import watchLog as wf
import win32file
import win32con

parser = argparse.ArgumentParser(prog='align', description='Process some results from positioning test, created by Weigang.')
parser.add_argument("-v", "--verbosity",   action="count",   default=0,                                    help="increase help verbosity and exit")
parser.add_argument("-N", dest='ctrlPar',  action="store",   default='0', type=int, choices=[0, 1, 2],     help='Control parameter to processing mode: 0: test steering model; 1: process data from CANOE real-time recordings; 2: postprocess data from simulation, CAN bus, etc.')
parser.add_argument('-f', dest='dataFile', action="store",   default='.\\data\\rssi.txt', help='Data file (S-format) to be processed')
parser.add_argument('-n', dest='nameUnit', action="store",   default='.\\data\\NameUnit.xls',              help="Header of the dada file")
parser.add_argument('-s', dest='scale',    action="store",   default='1', type=float,                      help="Scaling / zooming around the center region of the window")
parser.add_argument('--version',           action='version', version='%(prog)s 1.0')

args = parser.parse_args()

# set up data file
controlParGlbl = args.ctrlPar
# 0: manual
# 1: read log file from CANOE log file "secondaryLocation.asc"
# 2: read file in Soti format


dataFileDefault = r'.\data\rssi.txt'
#print(args.dataFile, "\n",dataFileDefault, args.dataFile==dataFileDefault, args.dataFile is dataFileDefault)
if controlParGlbl == 0:
    data2Process = ''
    print("\nStarting align to check steering model ... ...")
elif controlParGlbl == 1:
    if args.dataFile == dataFileDefault:
        path2WatchGlbl = r".\canoeData" # look at the current directory
        file2WatchGlbl = "test.asc" # look for changes to a file called test.asc
        data2Process   = os.path.join(path2WatchGlbl, file2WatchGlbl)
    else:
        data2Process   = args.dataFile
    print("\nStarting align to watch a running data ... ...")
    print("\nData to be processed: ", data2Process)
elif controlParGlbl == 2:
    if args.dataFile == dataFileDefault:
        data2Process   = dataFileDefault
    else:
        data2Process   = args.dataFile
    print("\nStarting align to process positioning results ... ...")
    print("\nData to be processed: ", data2Process, "\n")

    
#print('\ncontrolParGlbl=',controlParGlbl, '\ndata2Process=',data2Process)
#sys.exit()

if args.verbosity >= 1:
    print("\n'align' processes the positioning data in ASCII format; the data is arranged", 
          "\n        in column format without header. The data can be from CANOE recording,",
          "\n        positioning data from other simulations, etc. The processing includes",
          "\n        animation, statistics and more from future versions.",
          "\n        If applicable (-N 0 or no option),",
          "\n           - arrow keys: move / turn the vehicle",
          "\n           - r: reset the vehicle",
          "\n           - b: brake the vehicle",
          "\n           - q: exit from the programst\n",
          "\n        Created in 12.2017 by W. Wang\n")
    sys.exit()



# distinguish code in development or edvelped: for exe generation
if getattr(sys, 'frozen', False):
    CurrentPath = sys._MEIPASS
else:
    CurrentPath = os.path.dirname(__file__)

scale           = args.scale

# global setup
scaleGeoGlbl    = scale * 0.04                # 25 (=1/0.04) pixel/mm for key driven
scaleGeoGlbls   = scale * scaleGeoGlbl * 10   # pixel/cm fro Soti's data
scale4Car       = 0.04                        # for sec and car relative distance

offsetSecGlbl   = -1450   #-900          # mm offset in y steering of oru center to wheel (car) center

indexGlbl       = 0             # index to control redraw trail. need to declare global if assignment in a function

lineCounterGlbl = 0             # count the line read from running data file

# setup screen
os.environ['SDL_VIDEO_WINDOW_POS'] = '2,30' # window top-left corner
widthScreen     = int(350*2)
heightScreen    = int(500*2)
screenGlbl      = pygame.display.set_mode((widthScreen, heightScreen))
screenCntrGlbl  = (0,0) 
background      = pygame.Surface(screenGlbl.get_size())
background.fill((244, 244, 244))

screenGlbl.blit(background, (0, 0))
        

# start pygame
pygame.init()


# deal with log reading
if controlParGlbl == 1:
#    path2WatchGlbl = r"H:\Projects\bomb\Me\canoe\Test" # look at the current directory
#    file2WatchGlbl = "secondaryLocation.asc" # look for changes to a file called test.txt
#    dataFile       = os.path.join(path2WatchGlbl, file2WatchGlbl)
#   Open the file we're interested in
    hOfFileGlbl = open(data2Process, "rb")

#   Throw away any exising log data
    #hOfFileGlbl.read()

    # Set up the bits we'll need for output
    ACTIONS = {
          1 : "Created",
          2 : "Deleted",
          3 : "Updated",
          4 : "Renamed from something",
          5 : "Renamed to something"
    }

    FILE_LIST_DIRECTORY = 0x0001

    hDirGlbl = win32file.CreateFile (
          path2WatchGlbl,
          FILE_LIST_DIRECTORY,
          win32con.FILE_SHARE_READ | win32con.FILE_SHARE_WRITE,
          None,
          win32con.OPEN_EXISTING,
          win32con.FILE_FLAG_BACKUP_SEMANTICS,
          None
    )



def waitAkey(): event = pygame.event.wait()
    
def getRunningData(objCar):
    global lineCounterGlbl
    
    dataFromFile = []
#   Wait for a change to occur. this part is literally wait there till change comes
    results = win32file.ReadDirectoryChangesW (
              hDirGlbl,
              1024,
              False,
              win32con.FILE_NOTIFY_CHANGE_LAST_WRITE,
              None,
              None
    )

    lineCounterGlbl += 1
    # print("results: ", results)
#   For each change, check to see if it's updating the file we're interested in
    for action, file in results:
#       full_filename = os.path.join (path2WatchGlbl, file)
        # print (hOfFileGlbl, file, lineCounterGlbl, file2WatchGlbl, ACTIONS.get (action, "Unknown"), results)
        if file == file2WatchGlbl:
            first        = hOfFileGlbl.readline()                   # Read the first line.
            # print ("aaa=", file, first)
            try:
                hOfFileGlbl.seek(-2, os.SEEK_END)                       # Jump to the second last byte.
                while hOfFileGlbl.read(1) != b"\n":                     # Until EOL is found...
                    hOfFileGlbl.seek(-2, os.SEEK_CUR)                   # ...jump back the read byte plus one more.
                lineLast      = hOfFileGlbl.readline().decode()         # Read last line.
                
    #            print("not eq: ", np.array_equal(dataFromFile, objCar.lastValue), dataFromFile, objCar.lastValue)
                        
                varTmp        = processData(lineLast)
                if len(varTmp) > 0:
                    varTmp[0:2]  = -np.array([varTmp[1],varTmp[0]]) * scaleGeoGlbls + screenCntrGlbl
                    positionSec  = np.array([varTmp[4],varTmp[3]])   # need to convert this oru position to vehicle position in screen unit ?????
                    carHeading   = np.deg2rad(varTmp[5])
                    
                    # varTmp1      = offsetSecGlbl * np.array([np.cos(carHeading-np.pi/2), np.sin(carHeading-np.pi/2)]) * scale4Car
                    varTmp[3:5]  = (positionSec*[1,-1]) * scaleGeoGlbls + screenCntrGlbl # - np.array(objCar.vehiRect.center)  # + varTmp1  # - np.array(objCar.vehiRect.center) 
                    varTmp[6:8]  = (np.array([varTmp[7],varTmp[6]])*[1,-1]) * scaleGeoGlbls + screenCntrGlbl     # ?????
                    dataFromFile = varTmp[0:9]
                    if not np.array_equal(dataFromFile, objCar.lastValue):
                        
                        objCar.posOfRef.append(varTmp[0:2])
                        
                        objCar.posOfSecPri.append(varTmp[3:5])
                        objCar.oriOfSecPri.append(carHeading)       # rads
                        objCar.pntOfRunning.append(positionSec)
                        
                        objCar.posOfSecSec.append(varTmp[6:8])
                       
                    objCar.lastValue = dataFromFile
            except OSError:
                continue    # do nothing this time and do next
                    
            # print("getRunningData: ", lineCounterGlbl, len(objCar.posOfRef), len(objCar.posOfSecPri), len(objCar.oriOfSecPri),len(objCar.posOfSecSec))
#            lineNew = hOfFileGlbl.read()
#            if lineNew != "":
#                dataFromFile = processData(lineNew)
#                break
        # time.sleep(1)
        # threading.Timer(2, objCar.checkControlKeys).start()  # not working
    return dataFromFile
    

def getPositionOrientation(dataFile):
# read Soti's data: first 9 columns (data format related)
#  0       1        2      3       4       5       6       7       8 
# xref    yref    tref    xpad    ypad    tpad    xoru    yoru    toru
# [cm]    [cm]    [°]     [cm]    [cm]    [°]     [cm]    [cm]    [°]
    
# note: data row shall be delimited with a single SPC
    
# coordinate converter
#    convertThem = [1,1,1,1,1,1,1,1,1]    
#                 xref yref tref xpad ypad tpad xoru yoru toru
    convertThem = [1,  1,   1,   -1,  -1,   1,   1,   -1,   1]    
    
    if dataFile:
        try:
            positionOrientation = np.loadtxt(dataFile, delimiter=" ", usecols=(0,1,2,3,4,5,6,7,8))
        except FileNotFoundError:
            print("\nError: Wrong file or file path and exit from align.")
            pygame.quit()
            sys.exit()
    else:
        positionOrientation = np.array([])
        
    return positionOrientation*convertThem
    

# define primary part
class AWC:
    
    def __init__(self, widthPri, lengthPri, widthSec, lengthSec):
        global indexGlbl
#        widthScreen  = screenGlbl.get_width()
#        heightScreen = screenGlbl.get_height()
#        self.screenCntr   = (int(widthScreen/2), int(heightScreen/2))
        rect            = screenGlbl.get_rect()
#        widthScreen     = rect.width
#        heightScreen    = rect.height

        # size
        self.sizePri    = (int(widthPri), int(lengthPri)) 
        self.sizeSec    = (int(widthSec), int(lengthSec))
        # center
        self.centerP    = (int(widthPri/2), int(lengthPri/2))
        self.centerO    = (int(widthSec/2), int(lengthSec/2))
        self.pntOnTrail = cln.deque(maxlen=333)

        indexGlbl       = 0
        self.centerSec  = [0,0]
        self.drawEvery  = 10
        self.counter    = 0
        self.posLast    = [-111111,-111111]
        self.posInt     = [0,0]

    def update(self, positionOrientationCar, vehiRect):
        # this is for trace drawing; also consider the image anchor offset
        # no need for case 1
        if controlParGlbl != 1:
            positionOrientationCar = np.array(positionOrientationCar)
            # varTMp  = offsetSecGlbl * np.array([np.cos(positionOrientationCar[2]-np.pi/2), np.sin(positionOrientationCar[2]-np.pi/2)])
            xyc     = (positionOrientationCar[0:2]*[1,-1]) * scaleGeoGlbl + screenCntrGlbl + vehiRect.center
    
            self.centerSec = (xyc)    
              
    def placeSecTraceFromPri(self, secCenter):   # for the real sec position and the position seen from Pri
        # here the physicalunit witll be scalled to pixels and shifted on the screen

        global indexGlbl    
        
        if controlParGlbl == 0:    # draw trace from key stroke action
            color = (255,0,0)
        elif  controlParGlbl == 2:
            color = (0,0,255)
        else:
            color = (0,0,255)
            self.drawEvery = 1
            
        self.counter += 1
        # draw / redraw the trail from the beginning again
        if indexGlbl < 1: 
            self.pntOnTrail.clear()
            indexGlbl = 1

        if self.counter == self.drawEvery:
            self.counter = 0
            self.posInt  = secCenter    # screen ready 
                
            # save only the point which is not same as the last
            if not np.array_equal(self.posInt, self.posLast):
                self.pntOnTrail.append(self.posInt)
        
        if len(self.pntOnTrail)>1:
            iii = len(self.pntOnTrail)           
            # print("placeSecTraceFromPri: ", iii, self.pntOnTrail[iii-1], secCenter)
            
            # print("placeSecTraceFromPri: ", self.pntOnTrail)
            pygame.draw.lines(screenGlbl, color, False, self.pntOnTrail, 2)
            
        self.posLast = self.posInt        


    def placeSecTraceFromSec(self, objCar):   # for the position seen from Sec
        # here the physicalunit witll be scalled to pixels and shifted on the screen
        # print("placeSecTraceFromSec: ", posOriSec.shape)
        if controlParGlbl != 1:
            if objCar.posOriSec.any():      # only draw trail seen from car monitor for controlParGlbl = 2, i.e. posOriSec is not empty
                positionScrn = (objCar.posOriSec[:,0:2]*[1,-1]) * scaleGeoGlbls + screenCntrGlbl
                pygame.draw.lines(screenGlbl, (0,255,0), False, positionScrn, 1)
        else:
            pygame.draw.lines(screenGlbl, (0,255,0), False, objCar.posOfSecSec, 1)
           
    def putPriOn(self):
        
        screenGlbl.fill((244, 244, 244))

        x     = screenCntrGlbl[0] - self.sizePri[0]/2   # 22 # 153
        y     = screenCntrGlbl[1] - self.sizePri[1]/2   # 40 # 201-44
        color = (188,188,188)
        pygame.draw.rect(screenGlbl, color, [x, y, self.sizePri[0], self.sizePri[1]])


        # shift the top-left corner a little
        x = x + self.sizePri[0]*0.02
        y = y + self.sizePri[1]*0.02

        color = (99,99,99)
        pygame.draw.rect(screenGlbl, color, [x, y, 0.95*self.sizePri[0], 0.95*self.sizePri[1]])
        # screenGlbl.set_alpha(90) not working


    def putSecOn(self):
        widthScreen  = screenGlbl.get_width()
        heightScreen = screenGlbl.get_height()
        
        x     = int(widthScreen/2) - 26 # 153
        y     = int(heightScreen/2) - 29 # 201-44
        color = (99,99,99)

        pygame.draw.rect(screenGlbl, color, [x, y, self.sizePri[0], self.sizePri[1]])

    
    
class Car:

    def __init__(self):
        global indexGlbl, screenCntrGlbl, lineCounterGlbl, imageMaster

        # Region of interest
        self.widthRoi    = 17500 / scale  # mm
        self.heightRoi   = 25000 / scale  # mm
        self.centerRoi   = (17500/2 *(0.04/scaleGeoGlbl) , 25000/2 * (0.04/scaleGeoGlbl))
        screenCntrGlbl   = (self.centerRoi[0] * scaleGeoGlbl, self.centerRoi[1] * scaleGeoGlbl)
        
        # imageFile        = resource_path(os.path.join(".", "cayenne05.png")) 
        self.imgVehicle   = imageMaster
        # Image parameters
        self.rectImgInit  = imageMaster.get_rect()
        self.vehiRectInit = self.rectImgInit
        self.vehiRect     = self.rectImgInit
        
        self.heightVehi   = imageMaster.get_width()
        self.widthVehi    = imageMaster.get_height()
        
        # screen parameters
        self.widthScreen  = screenGlbl.get_width()
        self.heightScreen = screenGlbl.get_height()
        screenGlbl.fill((244, 244, 244))
        #self.screenCntr   = (int(self.widthScreen/2), int(self.heightScreen/2))
        
        self.wheelBase   = 2840 # mm
        self.dt          = 0.01
        self.steering    = 0   
        self.turnRate    = 3 * scale
        self.accel       = 9800/200/scale   # mm/s/s
        # self.initX       = int(random.randrange(-22,22) + int(0.5*self.widthScreen-0.5*self.width))
        
        resetVehi(self)
                
        # steering decay
        self.steeringDecayMax = 30   # number of dt 
        self.steeringCounter  = 0
        self.returnRate       = 2 
        self.keyLeft          = False
        self.keyRight         = False
           
        #  
        indexGlbl             = 0
        self.secCenter        = np.array([])
        self.positionRef      = np.array([])
        self.steeringRef      = np.array([])
        self.positionPri      = np.array([])
        self.steeringPri      = np.array([])
        
        self.posOriSec        = np.array([])

        self.posOfRef         = cln.deque(maxlen=333)
        self.posOfSecPri      = cln.deque(maxlen=333)
        self.oriOfSecPri      = cln.deque(maxlen=333)
        self.posOfSecSec      = cln.deque(maxlen=333)
        self.pntOfRunning     = cln.deque(maxlen=333)
        self.lastValue        = np.array([])
        
        self.speedPrev        = 0
        self.carHeadingPrev   = 0
        self.steeringPrev     = 0
        if (controlParGlbl == 1) or (controlParGlbl == 2):
         
            positionOrientation   = getPositionOrientation(data2Process)
             
            # prepare the reference position/orientation for the background
            numOfPnt2Draw = 333
            if positionOrientation.size:
                # decimination
                [numOfRow,numOfCol] = positionOrientation.shape
                take4Every          = max(1, int(numOfRow/numOfPnt2Draw))
                
                if False:
                    # xref, yref, tref
                    self.positionRef    = -np.fliplr(positionOrientation[0:numOfRow:take4Every, 0:2]) # / scaleGeoGlbl * 10 + self.screenCntr 
                    self.steeringRef    = positionOrientation[0:numOfRow:take4Every, 2]    
    
                    # tpad, xpad, ypad: car with follow this path
                    thetaPri            = np.deg2rad(positionOrientation[:,5])     # need to be converted to carHeading
                    self.posOriPri      = np.fliplr(positionOrientation[:,3:5]) #     / scaleGeoGlbl * 10 + self.screenCntr   
                    self.posOriPri      = np.column_stack((self.posOriPri, thetaPri))
    
                    # toru, xoru, yoru
                    thetaSec            = np.deg2rad(positionOrientation[:,8])    # need to be converted to carHeading
                    self.posOriSec      = -np.fliplr(positionOrientation[:,6:8])   #                    / scaleGeoGlbl * 10 + self.screenCntr    
                    self.posOriSec      = np.column_stack((self.posOriSec, thetaSec))
                else:
                    # screen x= pad x; screen y = pad y
                    self.positionRef    = np.fliplr(positionOrientation[0:numOfRow:take4Every, 0:2])   
                    self.steeringRef    = positionOrientation[0:numOfRow:take4Every, 2]    
    
                    # tpad, xpad, ypad: car with follow this path
                    thetaPri            = np.deg2rad(positionOrientation[:,5])      
                    self.posOriPri      = np.column_stack((positionOrientation[:,4], positionOrientation[:,3], thetaPri))
    
                    # toru, xoru, yoru
                    thetaSec            = np.deg2rad(positionOrientation[:,8])               
                    self.posOriSec      = np.column_stack((-positionOrientation[:,7], positionOrientation[:,6], thetaSec))
                    
                    
                    
                    

                # store points in deque for case 1; need screen units because deque can not do vector manipulation
                if controlParGlbl == 1:
                    lineCounterGlbl = len(self.positionRef)

                    for i in range(0, lineCounterGlbl):
                        varTmp = (np.array(self.positionRef[i,:])*[1,-1]) * scaleGeoGlbls + screenCntrGlbl
                        self.posOfRef.append(varTmp)
                        
                        carHeading  = np.deg2rad(thetaPri[i])
                        # varTmp1     = offsetSecGlbl * np.array([np.cos(carHeading-np.pi/2), np.sin(carHeading-np.pi/2)]) * scale4Car
                        varTmp      = (np.array(self.posOriPri[i,0:2])*[1,-1]) * scaleGeoGlbls + screenCntrGlbl # - np.array(self.vehiRectInit.center) 
                        self.posOfSecPri.append(varTmp)     # this one is for car image
                        self.oriOfSecPri.append(self.posOriPri[i,2])
                        self.pntOfRunning.append(self.posOriPri[i,0:2])
                        
                        varTmp = (np.array(self.posOriSec[i,0:2])*[1,-1]) * scaleGeoGlbls + screenCntrGlbl
                        self.posOfSecSec.append(varTmp)

                #print("init: ",lineCounterGlbl, len(self.posOfSecPri), len(self.oriOfSecPri))
  

  
    def update(self): # for every frame of car class
    # get all the parameters (xpad, ypad, tpad) needed to draw car
    
        # self.vehiRect = self.imgVehicle.get_rect()   # get the last rectangule of the car images with rotation
 
        self.checkControlKeys()
        
        if controlParGlbl == 0:
        
            self.checkMoveKeys()
            #print("                              carKineK:", self.speed, self.accel, self.carHeading, self.steering)

            self.positionNew()
            
            self.checkBounds()  
            # self.posOriSecPri = np.array([self.position[0], self.position[1], self.carHeading])
            #                            mm                 mm              radian
            #  x                        pixel             pixel             radian
        
        elif controlParGlbl == 1: # driven by log file change
        
            # self.steering self.carHeading, self.speed, self.position
            dataFromFile = getRunningData(self)   # things are assigned in deques posOfRef, posOfSecPri, posOfSecSec
            self.positionNew()
            # self.posOriSecPri = np.array([])
            
        elif controlParGlbl == 2: # based on data file from positioning test
            self.positionNew()
#            self.checkBounds()  
            # self.posOriSecPri = [self.position[0], self.position[1], self.steering]
            #print("update: ", self.posOriSecPri)
        
 
        
    def positionNew(self):   # the position of the car's center
        # the assumption: the center of the car is   the same as the car image with any rotation
        # self.steering: steering angle related
        # self.carHeading: moving direction of the car
        global indexGlbl    

        if controlParGlbl == 0:

            # bicycle model
            radians1        = self.carHeading - np.pi/2
            #print("positionNew1=", self.position, self.wheelBase)
            frontWheel      = self.position + 0.5*self.wheelBase*np.array([np.cos(radians1), np.sin(radians1)])
    
            backWheel       = self.position - 0.5*self.wheelBase*np.array([np.cos(radians1), np.sin(radians1)])
            backWheel      += self.speed * self.dt * np.array([np.cos(radians1), np.sin(radians1)])
    
            radians         = (self.carHeading + self.steering*np.pi/180) - np.pi/2 
            frontWheel     += self.speed * self.dt * np.array([np.cos(radians), np.sin(radians)])
            
            self.position   = 0.5 * (frontWheel + backWheel)
            #print("positionNew2=", self.position, self.wheelBase)
    
            self.carHeading   = np.arctan2(frontWheel[0]-backWheel[0], -(frontWheel[1]-backWheel[1]))            
            # self.carHeading = -np.rad2deg(carHeadingRad)   # '-' is to work around the different range of rad2deg and rad2deg
#            print("positionNew: ", carHeadingDeg)

            #self.imgVehicle = pygame.transform.rotate(imageMaster, carHeadingDeg)  # carHeadingDeg>0 --> counterclockwise

                        
            # what I am checking?
            if (self.keyRight or self.keyLeft) and (self.steeringCounter<self.steeringDecayMax):
                self.steeringCounter += 1
                dirTemp               = self.steering
                self.steering         = self.steering - np.sign(self.steering)*self.returnRate
                if dirTemp*self.steering<0: self.steering = 0
            else:
                self.keyLeft          = False
                self.keyRight         = False
                self.steeringCounter  = 0
                self.steering         = 0

        elif controlParGlbl == 1:

           indexTmp        = len(self.oriOfSecPri)-1
           self.carHeading = self.oriOfSecPri[indexTmp]
           self.position   = self.posOfSecPri[indexTmp]       # cm xpad, xpad, 

           #carHeadingDeg   = self.oriOfSecPri[indexTmp]
           # print("positionNew: ",self.oriOfSecPri[indexTmp], carHeadingDeg)
           #self.imgVehicle = pygame.transform.rotate(imageMaster, carHeadingDeg)  # carHeadingDeg>0 --> counterclockwise
                
        elif controlParGlbl == 2:   # get position and orientation from fdata
#           Sec position seen from pad
            indexGlbl += 1
            index      = min(indexGlbl, len(self.posOriPri)-1)
            if index  >= len(self.posOriPri)-1:
                indexGlbl = 0
                print("Message: Redraw the vehicle track again ... ...")

            #print("positionNew: ", len(self.posOriPri),self.vehiRect.center)
# make sign change here????????????
            self.position   = self.posOriPri[index,0:2]                    # cm xpad, xpad, 
            self.carHeading = self.posOriPri[index,2]                      # tpad = 0 at the moment
        
            
       
    
    def drawCar(self, img):
        # here the physicalunit witll be scalled to pixels and shifted on the screen
        global indexGlbl
        
        if controlParGlbl == 0:
            
            indexGlbl    += 1
            indexGlbl     = min(indexGlbl,  2147483646)
            
            positionScrn  = (self.position*[1,-1])*scaleGeoGlbl + screenCntrGlbl
            carHeading    =  self.carHeading
            carHeadingDeg = -np.rad2deg(self.carHeading)   # '-' is to work around the different range of rad2deg and rad2deg
            # varTmp2       = offsetSecGlbl * np.array([np.sin(self.carHeading), np.cos(self.carHeading)]) * scale4Car
            varTmp2       = offsetSecGlbl * np.array([np.cos(carHeading-np.pi/2), np.sin(carHeading-np.pi/2)]) * scale4Car

            # print("drawCar: ",self.position*scaleGeoGlbls)
#           self.imgVehicle,newRect  = myRotate(self, imageMaster, carHeadingDeg)  # carHeadingDeg>0 --> counterclockwise            
            # self.vehiRect        = self.imgVehicle.get_rect(center=positionScrn + varTmp2) 
            self.imgVehicle      = myRotate(self, imageMaster, carHeadingDeg)  # carHeadingDeg>0 --> counterclockwise
            self.vehiRect.center = positionScrn 
            
            screenGlbl.blit(self.imgVehicle, self.vehiRect)
            
            # img.move(screenGlbl, imageMaster, positionScrn, carHeadingDeg)
            
            placeText("Pnt No: "+str(indexGlbl), 0, 12, (580, 8))
            
        elif controlParGlbl == 1:
            
            carHeading    = self.carHeading
            carHeadingDeg = np.rad2deg(carHeading)                      # tpad = 0 at the moment            
            varTmp2       = offsetSecGlbl * np.array([np.sin(carHeading), np.cos(carHeading)]) * scale4Car
            
            positionScrn  = self.position
#            varTmp        = offsetSecGlbl * np.array([np.cos(carHeading-np.pi/2), np.sin(carHeading-np.pi/2)]) * scale4Car     
#            print("drawCar1: ", self.vehiRect, self.vehiRect.center)
            # img.move(screenGlbl, imageMaster, positionScrn, carHeadingDeg)

#            positionScrn1    =  self.pntOfRunning[indexTmp]* scaleGeoGlbls + np.array(screenCntrGlbl) + varTmp #- self.vehiRect.center 
#            print("drawCar3: ", indexTmp, positionScrn, positionScrn1)
            self.vehiRect        = self.imgVehicle.get_rect(center=positionScrn) 
            self.imgVehicle      = myRotate(self, imageMaster, carHeadingDeg)  # carHeadingDeg>0 --> counterclockwise
            self.vehiRect.center = positionScrn - varTmp2 
            
            screenGlbl.blit(self.imgVehicle, self.vehiRect)
            
            placeText("Pnt No: "+str(lineCounterGlbl), 0, 12, (580, 8))   
            
        elif controlParGlbl == 2:
            # if we get the data from file, that reference is the cneter of oru, so shift the image based on oru center
            carHeading    = self.carHeading
            carHeadingDeg = np.rad2deg(carHeading)
            #varTmp        = offsetSecGlbl * np.array([np.cos(carHeading-np.pi/2), np.sin(carHeading-np.pi/2)]) * scale4Car
            varTmp        = offsetSecGlbl * np.array([np.sin(carHeading), np.cos(carHeading)]) * scale4Car
            # self.vehiRect.center is the one only at the beginning. it is ok if no car drawing with angle. it should be subtracted and added a real carHeading at the time
            positionScrn  = (self.position*[1,-1]) * scaleGeoGlbls + screenCntrGlbl  # - self.vehiRect.center + varTmp 
            
            self.vehiRect        = self.imgVehicle.get_rect(center=positionScrn) 
            self.imgVehicle      = myRotate(self, imageMaster, carHeadingDeg)  # carHeadingDeg>0 --> counterclockwise
            self.vehiRect.center = positionScrn - varTmp  
            
            screenGlbl.blit(self.imgVehicle, self.vehiRect)

            #print("drawCar: ", self.position, carHeadingDeg)
            placeText("Pnt No: "+str(indexGlbl), 0, 12, (580, 8))
            # place file name below
            placeText(data2Process, 0, 12, (16, 975))
        else:
            print("Error: Wrong option from the command line for '-N': ", controlParGlbl)
            
        
 
       
    def getSecCenter(self):
    # get the center of the secondary coil in screen coordinate
        # center of car
        

        if controlParGlbl == 0:
            xyCar          = np.array(self.position)
            varTmp         = offsetSecGlbl * np.array([np.cos(self.carHeading-np.pi/2), np.sin(self.carHeading-np.pi/2)])
 
            # scale and shift 
            self.secCenter = (xyCar*[1,-1]) * scaleGeoGlbl + np.array(screenCntrGlbl) - scale4Car*varTmp

        elif controlParGlbl == 1:
            indexTmp       = len(self.posOfSecPri)-1
            #carHeading     = self.oriOfSecPri[indexTmp]
            #varTmp2        = offsetSecGlbl * np.array([np.sin(carHeading), np.cos(carHeading)]) * scale4Car            
            # self.secCenter = self.vehiRect.center + varTmp2
            
            
            self.secCenter = self.posOfSecPri[indexTmp]
            # self.secCenter = self.pntOfRunning[indexTmp]* scaleGeoGlbls + np.array(screenCntrGlbl) + varTmp1 + self.vehiRect.center
            # print("getSecCenter1: ", self.secCenter)

             
        elif controlParGlbl == 2: 

            #self.secCenter = np.array(self.position) * scaleGeoGlbls + np.array(screenCntrGlbl) 
            self.secCenter = (self.position*[1,-1]) * scaleGeoGlbls + screenCntrGlbl   
            # print("getSecCenter: ", self.secCenter)

            
    def drawRay(self):
        # screen center overlaps primary coil center
        priCenterx = screenCntrGlbl[0]  
        priCentery = screenCntrGlbl[1]  
        priCenter  = np.array([priCenterx, priCentery])
        color      = (255,200,0)
        
        distance   = []

        pygame.draw.line(screenGlbl, color, priCenter, self.secCenter, 1)            # center line

        x = self.position[0]  # +priCenterx
        y = self.position[1]  # +priCentery 
        distance.append(np.sqrt(x*x + y*y))
        #  0----1
        #  |    |
        #  3----2
#        xy  = np.array([xc+l*np.sin(alpha+self.carHeading), yc-l*np.cos(alpha+self.carHeading)])    # 0
#        xy1 = xy / scaleGeoGlbl + np.array(screenCntrGlbl)
#        pygame.draw.line(screenGlbl, color, priCenter, xy1, 1)
#        distance.append(np.sqrt((xy[0]-priCenterx)**2 + (xy[1]-priCentery)**2 ))
#        
#        xy = np.array([xc+l*np.sin(alpha-self.carHeading), yc+l*np.cos(alpha-self.carHeading)])     # 1
#        xy1 = xy / scaleGeoGlbl + np.array(screenCntrGlbl)
#        pygame.draw.line(screenGlbl, color, priCenter, xy1, 1)
#        distance.append(np.sqrt((xy[0]-priCenterx)**2 + (xy[1]-priCentery)**2 ))
#        
#        xy = np.array([xc-l*np.sin(alpha+self.carHeading), yc+l*np.cos(alpha+self.carHeading)])     # 2
#        xy1 = xy / scaleGeoGlbl + np.array(screenCntrGlbl)
#        pygame.draw.line(screenGlbl, color,priCenter, xy1, 1)
#        distance.append(np.sqrt((xy[0]-priCenterx)**2 + (xy[1]-priCentery)**2 ))
#        
#        xy = np.array([xc-l*np.sin(alpha-self.carHeading), yc-l*np.cos(alpha-self.carHeading)])     # 3
#        xy1 = xy / scaleGeoGlbl + np.array(screenCntrGlbl)
#        pygame.draw.line(screenGlbl, color, priCenter , xy1, 1)
#        distance.append(np.sqrt((xy[0]-priCenterx)**2 + (xy[1]-priCentery)**2 ))
        
           
        # textTemp  = str(sum(distance)/float(len(distance)) / scaleGeoGlbls)
        textTemp  = str(distance) 
        textx     = str(x)
        texty     = str(y)
    
        placeText("black: reference position; blue: position seen from primary side; green: position seen from secondary side ", 0, 11, (10, 8))
        placeText("Distance: "+textTemp[1:7], 1, 18, (140, 26))
        placeText("x: "+texty[0:6], 1, 18, (300, 26))
        placeText("y: "+textx[0:6], 1, 18, (380, 26))
        placeText("[cm]", 1, 18, (460, 26))
                
 

    def resetBackground(self):
        # here the physicalunit witll be scalled to pixels and shifted on the screen
#        screenGlbl.fill((244, 244, 244))

        # plot scales: vertical
        dxy = 100*scaleGeoGlbls
        for i in range(0, 20, 1):
            if i*dxy>self.heightScreen: break
            pygame.draw.line(screenGlbl, (0,0,0), (0,screenCntrGlbl[1]+  i*dxy), (3,screenCntrGlbl[1]+i*dxy), 1)
            pygame.draw.line(screenGlbl, (0,0,0), (0,screenCntrGlbl[1]+5*i*dxy), (5,screenCntrGlbl[1]+5*i*dxy), 2)
            
            pygame.draw.line(screenGlbl, (0,0,0), (self.widthScreen-3,screenCntrGlbl[1]+  i*dxy), (self.widthScreen,screenCntrGlbl[1]+  i*dxy), 1)
            pygame.draw.line(screenGlbl, (0,0,0), (self.widthScreen-5,screenCntrGlbl[1]+5*i*dxy), (self.widthScreen,screenCntrGlbl[1]+5*i*dxy), 2)
        for i in range(0, 20, 1):
            if i*dxy<0: break
            pygame.draw.line(screenGlbl, (0,0,0), (0,screenCntrGlbl[1]-  i*dxy), (3,screenCntrGlbl[1]-  i*dxy), 1)
            pygame.draw.line(screenGlbl, (0,0,0), (0,screenCntrGlbl[1]-5*i*dxy), (5,screenCntrGlbl[1]-5*i*dxy), 2)
            
            pygame.draw.line(screenGlbl, (0,0,0), (self.widthScreen-3,screenCntrGlbl[1]-  i*dxy), (self.widthScreen,screenCntrGlbl[1]-  i*dxy), 1)
            pygame.draw.line(screenGlbl, (0,0,0), (self.widthScreen-5,screenCntrGlbl[1]-5*i*dxy), (self.widthScreen,screenCntrGlbl[1]-5*i*dxy), 2)

        # plot scales: horizontal
        for i in range(0, 20, 1):
            if i*dxy>self.widthScreen: break
            pygame.draw.line(screenGlbl, (0,0,0), (screenCntrGlbl[0]+  i*dxy,0), (screenCntrGlbl[0]+  i*dxy, 3), 1)
            pygame.draw.line(screenGlbl, (0,0,0), (screenCntrGlbl[0]+5*i*dxy,0), (screenCntrGlbl[0]+5*i*dxy, 5), 2)
            
            pygame.draw.line(screenGlbl, (0,0,0), (screenCntrGlbl[0]-  i*dxy,0), (screenCntrGlbl[0]-  i*dxy, 3), 1)
            pygame.draw.line(screenGlbl, (0,0,0), (screenCntrGlbl[0]-5*i*dxy,0), (screenCntrGlbl[0]-5*i*dxy, 5), 2)

        for i in range(0, 20, 1):
            if i*dxy<0: break
            pygame.draw.line(screenGlbl, (0,0,0), (screenCntrGlbl[0]+  i*dxy,self.heightScreen), (screenCntrGlbl[0]+  i*dxy, self.heightScreen-3), 1)
            pygame.draw.line(screenGlbl, (0,0,0), (screenCntrGlbl[0]+5*i*dxy,self.heightScreen), (screenCntrGlbl[0]+5*i*dxy, self.heightScreen-5), 2)
            
            pygame.draw.line(screenGlbl, (0,0,0), (screenCntrGlbl[0]-  i*dxy,self.heightScreen), (screenCntrGlbl[0]-  i*dxy, self.heightScreen-3), 1)
            pygame.draw.line(screenGlbl, (0,0,0), (screenCntrGlbl[0]-5*i*dxy,self.heightScreen), (screenCntrGlbl[0]-5*i*dxy, self.heightScreen-5), 2)

        # draw circles           
        pygame.draw.circle(screenGlbl, (222,222,222), (int(screenCntrGlbl[0]), int(screenCntrGlbl[1])), int(650*scaleGeoGlbls), 1) # far
        pygame.draw.circle(screenGlbl, (222,222,222), (int(screenCntrGlbl[0]), int(screenCntrGlbl[1])), int( 40*scaleGeoGlbls), 1) # near
        
        # put the reference of car trail here (xref,yref,tref)
        if (controlParGlbl == 2) and (len(self.positionRef)>1):
            # put the car track/trail on the background
            # print('controlParGlbl=', controlParGlbl, self.positionRef[0:11,0:2])
            postionScrn = (self.positionRef*[1,-1]) * scaleGeoGlbls + screenCntrGlbl 
            
            pygame.draw.lines(screenGlbl, (0,0,0), False, postionScrn, 2)
            
        elif controlParGlbl == 1:
            # print("resetBack: ",  len(self.posOfRef), len(self.posOfSecPri))
        #   reference trace
            if len(self.posOfRef)>1:
                pygame.draw.lines(screenGlbl, (0,0,0), False, self.posOfRef, 2)
        #   sec trace
            if len(self.posOfSecPri)>1:
                pygame.draw.lines(screenGlbl, (0,0,255), False, self.posOfSecPri, 2)
             
             
    def checkBounds(self):
        self.position[0] = max(self.position[0], -self.centerRoi[0])
        self.position[0] = min(self.position[0], -self.centerRoi[0]+self.widthRoi)
        self.position[1] = min(self.position[1], -self.centerRoi[1]+self.heightRoi)
        self.position[1] = max(self.position[1], -self.centerRoi[1])
        
        # if hit the wall, speed will be reduced
        if (self.position[0] == -self.centerRoi[0]) or \
           (self.position[0] == -self.centerRoi[0]+self.widthRoi)  or \
           (self.position[1] == -self.centerRoi[1]+self.heightRoi) or \
           (self.position[1] == -self.centerRoi[1]):
            self.speed = np.sign(self.speed)*np.min([3e2, np.abs(self.speed)])

        
    def checkMoveKeys(self):
        keys = pygame.key.get_pressed()
        # steering
        if keys[pygame.K_RIGHT]:
            self.keyRight        = True
            self.steeringCounter = 0
            self.steering       += self.turnRate
            
        if keys[pygame.K_LEFT]:
            self.keyLeft         = True
            self.steeringCounter = 0
            self.steering       -= self.turnRate
        # check bound 
        self.steering = np.sign(self.steering)*np.min([50, np.abs(self.steering)])
            # accelerating/deaccelerating        
        if keys[pygame.K_UP]:
            self.speed += self.accel
        if keys[pygame.K_DOWN]:
            self.speed -= self.accel
#        if abs(self.speed)<self.accel:
#            self.speed  = 0

        # speed limitation  
        self.speed = np.sign(self.speed)*np.min([5e4, np.abs(self.speed)])
        
        #print("psa:", self.position, self.speed, self.accel, self.steering, np.rad2deg(self.carHeading))



    def checkControlKeys(self):
        global indexGlbl
        keys = pygame.key.get_pressed()        
        
        if controlParGlbl != 1:
            # resetBackground and pause
            if keys[pygame.K_r]:
                resetVehi(self)
                indexGlbl = -1    # to clear pntOnTrail
                
            if keys[pygame.K_b] or keys[pygame.K_SPACE]:
                self.speed          = 0
                # if self.speed != 0:
                    # self.speedPrev      = self.speed
                    # self.carHeadingPrev = self.carHeading
                    # self.steeringPrev   = self.steering
                    # self.speed          = 0
                # else:
                    # self.speed          = self.speedPrev
                    # self.carHeading     = self.carHeadingPrev
                    # self.steering       = self.steeringPrev
                    # self.speedPrev      = 0
        
        if keys[pygame.K_q]:
            pygame.quit()
            print("\nExit from align.")
            sys.exit()
            
     
class Img:   # deal with rotation of vehicle image: rotate around the image center, place image according to left-top coner
    
    def __init__(self, imageMaster):
        
        self.width  = imageMaster.get_width()
        self.height = imageMaster.get_height()
        
        self.beta   = np.arctan2(self.width, self.height)
        self.dc     = 0.5*np.sqrt(self.width*self.width + self.height*self.height)
    
        # image local center
        self.dxc    = 0.5*self.width
        self.dyc    = 0.5*self.height
        
        
    def shift(self, alpha):    # alpha [rad]
        
        alphaRad = np.deg2rad(alpha)
        # used 
        # use geometric relation: difficult
        # dx       = self.width*np.cos(alphaRad)           + self.dc*np.sin(self.beta+alphaRad) - self.dxc
        # print("shift1: ",dx, self.width*np.cos(alphaRad), self.dc*np.sin(self.beta+alphaRad), -self.dxc)
        # dy       = -2*self.dc*np.sin(self.beta+alphaRad) + self.dc*np.cos(self.beta+alphaRad) - self.dyc
        # print("shift2: ",dy, -2*self.dc*np.sin(self.beta+alphaRad), self.dc*np.cos(self.beta+alphaRad), -self.dyc)
        # varTmp   = self.width*np.cos(alphaRad) + self.height*np.sin(alphaRad)
        # print("shift3: ",varTmp, self.width*np.cos(alphaRad), self.height*np.sin(alphaRad))
        # return np.array([dx, dy])
        
        

    def move(self, screen, imageMaster, position, alpha):
        
        self.alpha = alpha
        rectOld    = imageMaster.get_rect()
        imgRotated = pygame.transform.rotate(imageMaster, alpha)
        rectNew    = imgRotated.get_rect()
        shift      = np.array(rectNew.center) - np.array(rectOld.center)
        # print("nove: ", shift, rectNew.center, rectOld.center, position)
        position   = np.array(position) 
        screenGlbl.blit(imgRotated, position) 
        
        
    def dimensionCheck(self, imageMaster, alpha):
        
#        alpha = -alpha
        angleRad = np.deg2rad(alpha)
        # expected dimension
        width  = self.width*np.cos(angleRad) + self.height*np.sin(angleRad)
        height = self.width*np.sin(angleRad) + self.height*np.cos(angleRad)
        
        # measured dimention
        width1  = imageMaster.get_width()
        height1 = imageMaster.get_height()
        
        return np.array([self.width, self.height,width1, height1,  width, height, width1-width, height1-height])



def processData(lineNew):  # no convertion, only get the values
    # parse the string to float
    # stringSplit = re.sub("[^0-9^.^\s]", "", lineNew)
    stringSplit = ' '.join(lineNew.split())    # split string based on ONE ' '; it two SPC, it is bad.
    if len(stringSplit)>0:
        # print("processData: |", stringSplit, "|", len(stringSplit))
        stringSplit = stringSplit.split(" ")
        stringSplit = np.array(stringSplit)
        try:   # for case, rubish is written in the file
            valueSplit  = stringSplit.astype(np.float)
            if len(valueSplit) <= 0:
                print("Warning: Data read is empty and program continues ... ...")
        except:
            valueSplit =[]
    else:
        valueSplit =[]
    return np.array(valueSplit)


def myRotate(self, imageMaster, angleDeg):
    """rotate an image while keeping its center"""

    oldCenter     = self.vehiRect.center
    imgVehicle    = pygame.transform.rotate(imageMaster, angleDeg)
    self.vehiRect = imgVehicle.get_rect()
  #  print("update: ", self.dir, oldCenter, self.rect)
    self.vehiRect.center = oldCenter

    return imgVehicle
    
    
def placeText(text, fontID, fontSize, xy):
    # font      = pygame.font.Font(None,24)
    resFolderPath = os.path.join(CurrentPath, 'res')
    if fontID == 0:
        font          = pygame.font.Font(os.path.join(resFolderPath, 'FreeSans.ttf'), fontSize)
    else:
        font          = pygame.font.Font(os.path.join(resFolderPath, 'FreeSansBold.ttf'), fontSize)
    textWhole     = font.render(text, 1, (11,11,11))
    screenGlbl.blit(textWhole, xy)


    def resetAwc(awc):
        awc.pntOnTrail.clear()
        
def resetVehi(car):
    # resetVehi the car to a random position at about the starting point
    if controlParGlbl == 0:    
        car.speed      = 0
        car.steering   = 0
        # car.initX      = int(0.5*random.randrange(-car.widthRoi, car.widthRoi))
        # car.initY      = int(car.centerRoi[1]-0*car.heightRoi*0.95) # 300.0
        car.initX      = int(random.randrange(screenCntrGlbl[0]-widthScreen, widthScreen-screenCntrGlbl[0]) / scaleGeoGlbl)
        car.initY      = int((heightScreen-screenCntrGlbl[1]) / scaleGeoGlbl)
        # the car center (wheel center)
        car.position   = np.array([car.initX, car.initY])
    
        car.carHeading = np.deg2rad(random.randrange(-10,10))
    else:
        car.speed      = 0
        car.steering   = 0
        car.initX      = 0
        car.initY      = 0
        car.position   = np.array([car.initX, car.initY])    
        car.carHeading = 0
        
    time.sleep(0.2)

       
def main():
    
    global imageMaster
    
    # pygame.display.set_caption("alignment")
    
    # background   = pygame.Surface(screenGlbl.get_size())
    # background.fill((244, 244, 244))
    
    # screenGlbl.blit(background, (0, 0))
        
    
    # pad size (642 x 890 mm), scale 14 mm/pixel
    awc = AWC(642*scaleGeoGlbl, 890*scaleGeoGlbl, 0, 0)
    try:
        resFolderPath = os.path.join(CurrentPath, 'res')
        imageFile     = os.path.join(resFolderPath, "audiA306.PNG")  # image abchr is always topleft corner
        imageMaster   = pygame.image.load(imageFile)
        img           = Img(imageMaster) 
    except:
        print("\nVehical image not found and program stops.")
        sys.exit()
            
        
    car = Car()

    #car = pygame.sprite.Group(car)
    
    keepGoing, pause = True, False
    clock     = pygame.time.Clock()
    

    while keepGoing:
        
        clock.tick(1/car.dt)
        
        # way to get out by the small "x" on the window upper-right corner
        for event in pygame.event.get(): 
            if event.type == pygame.QUIT: keepGoing = False  
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_p: pause = True
                if event.key == pygame.K_c: pause = False
        
        if not pause:       
            awc.putPriOn()
            car.resetBackground()
     
     
            car.update()
            
            car.drawCar(img)
            
            # print("dimensionCheck: ",img.alpha, img.dimensionCheck(img.imgRotated, img.alpha))
            car.getSecCenter()
    
            car.drawRay()
     
            #awc.update(car.posOriSecPri, car.vehiRect)
     
            awc.placeSecTraceFromPri(car.secCenter)
            
            awc.placeSecTraceFromSec(car)
        
         
        pygame.display.update()
        # waitAkey()
        
        
if __name__ == "__main__":
    main()
    
