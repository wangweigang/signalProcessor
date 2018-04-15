""" findMe.py
    testing signals from a set of entenna grids.
    Works with Python 3.4.4
    Built / created by W. Wang in 03.2018
"""
    
import numpy as np
#import csv
import matplotlib
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
from scipy.optimize import curve_fit
from scipy import interpolate
import os, sys, time
#import threading
import argparse
#import re
#import watchLog as wf
import win32file
import win32con


print ("matplotlib Ver.: ", matplotlib.__version__)
#print ("matplotlib tkinter: ", plt.get_backend())


parser = argparse.ArgumentParser(prog='align', description='Process some results from positioning test, created by Weigang.')
parser.add_argument("-v", "--verbosity",   action="count",   default=0,                                    help="increase help verbosity and exit")
parser.add_argument("-N", dest='ctrlPar',  action="store",   default='0', type=int, choices=[0, 1, 2],     help='Control parameter to processing mode: 0: test steering model; 1: process data from CANOE real-time recordings; 2: postprocess data from simulation, CAN bus, etc.')
parser.add_argument('-f', dest='dataFile', action="store",   default='fosStream.txt', help='Data file (S-format) to be processed')
parser.add_argument('-n', dest='nameUnit', action="store",   default='.\\data\\NameUnit.xls',              help="Header of the dada file")
parser.add_argument('-t', dest='thresholdStd',    action="store",   default='20', type=float,              help="Threshod based STD for object detection")
parser.add_argument('-d', dest='display',  action="store",   default='0', type=int,                        help="Display level")
parser.add_argument('--version',           action='version', version='%(prog)s 1.0')

args = parser.parse_args()

# set up data file
controlParGlbl = args.ctrlPar
# 0: manual
# 1: read log file from CANOE log file "secondaryLocation.asc"
# 2: read file in Soti format


dataFileDefault = r'fosStream.txt'
#print(args.dataFile, "\n",dataFileDefault, args.dataFile==dataFileDefault, args.dataFile is dataFileDefault)
if controlParGlbl == 0:
    data2Process = ''
    print("\nStarting align to check steering model ... ...")
elif controlParGlbl == 1:
    path2WatchGlbl = r".\data"          # default path
    if args.dataFile == dataFileDefault:
        file2WatchGlbl = "fosStream.txt"   # look for changes to a file called fod_stream.txt
        data2Process   = os.path.join(path2WatchGlbl, file2WatchGlbl)
    else:
        file2WatchGlbl = args.dataFile
        data2Process   = os.path.join(path2WatchGlbl, file2WatchGlbl)
    print("\nStarting to watch a running data: ", data2Process)
elif controlParGlbl == 2:
    path2file    = r".\data"           # default path
    if args.dataFile == dataFileDefault: 
        data2Process = os.path.join(path2file, dataFileDefault)
    else:
        data2Process = os.path.join(path2file, args.dataFile)
    print("\nStarting to process positioning data: ", data2Process)

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

displayLevel        = args.display


# distinguish code in development or dedvelped: for exe generation
if getattr(sys, 'frozen', False):
    CurrentPath = sys._MEIPASS
else:
    CurrentPath = os.path.dirname(__file__)

thresholdStd    = args.thresholdStd

lineCounterGlbl = 0             # count the line read from timHV data file
timReady        = False
numOfSample4Avg = 5
numOfVirtualAntenna = 32

# global setup
timHV         = np.array([])
lastValue     = np.array([])

# Oru geometry
widthOruGeom  = 2*17.4
heightOruGeom = 27
#centerOru     = np.array([[17.4],[13.5]])
centerOru     = np.array([[-16],[-14.6]])
#patchOru      = (np.array([[6.3, 28.6, 34.8, 34.8, 28.6, 6.3, 0,  0], 
#                          [0,   0,    12,   15,   27,  27,   15, 12]]) - centerOru).T
patchOru      = (np.array([[25,  20,  -20,  -25,  -25,  -20,    20,    25], 
                           [1.5, 14.6, 14.6, 1.5, -1.5, -14.6, -14.6, -1.5]]) ).T

# receiver board geometry
widthBoard    = 43.4    # cm
heightBoard   = 46.3    # cm 


# calibration for the threshod worth to check
worth2Check   = 0.425
level1        = [-8000,-7500,-7000,-6500,-6000,-5500,-5000,-4500,-4000,-3500,-3000,-2500,-2000,-1500,-1000,-500,0,500,1000,1500,2000,2500,3000,3500,4000,4500,5000,5500,6000,6500,7000,7500,8000]
level2        = np.linspace(0,0.9, 50)

#offsetSecGlbl   = -1450   #-900          # mm offset in y steering of oru center to wheel (car) center
#
#indexGlbl       = 0             # index to control redraw trail. need to declare global if assignment in a function
#
#lineCounterGlbl = 0             # count the line read from timHV data file
#
## setup screen
#os.environ['SDL_VIDEO_WINDOW_POS'] = '2,30' # window top-left corner
#widthScreen    = int(350*2)
#heightScreen   = int(500*2)
#screenGlbl     = pygame.display.set_mode((widthScreen, heightScreen))
#screenCntrGlbl = (0,0) 
#background     = pygame.Surface(screenGlbl.get_size())
#background.fill((244, 244, 244))

#screenGlbl.blit(background, (0, 0))
        

# deal with log reading
if controlParGlbl == 1:
#    path2WatchGlbl = r"H:\Projects\bomb\Me\canoe\Test" # look at the current directory
#    file2WatchGlbl = "secondaryLocation.asc" # look for changes to a file called test.txt
#    dataFile       = os.path.join(path2WatchGlbl, file2WatchGlbl)
#   Open the file we're interested in

    try:    
        hOfFileGlbl = open(data2Process, "rb")
    except FileNotFoundError:
        hOfFileGlbl = open(data2Process, "bw+")
        print("Message: No file found and a new one generate.")

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
    
    
    
def keyEvent( e):
    global pause, index2Draw, indexLastDraw, lineCounterGlbl, numOfSample4Avg, timHV, write2File
    print ("Message (keyEvent): Key (%s) pressed." % (e.key))
    if (e.key == "q") or (e.key == "Q"):
        # print("\nExit from findMe.")
        # sys.exit(0)
        if write2File:
            hFile.close() 

        os._exit(0)  # hammer exit no clean up
        # raise SystemExit(...)
        # os._exit()
    elif (e.key == "p") or (e.key == "P") or (e.key == " "):
        pause = True
    elif (e.key == "c") or (e.key == "C"):
        pause = False
    elif (e.key == "r"):     # smal reset, use the same tim
        pause           = False
        index2Draw      = numOfSample4Avg-1
        lineCounterGlbl = numOfSample4Avg
        indexLastDraw   = -111
    elif (e.key == "R"):     #  reset tim
        pause           = False
        
        # recollect data for tim
        timHV = collectTim(lineCounterGlbl, numOfSample4Avg)
        

def collectTim(lineCounterGlbl, numOfSample4Avg):
    
    i     = lineCounterGlbl
    timHV = np.zeros((1,256))
    while True:
        if i>=lineCounterGlbl+numOfSample4Avg:
            break
        
        horiVertSignal = getRunningData()   # things are assigned in deques posOfRef, posOfSecPri, posOfSecSec
        
        if len(horiVertSignal) != 0:                      
            timHV = np.add(timHV, horiVertSignal)
            i    += 1
    
            print("Message (collectTim): Collect ", i, " data for tim")
    
    print("Message (collectTim): Initial matrix (tim) regenerated with getRunningData.")    
        
    # tim 
    return timHV / numOfSample4Avg
       

    
def getRunningData():
    global lineCounterGlbl, lastValue
    
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

    # print("results: ", results)
#   For each change, check to see if it's updating the file we're interested in
    for action, file in results:
#       full_filename = os.path.join (path2WatchGlbl, file)
        # print (hOfFileGlbl, file, lineCounterGlbl, file2WatchGlbl, ACTIONS.get (action, "Unknown"), results)
        if file == file2WatchGlbl:
            first = hOfFileGlbl.readline()                              # Read the first line.
            # print ("aaa=", file, first)
            try:
                hOfFileGlbl.seek(-2, os.SEEK_END)                       # Jump to the second last byte.
                while hOfFileGlbl.read(1) != b"\n":                     # Until EOL is found...
                    hOfFileGlbl.seek(-2, os.SEEK_CUR)                   # ... jump back the read byte plus one more.
                lineLast      = hOfFileGlbl.readline().decode()         # Read last line.
                
    #            print("not eq: ", np.array_equal(dataFromFile, Object.lastValue), dataFromFile, Object.lastValue)
                        
                varTmp = processData(lineLast)
                if (len(varTmp) > 0) and (not np.array_equal(varTmp, lastValue)):
                    lastValue = varTmp
                    dataFromFile     = varTmp[10:266]   # the coloums with FOD data

            except OSError as err:
#                print("OS error: {0}".format(err))
#                print("type(err):", type(err))
#                print("err.args:", err.args)
#                print("err:", err)
                errorNo, ErrorName = err.args
#                print("errorNo, ErrorName = ", errorNo, ErrorName)
                
                # deal with only one line in file
                if ErrorName=='Invalid argument':
                    varTmp = processData(first.decode())
                    if len(varTmp)>0:
                        lastValue = varTmp
                        dataFromFile     = varTmp[10:266]   # the coloums with FOD data
                
                continue    # do nothing this time and do next
                    
            # print("getRunningData: ", lineCounterGlbl, len(Object.posOfRef), len(Object.posOfSecPri), len(Object.oriOfSecPri),len(Object.posOfSecSec))
#            lineNew = hOfFileGlbl.read()
#            if lineNew != "":
#                dataFromFile = processData(lineNew)
#                break
        # time.sleep(1)
        # threading.Timer(2, Object.checkControlKeys).start()  # not working
    return dataFromFile
    

def getHoriVertSignal(dataFile):
# read Soti data: first 9 columns (data format related)
#  0       1        2      3       4       5       6       7       8 
# xref    yref    tref    xpad    ypad    tpad    xoru    yoru    toru
# [cm]    [cm]    [°]     [cm]    [cm]    [°]     [cm]    [cm]    [°]
    
# note: dataFel has to be delimited with a single SPC
    
    if dataFile:
        try:
#            horiVertSignalOriginal = np.loadtxt(dataFile, delimiter=" ", usecols=range(10,42))   # 10:25 hori; 26:41 vert
            horiVertSignalOriginal = np.loadtxt(dataFile, delimiter=" ", usecols=[i for i in range(10,266)])   # all lh's and lv's
             
        except FileNotFoundError:
            print("\nError: Wrong file or file path and exit from findMe.")

            sys.exit()
    else:
        horiVertSignalOriginal = np.array([])
        
    return horiVertSignalOriginal
    

def getBoundaryIndex(vec, thresholdy):
    numOfEle = len(vec)
    thresholdy = 0.1
    iStart    = 0
    for k in range(0, numOfEle):
        if vec[k] >= thresholdy:
            iStart = np.max([0, k-1])
            break
    iEnd = numOfEle-1
    for k in range(numOfEle-1, -1, -1):
        if vec[k] >= thresholdy:
            iEnd = np.min([numOfEle-1, k+1])
            break
    return iStart, iEnd 





class Obj:

    def __init__(self):
        
        global indexGlbl, screenCntrGlbl, lineCounterGlbl, timReady, numOfSample4Avg, timHV
        lastValue                   = np.array([])
        self.horiVertSignalOriginal = np.array([])
        timHV                       = np.zeros((1,256))
        horiVertSignal              = np.zeros((1,256))

        # get all data in
        if (controlParGlbl == 1):
            # get the existing data first
            try:
            
                horiVertSignal          = getHoriVertSignal(data2Process)
                (numOfSample, numOfVar) = horiVertSignal.shape
                
                if numOfSample>0:
                    iEnd = np.min([numOfSample, numOfSample4Avg])
                    for i in range(0, iEnd):    # take tge first numOfSample4Avg  samples

                        timHV = np.add(timHV, horiVertSignal[i,:])

                print("Message (obj): ", iEnd, " samples collected.")

                if numOfSample<numOfSample4Avg:
                    i    = numOfSample
                    iAll = numOfSample
                    while True:
                        if i>=numOfSample4Avg:
                            break
                        
                        horiVertSignal = getRunningData()   # things are assigned in deques posOfRef, posOfSecPri, posOfSecSec
                        if len(horiVertSignal) != 0:                      
                            timHV = np.add(timHV, horiVertSignal)
                            iAll += 1
                            i    += 1
                
                    print("Message (obj): ", iAll, " samples collected (e).")
                    
                # tim 
                timHV    = timHV / numOfSample4Avg
                timReady = True     
                print("Message (Obj): Initial matrix (tim) generated with getRunningData.")    
                    
            except:
                # collect thing from scratch
                i = 1
                while True:
                    if i>numOfSample4Avg:
                        break
                    
                    horiVertSignal = getRunningData()   # things are assigned in deques posOfRef, posOfSecPri, posOfSecSec
                    if len(horiVertSignal) != 0:                      
                        timHV = np.add(timHV, horiVertSignal)
                        print("Collecting data=", i)
                        i += 1

                print("i horiVertSignal=", i, len(horiVertSignal))
                print("Message (Obj): Initial matrix (tim) generated with getRunningData from scratch.")    
                # tim 
                timHV    = timHV / numOfSample4Avg
                timReady = True
           
            self.numOfSample = numOfSample4Avg
            
            # after init, do getRunningData(self)   

        elif (controlParGlbl == 2):
         
            self.horiVertSignalOriginal = getHoriVertSignal(data2Process)
        
        else:
            self.horiVertSignalOriginal = np.array([]);
        
        if len(self.horiVertSignalOriginal)>0:
            (self.numOfSample, numOfVar) = self.horiVertSignalOriginal.shape
        
        # get first few samples and build a null matrix before any ploting
        
        if (self.numOfSample>5) and (not timReady):
            numOfSample4Avg = np.min([self.numOfSample, 6])
            for i in range(0,numOfSample4Avg):    # take tge first numOfSample4Avg  samples
                timHV = np.add(timHV, self.horiVertSignalOriginal[i,:])
            
            print("Message (Obj): Initial matrix (tim) generated with getHoriVertSignal.")    
            # tim 
            timHV = timHV / numOfSample4Avg
            timReady   = True
            
        self.x = np.linspace(0,15, 16)
        self.y = np.linspace(0,15, 16)
        
        # prepare figures
        if False:    # 8 subplots
            self.fig, self.ax = plt.subplots(figsize=(28, 10), nrows=2, ncols=4, sharex='col', sharey='row')
        else:
            self.fig, self.ax = plt.subplots(figsize=(23, 10), sharex='col', sharey='row')
            self.ax11 = plt.subplot2grid((4, 12), (3, 2))
            self.ax12 = plt.subplot2grid((4, 12), (3, 3))
            self.ax13 = plt.subplot2grid((4, 12), (3, 4))
            self.ax14 = plt.subplot2grid((4, 12), (3, 5))
            self.ax15 = plt.subplot2grid((4, 12), (3, 6))
            self.ax16 = plt.subplot2grid((4, 12), (3, 7))
            self.ax17 = plt.subplot2grid((4, 12), (3, 8))
            self.ax18 = plt.subplot2grid((4, 12), (3, 9))
            
            self.ax33 = plt.subplot2grid((4, 12), (0, 0), rowspan=3, colspan=4)
            self.ax44 = plt.subplot2grid((4, 12), (0, 4), rowspan=3, colspan=4)
            self.ax22 = plt.subplot2grid((4, 12), (0, 8), rowspan=3, colspan=4)
        
        self.fig.subplots_adjust(bottom=0.04, left=0.02, right=0.98, hspace=0.2, wspace=0.1)
#        self.fig.suptitle('FOD / vehicle detection signals', fontsize='large')
        
        # self.fig.canvas.mpl_connect('key_press_event', keyEvent)

#       self.interp = 'nearest'
        self.interp = 'bilinear'
        

    def func(self, x, a, b, c):       
        
        # hyperbolic th(x): works
        # func(xdata, 0.8, -4, 0.7)
        # 
        y = c*0.5*(1-np.tanh(a*x+b))
        
        return y
        
        

    def update(self, k): # for every frame of car class
    # get all the parameters (xpad, ypad, tpad) needed to draw car
    
        # self.vehiRect = self.imgVehicle.get_rect()   # get the last rectangule of the car images with rotation
 
        if controlParGlbl == 1: # driven by log file change
            
            # plot the data already in file
#            (self.numOfSample, numOfVar) = self.horiVertSignalOriginal.shape
            
            
#           plot the first few line which were already there
#            for k in range(0,self.numOfSample): 


            # self.checkControlKeys()
            
            # now follow the running dtat
            while True:
                self.horiVertSignalOriginal = getRunningData()   # things are assigned in deques posOfRef, posOfSecPri, posOfSecSec

                if (len(self.horiVertSignalOriginal)>0):
                    break
                    
#                if (len(self.horiVertSignalOriginal)>0) and (not np.array_equal(self.horiVertSignalOriginal, self.lastValue)):
#                    print("Message (Obj.update): Data file update detected: ", len(self.horiVertSignalOriginal), (not np.array_equal(self.horiVertSignalOriginal, self.lastValue)), lineCounterGlbl)
#                    self.makeAcontourf(-1)

            self.makeAcontourf(k)
            # self.lastValue = self.horiVertSignalOriginal


#            plt.show() 
            # self.posOriSecPri = np.array([])
            
        elif controlParGlbl == 2: # based on data file from positioning test
        
#            (self.numOfSample, numOfVar) = self.horiVertSignalOriginal.shape

#            for k in range(0,self.numOfSample,1):
            
            self.makeAcontourf(k)
        
#            plt.show()                            
    
#            self.makeAcontourf()
#            self.checkBounds()  
            # self.posOriSecPri = [self.position[0], self.position[1], self.steering]
            #print("update: ", self.posOriSecPri)
        
    def fitAndEvalue(self, x, y, method, ratioBoard, xn):
        # y are normilizsed after shifting
        # make a curve fit and evaluate the values on xn
        indexMax     = np.argmax(y)
        yMax         = y[indexMax]
        xTemp        = np.zeros(numOfVirtualAntenna)
        yTemp        = np.zeros(numOfVirtualAntenna)
        yn           = np.zeros(numOfVirtualAntenna)

        numOfPoint   = len(x)       # = 16
        thresholdLow = 0.05
#        condition    = y>=thresholdLow*yMax
#        areaHalf     = 0.5*np.sum(y[condition])
        
        # get practical threshold
        # yNewThreshold = np.max([y[0], y[15], thresholdLow*yMax])
        yNewThreshold  = thresholdLow*yMax
        
        # find left and left and right index and area under
        sumOfyLeft     = 0
        sumOfyRight    = 0
        iLeft          = np.max([indexMax-1,0])
        found          = False
        for i in range(indexMax,-1, -1):
            sumOfyLeft = sumOfyLeft + y[i]
            if y[i]<yNewThreshold:
                iLeft  = i
                found  = True
                break
        if not found:
            iLeft = 0
        # check if it is a blind spot: check 2 left point at left of iLeft
        if iLeft > 1:
            if y[iLeft-1]+y[iLeft-2]>3*thresholdLow*yMax:                
                for i in range(iLeft-2,-1, -1):
                    sumOfyLeft = sumOfyLeft + y[i]
                    if y[i]<yNewThreshold:
                        iLeft  = i
                        break                
            
        iRight          = np.min([indexMax+1, numOfPoint])   # deal with right border issue
        found           = False
        for i in range(indexMax+1,numOfPoint):
            sumOfyRight = sumOfyRight + y[i]
            if y[i]<yNewThreshold:
                iRight  = i
                found   = True
                break 
        if not found:
            iRight = numOfPoint-1
        # check if it is a blind spot: check 2 right point at right of iRIght
        if iRight < numOfPoint-2:
            if y[iRight+1]+y[iRight+2]>3*thresholdLow*yMax:
                # search to the right
                for i in range(indexMax+1,numOfPoint):
                    sumOfyRight = sumOfyRight + y[i]
                    if y[i]<yNewThreshold:
                        iRight  = i
                        break 

        sumOfy = sumOfyLeft + sumOfyRight

        # get gravity center
            
        iLeft, iRight = getBoundaryIndex(y, 0.01)
    
        if iRight == indexMax:
            iGravityCenter = iRight
        elif iLeft == indexMax:
            iGravityCenter = iLeft
        elif iRight<iLeft+numOfVirtualAntenna/2: # peaks are concentrated on half of the domain
            iGravityCenter = iLeft
            sumOfyHalf     = 0
            found          = False
            for i in range(iLeft, iRight):
                sumOfyHalf = sumOfyHalf + y[i]             
                if sumOfyHalf>=0.5*sumOfy:
                    iGravityCenter = i
                    break
        else:   # peaks spread too wide
            iGravityCenter = int((iLeft+iRight)/2)
                    
#        fold both sides together based on iGravityCenter
        if iGravityCenter==0:
            xTemp                      = x
            yTemp                      = y
            yTemp[iRight:numOfPoint]   = 0.001 
        elif iGravityCenter<numOfVirtualAntenna/2:
            # x: 0 -- iEnd(=numOfPoint-iGravityCenter)
            iEnd                       = iRight-iGravityCenter+1
            xTemp[0:iEnd]              = x[0:iEnd]
            # y: 0 -- iEnd1(=iRight-iGravityCenter+1), move peak right to the beginning
            yTemp[0:iEnd]              = y[iGravityCenter:iRight+1]
            # y: iEnd1 -- numOfPoint, all the rest
            yTemp[iEnd:numOfPoint]     = 0.001                        # brutally set the second peak to zero 
            # x: , peak left
            iEnd1                      = iGravityCenter - iLeft + 1
            xTemp[iEnd:iRight-iLeft+1] = x[1:iEnd1]        # put the small x to the end and see if it need to be moved at the begining
            # y: 
            if iLeft == 0:
                yTemp[iEnd:iRight-iLeft+1]   = y[iGravityCenter-1::-1]
            else:   
                yTemp[iEnd:iRight-iLeft+1]   = y[iGravityCenter-1:iLeft-1:-1]
            # x: the rest
            xTemp[iRight-iLeft+1:numOfPoint] = x[iRight-iLeft+1:numOfPoint]
        else:
            # x: 0 -- iGravityCenter
            xTemp[0:iGravityCenter+1] = x[0:iGravityCenter+1]
            # y: 0 -- iEnd, mirror peak left at left
            iEnd                      = iGravityCenter-iLeft+1
            if iLeft == 0:
                yTemp[0:iEnd]         = y[iGravityCenter::-1]            
            else:            
                yTemp[0:iEnd]         = y[iGravityCenter:iLeft-1:-1]
            # y: iEnd -- numOfPoint, all the rest
            yTemp[iEnd:numOfPoint]    = 0.001    # brutally set the second peak to zero 
            # x: 1 -- iEnd1(=iRight-iGravityCenter+1), peak right
            iEnd1                            = iRight-iGravityCenter+1
            xTemp[iGravityCenter+1:iRight+1] = x[1:iEnd1]             # put the small x to the end and see if it need to be moved at the begining
            # y: 1 -- iEnd1
            yTemp[iGravityCenter+1:iRight+1] = y[iGravityCenter+1:iRight+1]
            # x: the rest of x
            xTemp[iRight+1:numOfPoint]       = x[iRight+1:numOfPoint]

        if method==1:
            # make a curve fit 
# initiation of the function
        # pInit      = [1, -indexMax, y[indexMax]]
            pInit      = [1, 1, y[indexMax]]
            # popt, pcov = curve_fit(self.func, xTemp, yTemp, p0=pInit, method='{'lm', 'trf', 'dogbox'}', bounds=([1/16, -16.0, 0.0], [16, 16.0, 1.0]))
            popt, pcov = curve_fit(self.func, xTemp, yTemp, method='trf', p0=pInit, bounds=([1/numOfVirtualAntenna, -numOfVirtualAntenna/1.5, 0.2], [numOfVirtualAntenna, numOfVirtualAntenna, 1.1]))
    
            # evalue fitted value on point xn
            yTemp        = self.func(xn, *popt)
            
            errorStd = np.std(yTemp)
    #        print("errorStd pcov:",errorStd, popt, np.sqrt(np.diag(pcov)))
    
            if errorStd>0.02:  # if we get a line, drop it
                
                if iGravityCenter==0:
                    yn  = yTemp
                elif iGravityCenter<numOfVirtualAntenna/2:
                    iEnd                            = numOfPoint-iGravityCenter
                    yn[iGravityCenter:numOfPoint]   = yTemp[0:iEnd]
                    yn[0:iGravityCenter+1]          = yTemp[iGravityCenter::-1]
                else:    # mirror back
                    yn[0:iGravityCenter+1]          = yTemp[iGravityCenter::-1]
                    iEnd                            = numOfPoint - iGravityCenter
                    yn[iGravityCenter+1:numOfPoint] = yTemp[1:iEnd]
            else:   # curve fit is no good
                yn = y
    # convert x and y to fitting function
    # not working: good linear fit does not means a good gaussian fit
    #        xConv  = -0.5*np.square((x-m)/d)
    #        yConv  =  0.9189 + np.log(d*y)
    #        
    #        xnConv = -0.5*np.square((xn-m)/d)
    #        
    #        a, b   = np.polyfit(xConv, yConv, 1)
    #        ynConv = np.polyval([a, b], xnConv)
    #
    #        yn     = np.exp(ynConv-0.9189) / d
            # convert back
        elif method == 2:
#             make curve based on gc and area
            area           = np.sum(y)
            heightAvg      = np.mean(y[iLeft:iRight+1])
#            heightAvg  = np.linalg.norm(y)/numOfPoint
#            heightAvg  = np.std(y)/2
#            heightAvg  = np.median(y)
#            heightAvg  = yMax

            iLeft, iRight = getBoundaryIndex(y, 0.01)
            if iRight == indexMax:
                iGravityCenter = iRight
            elif iLeft == indexMax:
                iGravityCenter = iLeft
#            elif iRight<iLeft+numOfVirtualAntenna/2:   # for case with narrow peak
            elif heightAvg/(iRight-iLeft+1)<0.4/numOfVirtualAntenna: # two peaks are too far apart
                iGravityCenter = (iLeft+iRight)/2            
            else:
                iGravityCenter = iLeft
                sumOfyHalf     = 0
                found          = False
                for i in range(iLeft, iRight+1):
                    sumOfyHalf = sumOfyHalf + y[i]             
                    if sumOfyHalf>=0.5*sumOfy:
                        iGravityCenter = i
                        break
#            else:   # for case with long peaks
#                iGravityCenter = (iLeft+iRight)/2
 
            iGCn           = (numOfVirtualAntenna-1) * iGravityCenter / (numOfPoint-1)
#            coef           = 0.9 + (4.25-0.9)/(0.81-0.37)* (heightAvg-0.37
                                                
#            coef           = 0.94 + (1.24-0.94)/(0.63-0.24) * (heightAvg-0.24)     # 70
            coef           = 0.9 + (1.2-0.9)/(0.63-0.24) * (heightAvg-0.24) 
                                      
            height         = heightAvg * coef
#            widthHalfn     = (numOfVirtualAntenna-1) * area/height/2  / (numOfPoint-1)
            widthHalfn     = np.min([15, (numOfVirtualAntenna-1) * area/height/2  / (numOfPoint-1)]) / ratioBoard
            
            print("area heiht heightAvg widthHalfn iLeft yMax iRight gc=%6.3f %6.3f %6.3f %6.3f %6.3f %3d %6.3f %3d %3d" % (area, height, heightAvg, widthHalfn, coef, iLeft, yMax, iRight, iGravityCenter))
            
            for i in range(0,numOfVirtualAntenna):
                if np.max([iLeft, iGCn-widthHalfn]) <= i and i <= np.min([iRight, iGCn+widthHalfn]):
                   yn[i] = height
        else:
            print("Error (fitAndEvalue): Wrong method (", method, "choosen and program stops.")
#           os._exit(0)  # hammer exit no clean up
#           raise SystemExit(...)
            sys.exit()
            
        return yn, iGravityCenter/(numOfPoint-1)
        
        
        
        
    def makeAcontourf(self, k):   # make one pcolor plate

        global indexGlbl, lineCounterGlbl, worth2Check, level1, level2, indexLastDraw, afterReset, thresholdStd, timHV, write2File 

        if k != indexLastDraw:
            lineCounterGlbl += 1
        
        indexLastDraw = k
        
        # get rid of noise with tim
        if k == -1:
            horiVertSignal = np.subtract(self.horiVertSignalOriginal, timHV[0,:])            
        elif k >= 0:
            horiVertSignal = np.subtract(self.horiVertSignalOriginal[k,:], timHV[0,:])

        zh1           = np.zeros(18)         # get filled from 0 to 17
        zv1           = np.zeros(18)         # get filled from 0 to 17

        zhSum         = np.zeros(18)
        zvSum         = np.zeros(18)
        zhSumNorm     = np.zeros(18)
        zvSumNorm     = np.zeros(18)
        zhSum2NormAvg = np.zeros(18)
        zvSum2NormAvg = np.zeros(18)

#        zhSumLog     = np.zeros(18)
#        zvSumLog     = np.zeros(18)
        zhSumLogNorm  = np.zeros(18)
        zvSumLogNorm  = np.zeros(18)
        
        # loop all the antennas in one sample: algo 1 ------------------------------------------------------
        for lhStart in range(1, 256, 32):
            z         = np.zeros((18,18))      # 0-17, 0-17
            z4        = np.zeros((numOfVirtualAntenna,numOfVirtualAntenna))      
            z3        = np.zeros((numOfVirtualAntenna,numOfVirtualAntenna))      
            lvStart   = lhStart + 16
            lvEnd     = lvStart + 16

            zh        = horiVertSignal[lhStart-1:lvStart-1] 
            zv        = horiVertSignal[lvStart-1:lvEnd-1]

            zh1[0]    = zh[0]
            zh1[1:17] = zh        # zh1[1:17] 16 elements; zh: 0 -- 15
            zh1[17]   = zh[15]
            zv1[0]    = zv[0]
            zv1[1:17] = zv
            zv1[17]   = zv[15]

#           means before and after
            zhvMBefoAft        = np.zeros([2,4,2])
            
            zhvMBefoAft[0,0,0] = np.max(zh1)
            zhvMBefoAft[0,1,0] = np.mean(zh1)
            zhvMBefoAft[0,2,0] = np.min(zh1)
            zhvMBefoAft[1,0,0] = np.max(zv1)
            zhvMBefoAft[1,1,0] = np.mean(zv1)
            zhvMBefoAft[1,2,0] = np.min(zv1)

            l                  = np.rint(lhStart/32)
#            j = np.remainder(l+1, 4)
#            i = np.floor_divide(l,4)

            # light max area
            indexSortzh        = np.argsort(np.abs(zh1[1:17]))
            indexSortzv        = np.argsort(np.abs(zv1[1:17]))
#                if abs(zh1[indexSortzh[0]]+zv1[indexSortzv[0]]) > abs(zh1[indexSortzh[-1]]+zv1[indexSortzv[-1]]):
#                if (zh1[indexSortzh[0]]+zv1[indexSortzv[0]]) > (zh1[indexSortzh[-1]]+zv1[indexSortzv[-1]]):
#                    i = indexSortzh[0]
#                    j = indexSortzv[0]      
#                else:
#                    i = indexSortzh[-1]
#                    j = indexSortzv[-1]
            
            # plot pcolor/contourf around max
            i          = indexSortzh[-1]
            j          = indexSortzv[-1]      
                
            z[i-1,j+1] = np.abs(zh1[i-1]) + np.abs(zv1[j+1])
            z[i,  j+1] = np.abs(zh1[i])   + np.abs(zv1[j+1])
            z[i+1,j+1] = np.abs(zh1[i+1]) + np.abs(zv1[j+1])

            z[i-1,j]   = np.abs(zh1[i-1]) + np.abs(zv1[j])
            z[i,  j]   = np.abs(zh1[i])   + np.abs(zv1[j])     # valley
            z[i+1,j]   = np.abs(zh1[i+1]) + np.abs(zv1[j])
            
            z[i-1,j-1] = np.abs(zh1[i-1]) + np.abs(zv1[j-1])
            z[i,  j-1] = np.abs(zh1[i])   + np.abs(zv1[j-1])
            z[i+1,j-1] = np.abs(zh1[i+1]) + np.abs(zv1[j-1])
                
                  
                # print("cntr: %4d %3d %3d|%s|%s " % (lineCounterGlbl, i, j, ' '.join(map(str, indexSortzh)), ' '.join(map(str, indexSortzv))))
            
            # make 9 contourf         
            maxzh1     = np.max(np.abs(zh1[1:17]))
            minzh1     = np.min(np.abs(zh1[1:17]))
            maxDzh1    = maxzh1-minzh1
            if maxDzh1 == 0.0:
                maxDzh1 = 1.0
            
            maxzv1     = np.max(np.abs(zv1[1:17]))
            minzv1     = np.min(np.abs(zv1[1:17]))
            maxDzv1    = maxzv1-minzv1
            if maxDzv1 == 0.0:
                maxDzv1 = 1.0
            # print("maxDzh1 maxDzv1=",maxDzh1, maxDzv1)
            
            zhSum      = np.add(zhSum, np.abs(zh1))
            zvSum      = np.add(zvSum, np.abs(zv1))
            
            zhSumNorm  = np.add(zhSumNorm, (np.abs(zh1)-minzh1)/maxDzh1)
            zvSumNorm  = np.add(zvSumNorm, (np.abs(zv1)-minzv1)/maxDzv1)
        
            if l+1 == 1:
                axi = self.ax11
            elif l+1 == 2:
                axi = self.ax12
            elif l+1 == 3:
                axi = self.ax13
            elif l+1 == 4:
                axi = self.ax14
            elif l+1 == 5:
                axi = self.ax15
            elif l+1 == 6:
                axi = self.ax16
            elif l+1 == 7:
                axi = self.ax17
            elif l+1 == 8:
                axi = self.ax18
            else:
                print("Error (makeAcontourf): Wrong axis index and the program stops.")
                sys.exit()

            # axi.clear()
            
#                plt.subplot(2, 4, l+1)
            axi.hold(False)
            # levels = [-30000,-29000,-28000,-27000,-26000,-25000,-24000,-23000,-22000,-21000,-20000,-19000,-18000,-17000,-16000,-15000,-14000,-13000,-12000,-11000,-10000,-9000,-8000,-7000,-6000,-5000,-4000,-3000,-2000,-1000,0,1000,2000,3000,4000,5000,6000,7000,8000,9000,10000,11000,12000,13000,14000,15000,16000,17000,18000,19000,20000,21000,22000,23000,24000,25000,26000,27000,28000,29000,30000]
             
            cs = axi.contourf(self.x, self.y, z[1:17,1:17], level1, cmap=plt.cm.hot)   # hot gnuplot2 afmhot
            
            if displayLevel > 0:
                axi.hold(True)
                axi.plot((np.abs(zh1[1:17]-minzh1)/maxDzh1) + 1, self.x, color='darkorange')
                axi.hold(True)
                axi.plot(self.y, (np.abs(zv1[1:17]-minzv1))/maxDzv1 + 1, color='coral')
                axi.tick_params(axis='x', labelsize=7)  
                axi.tick_params(axis='y', labelsize=7)
            
            if l+1==1:
                axi.set_ylabel("Antennas (algo 1)")    
 
        # end of loop lhStart
            

        # make averages based on 8 frequencies
        zhSumNormAvg       = zhSumNorm / 8
        zvSumNormAvg       = zvSumNorm / 8
        
        zhvMBefoAft[0,0,0] = np.min(zhSum)  / 8
        zhvMBefoAft[0,1,0] = np.mean(zhSum) / 8
        zhvMBefoAft[0,2,0] = np.max(zhSum)  / 8
        zhvMBefoAft[0,3,0] = np.std(zhSum)  / 8
        zhvMBefoAft[1,0,0] = np.min(zvSum)  / 8
        zhvMBefoAft[1,1,0] = np.mean(zvSum) / 8
        zhvMBefoAft[1,2,0] = np.max(zvSum)  / 8
        zhvMBefoAft[1,3,0] = np.std(zvSum)  / 8
        
        # sorting and get the max and min
        indexSortzhSum = np.argsort(zhSumNormAvg[1:17])
        indexSortzvSum = np.argsort(zvSumNormAvg[1:17])
        
        iMax           = indexSortzhSum[-1] + 1
        jMax           = indexSortzvSum[-1] + 1
        iMin           = indexSortzhSum[0]  + 1
        jMin           = indexSortzvSum[0]  + 1
        
        zhMaxSum       = np.log(np.abs(zhSumNormAvg[iMax]) + 1)
        zhMinSum       = np.log(np.abs(zhSumNormAvg[iMin]) + 1)
        maxDzhSum      = zhMaxSum-zhMinSum
        if maxDzhSum==0:
            maxDzhSum  = 1
            
        zvMaxSum       = np.log(np.abs(zvSumNormAvg[jMax]) + 1)
        zvMinSum       = np.log(np.abs(zvSumNormAvg[jMin]) + 1)
        maxDzvSum      = zvMaxSum-zvMinSum
        if maxDzvSum==0:
            maxDzvSum  = 1
        
        zhSumLogNorm   = (np.log(np.abs(zhSumNormAvg) + 1) - zhMinSum) / maxDzhSum
        zvSumLogNorm   = (np.log(np.abs(zvSumNormAvg) + 1) - zvMinSum) / maxDzvSum

        # print("zhSumNorm zvSumNorm=", zhMinSum,zhMaxSum, -zhMinSum+zhMaxSum, zvMinSum,zvMaxSum, -zvMinSum+zvMaxSum,     zhSumNorm, zvSumNorm)
        
        
        # plot the big contourf  ax0
        ax33 = self.ax33
        ax44 = self.ax44
        ax22 = self.ax22
        # print ("the last picture:  

        # ignore or worth chwcking                
        stdh = zhvMBefoAft[0,3,0] 
        stdv = zhvMBefoAft[1,3,0]  
        
        if write2File:
#            for iTmp in range(1,17):
#                print("%+6.3e " % (zhSumNormAvg[iTmp]), end='')
#            print("%+6.3e " % (stdh), end='')
#            for iTmp in range(1,17):
#                print("%+6.3e " % (zvSumNormAvg[iTmp]), end='')
#            print("%+6.3e" % (stdv))
            
            for iTmp in range(1,17):
                hFile.write("%+6.3e " % (zhSumNormAvg[iTmp])) 
            hFile.write("%+6.3e " % (stdh))
            
            for iTmp in range(1,17):
                 hFile.write("%+6.3e " % (zvSumNormAvg[iTmp]))
             
            hFile.write("%+6.3e\n" % (stdv))
 
        if k == 17:
            aaa=0
            
        if stdh>thresholdStd or stdv>thresholdStd:             
       #  if zhMaxSum-zhMinSum>worth2Check or zvMaxSum-zvMinSum>worth2Check:
            
        # renorm the values for better fittig
            maxzhNorm      = np.max(zhSumNormAvg[1:17])
            minzhNorm      = np.min(zhSumNormAvg[1:17])
            maxDzhNorm     = maxzhNorm-minzhNorm
            if maxDzhNorm == 0.0:
                maxDzhNorm = 1.0
            maxzvNorm      = np.max(zvSumNormAvg[1:17])
            minzvNorm      = np.min(zvSumNormAvg[1:17])
            maxDzvNorm     = maxzvNorm-minzvNorm
            if maxDzvNorm == 0.0:
                maxDzvNorm = 1.0
            
            zhSum2NormAvg  = (zhSumNormAvg[1:17]-minzhNorm)/maxDzhNorm
            zvSum2NormAvg  = (zvSumNormAvg[1:17]-minzvNorm)/maxDzvNorm
#            print("zh zv=%6.2e %6.2e %6.2e %6.2e %6.2e %6.2e %6.2e %6.2e" % (np.max(zhSumNormAvg), np.min(zhSumNormAvg), np.max(zhSum2NormAvg), np.min(zhSum2NormAvg), np.max(zvSumNormAvg), np.min(zvSumNormAvg), np.max(zvSum2NormAvg), np.min(zvSum2NormAvg)))
            
            if False:   # use fit 16 point
            
                zhCombine,  = self.fitAndEvalue(self.x, zhSum2NormAvg, iMax, 0.05, self.x)
                zvCombine,  = self.fitAndEvalue(self.x, zvSum2NormAvg, jMax, 0.05, self.y)
            elif True: # use fit 32 points
                
                xInterp             = np.linspace(0, 15, numOfVirtualAntenna)
                yInterp             = np.linspace(0, 15, numOfVirtualAntenna)
                interpFun4h         = interpolate.interp1d(self.x, zhSum2NormAvg)
                interpFun4v         = interpolate.interp1d(self.y, zvSum2NormAvg)
                zhSum2NormAvgInterp = interpFun4h(xInterp)
                zvSum2NormAvgInterp = interpFun4v(yInterp)
                indexXMin           = np.argmin(zhSum2NormAvgInterp)
                indexYMin           = np.argmin(zvSum2NormAvgInterp)
                indexXMax           = np.argmax(zhSum2NormAvgInterp)
                indexYMax           = np.argmax(zvSum2NormAvgInterp)
                
                zhSum2NormAvgInterp = (zhSum2NormAvgInterp-zhSum2NormAvgInterp[indexXMin]) / (zhSum2NormAvgInterp[indexXMax]-zhSum2NormAvgInterp[indexXMin])
                zvSum2NormAvgInterp = (zvSum2NormAvgInterp-zvSum2NormAvgInterp[indexYMin]) / (zvSum2NormAvgInterp[indexYMax]-zvSum2NormAvgInterp[indexYMin])

                zhCombine, iGCxnorm  = self.fitAndEvalue(xInterp, zhSum2NormAvgInterp, 1, 0.01, xInterp)
                zvCombine, iGCynorm  = self.fitAndEvalue(yInterp, zvSum2NormAvgInterp, 1, 0.01, yInterp)
                # search new max
                indexXMaxNew        = np.argmax(zhCombine)
                indexYMaxNew        = np.argmax(zvCombine)
            else:       # use normalized avg
                zhCombine  = zvSumLogNorm[1:17]
                zvCombine  = zvSumLogNorm[1:17]

            maxzhCombine   = np.max(zhCombine)
            minzhCombine   = np.min(zhCombine)
            maxDzhCombine  = maxzhCombine-minzhCombine
            if maxDzhCombine == 0.0:
                maxDzhCombine = 1.0

            maxzvCombine   = np.max(zvCombine)
            minzvCombine   = np.min(zvCombine)
            maxDzvCombine  = maxzvCombine-minzvCombine
            if maxDzvCombine == 0.0:
                maxDzvCombine = 1.0

            zhCombineNorm  = (zhCombine-minzhCombine)/maxDzhCombine
            zvCombineNorm  = (zvCombine-minzvCombine)/maxDzvCombine
                
#            print("zh zv=%6.2e %6.2e %6.2e %6.2e" % (np.max(zhCombineNorm), np.min(zhCombineNorm), np.max(zvCombineNorm), np.min(zvCombineNorm)))
            # print("zh zv=%6.2e %6.2e %6.2e %6.2e" % (np.max(zhSumLogNorm), np.min(zhSumLogNorm), np.max(zvSumLogNorm), np.min(zvSumLogNorm)))
                
            # axi.clear()
            ax33.hold(False)
           
#                for k in range(1, 17, 1):
#                    z[:,k] = zhSumNorm
#                for k in range(1, 17, 1):
#                    z[k,:] = z[k,:] + zvSumNorm
           
            # cut off picture: algo 3 ---------------------------------------------------------------
            for k in range(0, numOfVirtualAntenna):
                for l in range(0, numOfVirtualAntenna):
                    z3[k,l] = zhCombineNorm[k]*zvCombineNorm[l]
           
            ax33.contourf(xInterp, yInterp, z3, level2, cmap=plt.cm.hot)   # hot gnuplot2 afmhot
            
            # make a rectangle
            pointy1, pointy2 = getBoundaryIndex(zvCombineNorm, 0.1)
            pointx1, pointx2 = getBoundaryIndex(zhCombineNorm, 0.1)
#             
            print("Rect size: ", (pointx2-pointx1)/(numOfVirtualAntenna-1) * 69, (pointy2-pointy1)/(numOfVirtualAntenna-1) * 69)
            ax33.hold(True)
            # make a rectangule
            # size of rectangule
            dx = (16-1) * 80/83 / 2    # 0°
            dy = (16-1) * 45/83 / 2    # 0°
            centerY  = (16-1) * indexXMaxNew/(numOfVirtualAntenna-1)
            centerX  = (16-1) * indexYMaxNew/(numOfVirtualAntenna-1)
            # ax33.plot([indexYMaxNew-dx, indexYMaxNew+dx, indexYMaxNew+dx, indexYMaxNew-dx, indexYMaxNew-dx], [indexXMaxNew-dy, indexXMaxNew-dy, indexXMaxNew+dy, indexXMaxNew+dy, indexXMaxNew-dy],  color='orange')
            ax33.plot([centerX-dx, centerX+dx, centerX+dx, centerX-dx, centerX-dx], [centerY-dy, centerY-dy, centerY+dy, centerY+dy, centerY-dy],  color='orange')
            # ax33.plot(np.array([pointx1, pointx2, pointx2, pointx1, pointx1])*15/(numOfVirtualAntenna-1), np.array([pointy1, pointy1, pointy2,pointy2, pointy1])*15/(numOfVirtualAntenna-1),  color='blue')
            
# no marker for FOS
#            indexXMax           = np.argmax(zhCombineNorm)
#            indexYMax           = np.argmax(zvCombineNorm)
#           (indexXMax, indexYMax) = np.unravel_index(np.argmax(z3, axis=None), z3.shape)
#            ax33.hold(True)
#            ax33.plot(xInterp[indexYMax], yInterp[indexXMax], 'ro')   # make the center of Oru
            if displayLevel > 0:
                ax33.hold(True)
                ax33.plot(zhCombineNorm + 1, xInterp, color='red')
                ax33.hold(True)
                ax33.plot(zhSum2NormAvg + 1, self.x, color='blue')
                ax33.hold(True)
                ax33.plot(np.ones((len(self.x),1)), self.x, color='blue')
                ax33.hold(True)
                
                ax33.plot(yInterp, zvCombineNorm + 1, color='red')
                ax33.hold(True)
                ax33.plot(self.y, zvSum2NormAvg + 1, color='blue')
                ax33.hold(True)
                ax33.plot(self.y, np.ones((len(self.y),1)), color='blue')

            ax33.axis('scaled')
            ax33.set_xlim(0, 15)
            ax33.set_ylim(0, 15)



#  algo 4
            zhCombine, iGCynorm = self.fitAndEvalue(xInterp, zhSum2NormAvgInterp, 2, heightBoard/widthBoard, xInterp)
            zvCombine, iGCxnorm = self.fitAndEvalue(yInterp, zvSum2NormAvgInterp, 2, 1,                      yInterp)
            # search new max
            indexXMaxNew        = np.argmax(zhCombine)
            indexYMaxNew        = np.argmax(zvCombine)

            maxzhCombine   = np.max(zhCombine)
            minzhCombine   = np.min(zhCombine)
            maxDzhCombine  = maxzhCombine-minzhCombine
            if maxDzhCombine == 0.0:
                maxDzhCombine = 1.0

            maxzvCombine   = np.max(zvCombine)
            minzvCombine   = np.min(zvCombine)
            maxDzvCombine  = maxzvCombine-minzvCombine
            if maxDzvCombine == 0.0:
                maxDzvCombine = 1.0

            zhCombineNorm  = (zhCombine-minzhCombine)/maxDzhCombine
            zvCombineNorm  = (zvCombine-minzvCombine)/maxDzvCombine

            ax44.hold(False)
                      
            # cut off picture: algo 3 ---------------------------------------------------------------
            for k in range(0, numOfVirtualAntenna):
                for l in range(0, numOfVirtualAntenna):
                    z4[k,l] = zhCombineNorm[k]*zvCombineNorm[l]
           
            ax44.contourf(xInterp, yInterp, z4, level2, cmap=plt.cm.hot)   # hot gnuplot2 afmhot
            polygonOru = Polygon(patchOru*0.275 + 15*np.array([iGCxnorm, iGCynorm]), closed=True, linestyle='-', alpha=0.1)
            ax44.add_patch(polygonOru)
            print("iGC=", 15*np.array([iGCxnorm, iGCynorm]))
            
            ax44.hold(True)
            ax44.plot([centerX-dx, centerX+dx, centerX+dx, centerX-dx, centerX-dx], [centerY-dy, centerY-dy, centerY+dy, centerY+dy, centerY-dy],  color='orange')
            ax44.set_ylabel("Antennas (algo 4)")

            if displayLevel > 0:
                ax44.hold(True)
                ax44.plot(zhCombineNorm + 1, xInterp, color='red')
                ax44.hold(True)
                ax44.plot(zhSum2NormAvg + 1, self.x, color='blue')
                ax44.hold(True)
                ax44.plot(np.ones((len(self.x),1)), self.x, color='blue')
                ax44.hold(True)
                
                ax44.plot(yInterp, zvCombineNorm + 1, color='red')
                ax44.hold(True)
                ax44.plot(self.y, zvSum2NormAvg + 1, color='blue')
                ax44.hold(True)
                ax44.plot(self.y, np.ones((len(self.y),1)), color='blue')




            ax22.hold(False)
           
            # cut off picture: algo 2 ----------------------------------------------------------------
            for k in range(1, 17, 1):
                for l in range(1, 17, 1):
                    z[k,l] = zhSumLogNorm[k]*zvSumLogNorm[l]
            
            ax22.contourf(self.x, self.y, z[1:17,1:17], level2, cmap=plt.cm.hot)   # hot gnuplot2 afmhot


# not x and y exchange
            indexYMax           = np.argmax(zhSumLogNorm[1:17])
            indexXMax           = np.argmax(zvSumLogNorm[1:17])
#            (indexXMax, indexYMax) = np.unravel_index(np.argmax(z[1:17,1:17], axis=None), z[1:17,1:17].shape)
            ax22.hold(True)
            ax22.plot(self.x[indexXMax], self.y[indexYMax], 'ro')   # make the center of Oru
            ax22.set_ylabel("Antennas (algo 3)")

            if displayLevel > 0:
                ax22.hold(True)
                ax22.plot(zhSumLogNorm[1:17] + 1, self.x, color='blue')
                ax22.hold(True)
                ax22.plot(np.ones((len(self.x),1)), self.x, color='blue')
                ax22.hold(True)                
                ax22.plot(self.y, zvSumLogNorm[1:17] + 1, color='blue')
                ax22.plot(self.y, np.ones((len(self.y),1)), color='blue')
            
        else:
            # axi.clear()
            ax44.hold(False)
            ax44.contourf(self.x, self.y, np.zeros((16,16)), [0,10,100], cmap=plt.cm.hot)
            ax33.hold(False)
            ax33.contourf(self.x, self.y, np.zeros((16,16)), [0,10,100], cmap=plt.cm.hot)
            ax22.hold(False)
            ax22.contourf(self.x, self.y, np.zeros((16,16)), [0,10,100], cmap=plt.cm.hot)
#            ax33.axis('scaled')
#            ax33.set_xlim(0, 15)
#            ax33.set_ylim(0, 15)
                
        somePars00  = "lh: min=%4.1e avg=%4.1e max=%4.1e std=%4.1e  lv: min=%4.1e avg=%4.1e max=%4.1e std=%4.1e" % (zhvMBefoAft[0,0,0], zhvMBefoAft[0,1,0], zhvMBefoAft[0,2,0], zhvMBefoAft[0,3,0], zhvMBefoAft[1,0,0], zhvMBefoAft[1,1,0], zhvMBefoAft[1,2,0], zhvMBefoAft[1,3,0])
        ax33.set_title(somePars00, fontsize=8)
        ax33.set_ylabel("Antennas (algo 3)")


        
#        ax22.axis('scaled')
#        ax22.set_xlim(0, 15)
#        ax22.set_ylim(0, 15)
#        ax22.yaxis.tick_right()
        ax22.set_ylabel("Antennas (algo 2)")    
#        ax22.yaxis.set_label_position("right")         
 
        titleName = "Concept demonstration for vehicle detection (FOS) at time point: " + str(lineCounterGlbl)
        self.fig.suptitle(titleName, fontsize=14)
             
            # end of looping all entennas

        ax33.axis('scaled')
        ax33.set_xlim(0, 15)
        ax33.set_ylim(0, 15)

        ax44.axis('scaled')
        ax44.set_xlim(0, 15)
        ax44.set_ylim(0, 15)

        ax22.axis('scaled')
        ax22.set_xlim(0, 15)
        ax22.set_ylim(0, 15)
            
        plt.pause(1e-17)
        time.sleep(0.0001)
#        plt.connect('key_press_event', keyEvent)
#            plt.show()                            


                           
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


def main():
    global pause, indexLastDraw, index2Draw, lineCounterGlbl, hFile, write2File
                
    vd = Obj()

    #(self.numOfSample, numOfVar) = vd.horiVertSignalOriginal.shape
    
    keepGoing, pause = True, False
    
    index2Draw       = 0
    indexLastDraw    = -111
    # lineCounterGlbl = numOfSample4Avg
    write2File       = False
    if write2File:
        hFile = open("file4Fos.txt", "w") 

    while keepGoing:
        
        plt.connect('key_press_event', keyEvent)

        if controlParGlbl == 1:
            if not pause:
                indexLastDraw   = index2Draw 
                index2Draw      = np.max([index2Draw+1, numOfSample4Avg+1, vd.numOfSample])
                lineCounterGlbl = index2Draw-1
            if not pause:  
                vd.update(-1)
            else:
                plt.pause(0.1)
            #print('controlParGlbl pause=', controlParGlbl, pause, index2Draw)
        elif controlParGlbl == 2:
            if not pause:
                index2Draw = np.min([index2Draw+1, vd.numOfSample])
#                lineCounterGlbl = index2Draw-1

            #print('controlParGlbl pause=', controlParGlbl, pause, index2Draw)
            if not pause:  
                vd.update(index2Draw-1)
            else:
                plt.pause(0.1)

    plt.show()
    
        
if __name__ == "__main__":
    main()
    
