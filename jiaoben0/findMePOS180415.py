""" align.py
    testing steering model, watch data from other apps through file in disk, and process the data from saved datafile
    steering stuff and watching running data inspired from 
    https://cs.iupui.edu/~aharris/pygame/ch09/carVec.py http://engineeringdotnet.blogspot.de/2010/04/simple-2d-car-physics-in-games.html
    and other sources.
    Works with Python 3.4.4
    Built / created by W. Wang in 12.2017
"""
    
import numpy as np
import collections as cln

#import csv
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.patches as patches

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
parser.add_argument('-f', dest='dataFile', action="store",   default='posStream.txt', help='Data file (S-format) to be processed')
parser.add_argument('-n', dest='nameUnit', action="store",   default='.\\data\\NameUnit.xls',              help="Header of the dada file")
parser.add_argument('-d', dest='display',  action="store",   default='0', type=int,                        help="Display level")
parser.add_argument('--version',           action='version', version='%(prog)s 1.0')

args = parser.parse_args()

# set up data file
controlParGlbl = args.ctrlPar
# 0: manual
# 1: read log file from CANOE log file "secondaryLocation.asc"
# 2: read file in Soti format


dataFileDefault = r'posStream.txt'
#print(args.dataFile, "\n",dataFileDefault, args.dataFile==dataFileDefault, args.dataFile is dataFileDefault)
if controlParGlbl == 0:
    data2Process = ''
    print("\nStarting align to check steering model ... ...")
elif controlParGlbl == 1:
    path2WatchGlbl = r".\data" # look at the current directory
    if args.dataFile == dataFileDefault:
        file2WatchGlbl = "posStream.txt" # look for changes to a file called test.asc
        data2Process   = os.path.join(path2WatchGlbl, file2WatchGlbl)
    else:
        file2WatchGlbl = args.dataFile
        data2Process   = os.path.join(path2WatchGlbl, file2WatchGlbl)
    print("\nStarting to watch a running data ... ...")
    print("\nData to be processed: ", data2Process)
elif controlParGlbl == 2:
    path2file    = r".\data"           # default path
    if args.dataFile == dataFileDefault:
        data2Process = os.path.join(path2file, dataFileDefault)
    else:
        data2Process = os.path.join(path2file, args.dataFile)
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

displayLevel        = args.display

dataLineCounter     = 0             # count the line read from running data file
timReady            = False
numOfSample4Avg     = 5
numOfVirtualAntenna = 16

# global setup
worth2Check = 0.425

level1      = np.power(np.linspace(0, 1, 111), 1) * 111

levelTmp    = np.linspace(0,0.5, 50)
#level2      = (levelTmp-np.min(levelTmp))/(np.max(levelTmp)-np.min(levelTmp))
level2      = np.power(np.linspace(0, 1, 55), 1) *1.5

level3 = np.linspace(0, 0.5, 111)

indexGlbl       = 0             # index to control redraw trail. need to declare global if assignment in a function


# setup screen
os.environ['SDL_VIDEO_WINDOW_POS'] = '2,30' # window top-left corner
widthScreen     = int(350*2)
heightScreen    = int(500*2)

screenCntrGlbl  = (0,0) 
   
# Oru geometry
widthOruGeom    = 2*17.4
heightOruGeom   = 27

posSenderXrel   = 15.6
posSenderYrel   = 5.6
hypotenuse      = np.linalg.norm([posSenderXrel,posSenderYrel])
alpha           = np.rad2deg(np.arctan2(posSenderYrel, posSenderXrel))   # -180, 180
  
oru             = patches.Rectangle((0, 0), 1, 1, facecolor='black', alpha=0.50)

# receiver board geometry
widthBoard          = 43.4    # cm
heightBoard         = 46.3    # cm 
heightExtra         = 7     # cm          
centerReceiverLeft  = np.array([ widthBoard/2, -heightBoard/2-heightExtra/2])
centerReceiverRight = np.array([-widthBoard/2, -heightBoard/2-heightExtra/2])



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


def keyEvent(e):
    global pause, index2Draw, indexLastDraw, dataLineCounter, numOfSample4Avg, hFile, write2File


    print ("Message (keyEvent): exit from findeMe forced by quit key (%s)." % (e.key))
    if (e.key == "q") or (e.key == "Q"):
        # print("\nExit from findMe.")

        # sys.exit(0)
        if write2File:
            hFile.close() 

        os._exit(0)  # hammer exit no clean up
        # raise SystemExit(...)
    elif (e.key == "p") or (e.key == "P") or (e.key == " "):
        pause = True
    elif (e.key == "c") or (e.key == "C"):
        pause = False
    elif (e.key == "r") or (e.key == "R"):
        pause           = False
        index2Draw      = 0
        dataLineCounter = 0
        indexLastDraw   = -111

        
def getRunningData(Object):
#    global dataLineCounter
    
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

#    dataLineCounter += 1
    # print("results: ", results)
#   For each change, check to see if it's updating the file we're interested in
    for action, file in results:
#       full_filename = os.path.join (path2WatchGlbl, file)
        # print (hOfFileGlbl, file, dataLineCounter, file2WatchGlbl, ACTIONS.get (action, "Unknown"), results)
        if file == file2WatchGlbl:
            first        = hOfFileGlbl.readline()                   # Read the first line.
            # print ("aaa=", file, first)
            try:
                hOfFileGlbl.seek(-2, os.SEEK_END)                       # Jump to the second last byte.
                while hOfFileGlbl.read(1) != b"\n":                     # Until EOL is found...
                    hOfFileGlbl.seek(-2, os.SEEK_CUR)                   # ...jump back the read byte plus one more.
                lineLast      = hOfFileGlbl.readline().decode()         # Read last line.
                
    #            print("not eq: ", np.array_equal(dataFromFile, Object.lastValue), dataFromFile, Object.lastValue)
                        
                varTmp        = processData(lineLast)
                if len(varTmp) > 0:

                    dataFromFile = varTmp[21:93]
                    if np.array_equal(dataFromFile, Object.lastValue):
                        Object.lastValue = dataFromFile
                        dataFromFile = np.array([])
            except OSError:
                continue    # do nothing this time and do next
                errorNo, ErrorName = err.args
#                print("errorNo, ErrorName = ", errorNo, ErrorName)
                
                # deal with only one line in file
#                if ErrorName=='Invalid argument':
#                    varTmp = processData(first.decode())
#                    if len(varTmp)>0:
#                        Object.lastValue = varTmp
                    
            # print("getRunningData: ", dataLineCounter, len(Object.posOfRef), len(Object.posOfSecPri), len(Object.oriOfSecPri),len(Object.posOfSecSec))
#            lineNew = hOfFileGlbl.read()
#            if lineNew != "":
#                dataFromFile = processData(lineNew)
#                break
        # time.sleep(1)
        # threading.Timer(2, Object.checkControlKeys).start()  # not working
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



def getAngle(xrlx, xrly, xlly, xllx, centerSenderPosX, centerSenderPosY):
    global hFile, write2File, xrlx0, xrly0, xlly0, xllx0
    
    # xrlx  xrly      xlly  xllx
    #  |    ---       ---    |
        
    # mean strength
    strengthMean    = np.mean([xrlx, xrly, xlly, xllx])
    
    # real left and right
    distLeft        = np.linalg.norm([centerSenderPosX-centerReceiverLeft[0],  centerSenderPosY-centerReceiverLeft[1]])
    distRight       = np.linalg.norm([centerSenderPosX-centerReceiverRight[0], centerSenderPosY-centerReceiverRight[1]])
   
   # use 1/r4 rule to balance     
   
    ratioLeft2Right = np.power(distRight/distLeft, 3.3)
    
    senderProjectX  = centerSenderPosX - centerReceiverLeft[0]
    senderProjectY  = centerSenderPosY - centerReceiverLeft[1]
    
    dlx         = xllx-xrlx*ratioLeft2Right
    dly         = xlly-xrly*ratioLeft2Right


    angle           = np.rad2deg(np.arctan2(0.5*(dlx+dly),strengthMean))
    # angle           = np.rad2deg(np.arctan2(dlx+dly, strengthMean))
#    print("ratio: %+6.3e %+6.3e %+6.3e|%+6.3e %+6.3e|%+6.3e %+6.3e %+6.3e %+6.3e|%+6.3e" % (ratioLeft2Right, distRight, distLeft, dlx,dly, xrlx, xrly, xlly, xllx, angle))
    if write2File:
        hFile.write("%+6.3e %+6.3e %+6.3e %+6.3e %+6.3e %+6.3e %+6.3e %+6.3e %+6.3e %+6.3e\n" % (ratioLeft2Right, distRight, distLeft, dlx,dly, xrlx, xrly, xlly, xllx, angle))
    
    xrlx0, xrly0, xlly0, xllx0 = xrlx, xrly, xlly, xllx
    
    return angle




def moveOru2(x, y, angle):
    
    oru.set_width(widthOruGeom)
    oru.set_height(heightOruGeom)
    
    oru.set_xy([x, y])
    # patch._angle = -np.rad2deg(yaw[i])
    oru._angle = angle
    # print("x y angle=", x, y, angle)
    return oru
        
        
        
def getHoriVertSignal(dataFile):
    
# note: dataField has to be delimited with a single SPC
    
    if dataFile:
        try:
# 22                  23                  24                  25                  26                 27                 28                 29                 30              31              32 ... ...              93
# POS_FAR_RIGHT_LY_RE POS_FAR_RIGHT_LY_IM POS_FAR_RIGHT_LX_RE POS_FAR_RIGHT_LX_IM POS_FAR_LEFT_LY_RE POS_FAR_LEFT_LY_IM POS_FAR_LEFT_LX_RE POS_FAR_LEFT_LX_IM POS_NEAR_LV1_RE POS_NEAR_LV1_IM POS_NEAR_LV2_RE ... ... POS_NEAR_LH16_IM
            horiVertSignal = np.loadtxt(dataFile, delimiter=" ", usecols=[i for i in range(21,93)])   # all lh's and lv's
             
        except FileNotFoundError:
            print("\nError: Wrong file or file path and exit from findMe.")

            sys.exit()
    else:
        horiVertSignal = np.array([])
        
    return horiVertSignal
    



class Obj:

    def __init__(self):
        
        global indexGlbl, screenCntrGlbl, dataLineCounter, timReady, hOfOru
        self.lastValue      = np.array([])
        self.numOfSample    = 0
        self.horiVertSignal = np.array([])

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

        # get all data in
        if (controlParGlbl == 2):
         
            self.horiVertSignal          = getHoriVertSignal(data2Process)
            (self.numOfSample, numOfVar) = self.horiVertSignal.shape
            print("Message (Obj): ", self.numOfSample, " data point read from ", data2Process)
            self.posFarReIm              = self.horiVertSignal[:,0:8]
            self.posNearlvReIm           = self.horiVertSignal[:,8:40]
            self.posNearlhReIm           = self.horiVertSignal[:,40:72]
            
        else:
            self.horiVertSignal = np.array([]);
        
        
        if len(self.horiVertSignal)>0:
            (numOfSample, numOfVar) = self.horiVertSignal.shape
        else:
            numOfSample = 0
            numOfVar    = 0
        
        self.x = np.linspace(0,15, 16)
        self.y = np.linspace(0,15, 16)
        
        # prepare figures
        self.fig, self.ax = plt.subplots(figsize=(24, 8.1), sharex='col', sharey='row')
        self.ax0 = plt.subplot2grid((1, 3), (0, 0))
        self.ax1 = plt.subplot2grid((1, 3), (0, 1))
        self.ax2 = plt.subplot2grid((1, 3), (0, 2))
        
        self.fig.subplots_adjust(bottom=0.04, left=0.02, right=0.98, hspace=0.2, wspace=0.1)
#        self.fig.suptitle('FOD / vehicle detection signals', fontsize='large')
        
        # self.fig.canvas.mpl_connect('key_press_event', keyEvent)

#       self.interp = 'nearest'
        self.interp = 'bilinear'

        hOfOru = self.ax2.add_patch(oru)
        
  
  
    def func(self, x, a, b, c):       
        
        # hyperbolic th(x): works
        # func(xdata, 0.8, -4, 0.7)
        # 
        y = c*0.5*(1-np.tanh(a*x+b))
        
        return y

        

    def update(self, k): # for every frame of car class    
 
        if controlParGlbl == 1: # driven by log file change
                        
            # now follow the running dtat
            while True:
                self.horiVertSignal = getRunningData(self)   # things are assigned in deques posOfRef, posOfSecPri, posOfSecSec
                
                if (len(self.horiVertSignal)>0) :
                    break
                    
            self.posFarReIm     = self.horiVertSignal[0:8]
            self.posNearlvReIm  = self.horiVertSignal[8:40]
            self.posNearlhReIm  = self.horiVertSignal[40:72]
            
            self.makeAcontourf(k)

            
        elif controlParGlbl == 2: # based on data file from positioning test
        

            self.makeAcontourf(k)



    def fitAndEvalue(self, x, y, m, d, xn):
        
        # make a curve fit and evaluate the values on xn
        indexMax     = np.argmax(y)
        yMax         = y[indexMax]
        xTemp        = np.zeros(numOfVirtualAntenna)
        yTemp        = np.zeros(numOfVirtualAntenna)
        yn           = np.zeros(numOfVirtualAntenna)

        numOfPoint   = len(x)       # = 16
        thresholdLow = 0.4
#        condition    = y>=thresholdLow*yMax
#        areaHalf     = 0.5*np.sum(y[condition])
        
        # get practical threshold
        # yNewThreshold = np.max([y[0], y[15], thresholdLow*yMax])
        yNewThreshold = thresholdLow*yMax
        
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
            # if y[iLeft-2]-y[iLeft-1]>0.15:   # check gradient
                # search to the left
                
                for i in range(iLeft-2,-1, -1):
                    sumOfyLeft = sumOfyLeft + y[i]
                    if y[i]<yNewThreshold:
                        iLeft  = i
                        break                
            
        iRight         = np.min([indexMax+1, numOfPoint])   # del with right border issue
        found          = False
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
        if iRight == indexMax:
            iGravityCenter = iRight
        elif iLeft == indexMax:
            iGravityCenter = iLeft
        elif iRight<iLeft+numOfVirtualAntenna/2:
            iGravityCenter = iLeft
            sumOfyHalf     = 0
            found          = False
            for i in range(iLeft, iRight):
                sumOfyHalf = sumOfyHalf + y[i]             
                if sumOfyHalf>=0.5*sumOfy:
                    iGravityCenter = i
                    break
        else:
            iGravityCenter = int((iLeft+iRight)/2)
                    
        # fold both sides together based on iGravityCenter
        
        if iGravityCenter==0:
            xTemp                      = x
            yTemp                      = y
            yTemp[iRight:numOfPoint]     = 0.001 
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
            

                
# initiation of the function
        pInit      = [0.8, -indexMax, y[indexMax]]
        # popt, pcov = curve_fit(self.func, xTemp, yTemp, p0=pInit, method='trf', bounds=([1/16, -16.0, 0.0], [16, 16.0, 1.0]))
        popt, pcov = curve_fit(self.func, xTemp, yTemp, p0=pInit, method='trf', bounds=([1/numOfVirtualAntenna, -numOfVirtualAntenna, 0.0], [numOfVirtualAntenna, numOfVirtualAntenna, 1.0]))

        # evalue fitted value on point xn
        yTemp        = self.func(xn, *popt)
        
        errorStd = np.std(yTemp)
       # print("errorStd pcov:",errorStd,np.sqrt(np.diag(pcov)))

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
        
        return yn
    


    def getFarSignal(self, posFarReIm):           
        global xrlx0, xrly0, xlly0, xllx0, dataLineCounter

        if True:
            xrly = np.linalg.norm([posFarReIm[0], posFarReIm[1]])
            xrlx = np.linalg.norm([posFarReIm[2], posFarReIm[3]])
            xlly = np.linalg.norm([posFarReIm[4], posFarReIm[5]])
            xllx = np.linalg.norm([posFarReIm[6], posFarReIm[7]])
    
    #       normalize
            xllx = (xllx - 1.82e+05) / (2.34e+09-1.82e+05)
            xlly = (xlly - 1.82e+05) / (2.34e+09-1.82e+05)
            xrly = (xrly - 1.82e+05) / (2.34e+09-1.82e+05)
            xrlx = (xrlx - 1.82e+05) / (2.34e+09-1.82e+05)
#  out jumps
#        if dataLineCounter>1:
#            if np.abs(xllx-xllx0)>0.2:
#                xllx = xllx0 + 0.1*(xllx-xllx0)
#            if np.abs(xlly-xlly0)>0.2:
#                xlly = xlly0 + 0.1*(xlly-xlly0)
#            if np.abs(xrly-xrly0)>0.2:
#                xrly = xrly0 + 0.1*(xrly-xrly0)
#            if np.abs(xrlx-xrlx0)>0.2:
#                xrlx = xrlx0 + 0.1*(xrlx-xrlx0)
        else:

            xrly = np.log(np.linalg.norm([posFarReIm[0], posFarReIm[1]]))
            xrlx = np.log(np.linalg.norm([posFarReIm[2], posFarReIm[3]]))
            xlly = np.log(np.linalg.norm([posFarReIm[4], posFarReIm[5]]))
            xllx = np.log(np.linalg.norm([posFarReIm[6], posFarReIm[7]]))
    #       normalize
#            xllx = (xllx - 12.3) / (21.6-12.3)
#            xlly = (xlly - 12.3) / (21.6-12.3)
#            xrly = (xrly - 12.3) / (21.6-12.3)
#            xrlx = (xrlx - 12.3) / (21.6-12.3)
# filter out jumps
            if dataLineCounter<-111:
                if np.abs(xllx-xllx0)>0.2*step4Every*sampleTime:
                    xllx = xllx0 + 0.1*(xllx-xllx0)
                if np.abs(xlly-xlly0)>0.2*step4Every*sampleTime:
                    xlly = xlly0 + 0.1*(xlly-xlly0)
                if np.abs(xrly-xrly0)>0.2*step4Every*sampleTime:
                    xrly = xrly0 + 0.1*(xrly-xrly0)
                if np.abs(xrlx-xrlx0)>0.2*step4Every*sampleTime:
                    xrlx = xrlx0 + 0.1*(xrlx-xrlx0)

            
        xrlx0, xrly0, xlly0, xllx0 = xrlx, xrly,xlly, xllx
        
        return xrlx, xrly, xlly, xllx
        
        
 
    def makeAcontourf(self, k):   # make one pcolor plate

        global indexGlbl, dataLineCounter, worth2Check, level1, level2, level3, xllx, xlly, xrlx, xrly, hOfOru, horiNorm0, vertNorm0, sampleTime


        dataLineCounter += 1
        
        # get rid of noise with tim
        if k == -1:
            self.horiVertSignal = self.horiVertSignal          # ????
        else:
            self.horiVertSignal[k,8:72] = self.horiVertSignal[k,8:72]    # ????
    
        zh1          = np.zeros(18)         # get filled from 0 to 17
        zv1          = np.zeros(18)         # get filled from 0 to 17

        zhSum        = np.zeros(18)
        zvSum        = np.zeros(18)
        zhSumNorm    = np.zeros(18)
        zvSumNorm    = np.zeros(18)
#        zhSumLog     = np.zeros(18)
#        zvSumLog     = np.zeros(18)
        zhSumLogNorm = np.zeros(18)
        zvSumLogNorm = np.zeros(18)
        
        
        # make magnitude from Real and Imaginary parts
        zh = np.zeros(17)
        zv = np.zeros(17)
        z  = np.zeros((18,18))      # 0-17, 0-17
        z3 = np.zeros((numOfVirtualAntenna,numOfVirtualAntenna))      

            
        if k == -1:
            # far antenna

            xrlx, xrly, xlly, xllx = self.getFarSignal(self.posFarReIm) 
                            
            # near antenna only on set 16 h and 16 v
            for l in range(0,16,1):
                lh    = l*2
                zh[l] = np.linalg.norm([self.posNearlhReIm[lh], self.posNearlhReIm[lh+1]])
            for l in range(0,16,1):
                lv    = l*2
                zv[l]  = np.linalg.norm([self.posNearlvReIm[lv], self.posNearlvReIm[lv+1]])
        else:
            # far antenna  
            xrlx, xrly, xlly, xllx = self.getFarSignal(self.posFarReIm[k,:]) 
                            
            # near antenna only on set 16 h and 16 v
            for l in range(0,16,1):
                lh    = l*2
                zh[l] = np.linalg.norm([self.posNearlhReIm[k,lh], self.posNearlhReIm[k,lh+1]])
            for l in range(0,16,1):
                lv    = l*2
                zv[l]  = np.linalg.norm([self.posNearlvReIm[k,lv], self.posNearlvReIm[k,lv+1]])

        zh1[0]    = zh[0]
        zh1[1:17] = zh[0:16]
        zh1[17]   = zh[15]
        zv1[0]    = zv[0]
        zv1[1:17] = zv[0:16]
        zv1[17]   = zv[15]
        zh1[0]    = zh[0]
        
#           means before and after
        zhvMBefoAft        = np.zeros([2,4,2])
        
        zhvMBefoAft[0,0,0] = np.max(zh1)
        zhvMBefoAft[0,1,0] = np.mean(zh1)
        zhvMBefoAft[0,2,0] = np.min(zh1)
        zhvMBefoAft[1,0,0] = np.max(zv1)
        zhvMBefoAft[1,1,0] = np.mean(zv1)
        zhvMBefoAft[1,2,0] = np.min(zv1)


#            j = np.remainder(l+1, 4)
#            i = np.floor_divide(l,4)

        # light max area
        indexSortzh = np.argsort(np.abs(zh1[1:17]))
        indexSortzv = np.argsort(np.abs(zv1[1:17]))
#                if abs(zh1[indexSortzh[0]]+zv1[indexSortzv[0]]) > abs(zh1[indexSortzh[-1]]+zv1[indexSortzv[-1]]):
#                if (zh1[indexSortzh[0]]+zv1[indexSortzv[0]]) > (zh1[indexSortzh[-1]]+zv1[indexSortzv[-1]]):
#                    i = indexSortzh[0]
#                    j = indexSortzv[0]      
#                else:
#                    i = indexSortzh[-1]
#                    j = indexSortzv[-1]
        
        # plot pcolor/contourf around max
        im1 = indexSortzh[-1]  
        jm1 = indexSortzv[-1]       
        i   = im1 + 1
        j   = jm1 + 1
        # simple algorithm
#        z[i-1,j+1] = np.abs(zh1[i-1]) + np.abs(zv1[j+1])
#        z[i,  j+1] = np.abs(zh1[i])   + np.abs(zv1[j+1])
#        z[i+1,j+1] = np.abs(zh1[i+1]) + np.abs(zv1[j+1])
#
#        z[i-1,j]   = np.abs(zh1[i-1]) + np.abs(zv1[j])
        z[i,  j]   = np.abs(zh1[im1])   + np.abs(zv1[jm1])     # valley
#        z[i+1,j]   = np.abs(zh1[i+1]) + np.abs(zv1[j])
#        
#        z[i-1,j-1] = np.abs(zh1[i-1]) + np.abs(zv1[j-1])
#        z[i,  j-1] = np.abs(zh1[i])   + np.abs(zv1[j-1])
#        z[i+1,j-1] = np.abs(zh1[i+1]) + np.abs(zv1[j-1])
            
              
        # print("cntr: %4d %3d %3d|%s|%s " % (dataLineCounter, i, j, ' '.join(map(str, indexSortzh)), ' '.join(map(str, indexSortzv))))
        
        # xxx      
        maxzh1     = np.max(np.abs(zh1[1:17]))
        minzh1     = np.min(np.abs(zh1[1:17]))
        maxDzh1    = maxzh1 - minzh1
        
        maxzv1     = np.max(np.abs(zv1[1:17]))
        minzv1     = np.min(np.abs(zv1[1:17]))
        maxDzv1    = maxzv1 - minzv1
        
        zhSum      = np.add(zhSum, np.abs(zh1))
        zvSum      = np.add(zvSum, np.abs(zv1))
        
        zhSumNorm  = np.add(zhSumNorm, (np.abs(zh1)-minzh1)/maxDzh1)
        zvSumNorm  = np.add(zvSumNorm, (np.abs(zv1)-minzv1)/maxDzv1)
    

        # 
        # subplot 2: second contourf: algo 2 based on max --------------------------------
        #
        axi = self.ax1

        axi.hold(False)
         
        cs = axi.contourf(self.x, self.y, z[1:17,1:17], 111, cmap=plt.cm.hot)   # hot gnuplot2 afmhot
        
        axi.hold(True)
        axi.plot(jm1, im1, 'ro')   # make the center of Oru
        if displayLevel > 0:
            axi.hold(True)
            axi.plot((np.abs(zh1[1:17]-minzh1)/maxDzh1) + 1, self.x, color='darkorange')
            axi.hold(True)
            axi.plot(self.y, (np.abs(zv1[1:17]-minzv1))/maxDzv1 + 1, color='coral')
            
        # axi.axis('scaled')
        axi.set_xlim(0, 15)
        axi.set_ylim(0, 15)
#        axi.tick_params(axis='x', labelsize=11)  
#        axi.tick_params(axis='y', labelsize=11)   
        axi.set_title("Algo 2 for near antennas")
        axi.set_xlabel("Antenna (v)")    
        axi.set_ylabel("Antennas (h)")    
            

        # make averages
        zhSumNormAvg   = zhSumNorm
        zvSumNormAvg   = zvSumNorm 
        
        zhvMBefoAft[0,0,0] = np.min(zhSum)  
        zhvMBefoAft[0,1,0] = np.mean(zhSum) 
        zhvMBefoAft[0,2,0] = np.max(zhSum)  
        zhvMBefoAft[0,3,0] = np.std(zhSum)  
        zhvMBefoAft[1,0,0] = np.min(zvSum)  
        zhvMBefoAft[1,1,0] = np.mean(zvSum) 
        zhvMBefoAft[1,2,0] = np.max(zvSum)  
        zhvMBefoAft[1,3,0] = np.std(zvSum)  
        
        # sorting and get the max and min
        indexSortzhSum = np.argsort(zhSumNormAvg[1:17])
        indexSortzvSum = np.argsort(zvSumNormAvg[1:17])
        
        iMax           = indexSortzhSum[-1] + 1
        jMax           = indexSortzvSum[-1] + 1
        iMin           = indexSortzhSum[0]  + 1
        jMin           = indexSortzvSum[0]  + 1
        
        zhMaxSum       = np.log(np.abs(zhSumNormAvg[iMax]) + 1)
        zvMaxSum       = np.log(np.abs(zvSumNormAvg[jMax]) + 1)
        zhMinSum       = np.log(np.abs(zhSumNormAvg[iMin]) + 1)
        zvMinSum       = np.log(np.abs(zvSumNormAvg[jMin]) + 1)

        zhSumLogNorm   = (np.log(np.abs(zhSumNormAvg) + 1) - zhMinSum) / (zhMaxSum - zhMinSum)
        zvSumLogNorm   = (np.log(np.abs(zvSumNormAvg) + 1) - zvMinSum) / (zvMaxSum - zvMinSum)

        # print("zhSumNorm zvSumNorm=", zhMinSum,zhMaxSum, -zhMinSum+zhMaxSum, zvMinSum,zvMaxSum, -zvMinSum+zvMaxSum,     zhSumNorm, zvSumNorm)
        
        #
        # subplot 1: first contourf for near antenna (1. algo)------------------------------
        #
        axi = self.ax0

        # ignore or worth checking                
        stdh = zhvMBefoAft[0,3,0] 
        stdv = zhvMBefoAft[1,3,0]  
        if stdh>0.01 or stdv>0.01:             
       #  if zhMaxSum-zhMinSum>worth2Check or zvMaxSum-zvMinSum>worth2Check:
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

            xInterp             = np.linspace(0, 15, numOfVirtualAntenna)
            yInterp             = np.linspace(0, 15, numOfVirtualAntenna)
            interpFun4h         = interpolate.interp1d(self.x, zhSum2NormAvg)
            interpFun4v         = interpolate.interp1d(self.y, zvSum2NormAvg)
            zhSum2NormAvgInterp = interpFun4h(xInterp)
            zvSum2NormAvgInterp = interpFun4v(yInterp)
            indexXMax           = np.argmax(zhSum2NormAvgInterp)
            indexYMax           = np.argmax(zvSum2NormAvgInterp)

            zhCombine  = self.fitAndEvalue(xInterp, zhSum2NormAvgInterp, indexXMax, 0.01, xInterp)
            zvCombine  = self.fitAndEvalue(yInterp, zvSum2NormAvgInterp, indexYMax, 0.01, yInterp)

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
                
                
                
                
            axi.hold(False)           
            #
            # subplot 1: simpler algorithm 1: dim and not dim ----------------------------
            #
            for k in range(0, numOfVirtualAntenna):
                for l in range(0, numOfVirtualAntenna):
                    z3[k,l] = zhCombineNorm[k]*zvCombineNorm[l] * zhCombineNorm[k]*zvCombineNorm[l] * zhCombineNorm[k]*zvCombineNorm[l] * zhCombineNorm[k]*zvCombineNorm[l]* zhCombineNorm[k]*zvCombineNorm[l]* zhCombineNorm[k]*zvCombineNorm[l]                  
                        
            # find the max in k and l for Far algo
            (iMax4Far, jMax4Far) = np.unravel_index(np.argmax(z3, axis=None), z3.shape)

            axi.contourf(xInterp, yInterp, z3, level2, cmap=plt.cm.hot)   # hot gnuplot2 afmhot
            axi.hold(True)           
            axi.plot(jMax4Far, iMax4Far, 'ro')   # make the center of Oru

            if displayLevel > 0:
                axi.hold(True)
                axi.plot(zhCombineNorm + 1, xInterp, color='red')
                axi.hold(True)
                axi.plot(zhSum2NormAvg + 1, self.x, color='white')
                axi.hold(True)
                axi.plot(yInterp, zvCombineNorm + 1, color='red')
                axi.hold(True)
                axi.plot(self.y, zvSum2NormAvg + 1, color='white')
            
            somePars  = "lh: min=%4.1e avg=%4.1e max=%4.1e std=%4.1e  lv: min=%4.1e avg=%4.1e max=%4.1e std=%4.1e" % (zhvMBefoAft[0,0,0], zhvMBefoAft[0,1,0], zhvMBefoAft[0,2,0], zhvMBefoAft[0,3,0], zhvMBefoAft[1,0,0], zhvMBefoAft[1,1,0], zhvMBefoAft[1,2,0], zhvMBefoAft[1,3,0])
            axi.set_title(somePars, fontsize=7)
        else:
            # axi.clear()
            axi.hold(False)
            axi.contourf(self.x, self.y, np.zeros((16,16)), [0,10,100], cmap=plt.cm.hot)
            
        # axi.axis('scaled')
        axi.set_xlim(0, 15)
        axi.set_ylim(0, 15)
#        axi.tick_params(axis='x', labelsize=11)  
#        axi.tick_params(axis='y', labelsize=11)   
        axi.set_xlabel("Antenna (v)")    
        axi.set_ylabel("Antenna (h)")    

        #
        # subplot 3: third conturf for FAR antennas (algo 1)------------------------------
        #

        axi              = self.ax2
        #  screen grid   
        x                = np.linspace(-widthBoard/2,           widthBoard/2,  56)
        y                = np.linspace(-heightBoard/2-heightExtra, heightBoard/2, 64)

        # sender position
        horiNorm         = jMax4Far / (numOfVirtualAntenna-1) 
        vertNorm1        = iMax4Far / (numOfVirtualAntenna-1)
        vertNorm         = 1 - heightBoard/(heightBoard+heightExtra) * (numOfVirtualAntenna-1-iMax4Far)/(numOfVirtualAntenna-1)
        
        #filter out near-field jumps
        if dataLineCounter<-111:
            if np.abs(horiNorm-horiNorm0)>=7/15*step4Every*sampleTime:
                horiNorm = horiNorm0 + 0.1*(horiNorm-horiNorm0)
                
            if np.abs(vertNorm-vertNorm0)>=7/15*step4Every*sampleTime:
                vertNorm = vertNorm0 + 0.1*(vertNorm-vertNorm0)
        
        centerSenderPosX = widthBoard  * (horiNorm - 0.5)
        # centerSenderPosY = heightBoard * (vertNorm - (0.5*heightBoard+heightExtra)/(heightBoard+heightExtra))
        centerSenderPosY = heightBoard * (vertNorm1 - 0.5)   # + heightExtra
        
        z                = np.zeros((64,56))        # 0-63, 0-55
        
        
#       right and left need to be turned on table to match th e reality
        #  Y   X
        z[1:8, 2]          = z[1:8, 2]          + xrlx + 0.001   # left verticlly aligned:     l lx
        z[4,   4:11]       = z[4,   4:11]       + xrly + 0.001   # left horizontally  aligned: l ly
        z[4,   56-11:56-4] = z[4,   56-11:56-4] + xlly + 0.001   # left horizontally  aligned: r ly
        z[1:8, 56-3]       = z[1:8, 56-3]       + xllx + 0.001    # right verticlly aligned:   r lx
       
              
        
        # print("xllx xrlx=%8.3e %8.3e %8.3e %8.3e" %(xlly,xllx, xrlx,xrly))
        
#                            xllx     xlly     xrly     xrlx     mean
# xllx xlly xrly xrlx min: 2.53e+06 2.07e+06 2.17e+06 1.87e+06 2.16e+06
# xllx xlly xrly xrlx max: 2.27e+09 2.34e+09 2.35e+09 2.32e+09 2.32e+09

        # print("xllx xlly xrly xrlx: %5.2e %5.2e %5.2e %5.2e|%5.2e %5.2e %5.2e %5.2e" %(xllxNorm,xllyNorm,xrlyNorm,xrlxNorm, xllx,xlly,xrly,xrlx))

#        xPos = np.max([np.min([63,32-32*int((xllx+xrlx+xlly+xrly)/4/4e8)]),0])
#        yPos = np.max([np.min([55,26-32*int((xllx-xrlx+xlly-xrly)/4/4e8)]),0])
#        
#        xOri = np.max([np.min([63, 32- 32*int((xllx+xrlx-xlly-xrly)/4/4e8)]),0])
#        yOri = 32
        #print ("x y x y:", yPos,xPos, yOri, xOri)
        
#        z[xPos, yPos] = 55e7
#        z[xOri, yOri] = 11e7
        axi.hold(False)           
        
        axi.contourf(x, y, z, 111, cmap=plt.cm.rainbow)   # hot gnuplot2 afmhot
        
        axi.hold(True)           
        axi.plot(centerSenderPosX, centerSenderPosY, 'ro')   # make the center of Oru
        
        # draw the bottpm frame 
        axi.plot([-widthBoard/2,  -widthBoard/2+9, -widthBoard/2+9,             widthBoard/2-9,             widthBoard/2-9, widthBoard/2], \
                 [-heightBoard/2, -heightBoard/2,  -heightBoard/2-heightExtra, -heightBoard/2-heightExtra, -heightBoard/2, -heightBoard/2], '-w')
 

        axi.axis('scaled')
        
        # hOfOru.remove()
        angle     = getAngle(xrlx, xrly, xlly, xllx, centerSenderPosX, centerSenderPosY)
        
#        angle     = (-dlxNorm-dlyNorm)*1000
        rad       = np.deg2rad(angle+alpha)
        posHorilb = centerSenderPosX - hypotenuse*np.cos(rad)
        posVertlb = centerSenderPosY - hypotenuse*np.sin(rad)
#        print("posHorilb centerSenderPosX, np.cos(rad):", posHorilb, centerSenderPosX, np.cos(rad))
        oru       = moveOru2(posHorilb, posVertlb, angle)
        hOfOru    = axi.add_patch(oru)
        
#        axi.tick_params(axis='x') # , labelsize=11)  
#        axi.tick_params(axis='y') # , labelsize=11)   
        axi.set_xlabel("y [cm]")    # 453mm
        axi.set_ylabel("x [cm]")    # 565mm
        axi.set_xlim(-widthBoard/2,  widthBoard/2)
        axi.set_ylim(-heightBoard/2-heightExtra, heightBoard/2)
        axi.set_title("Algo 1 for far antennas")
           
        titleName = "Concept demonstration for vehicle detection (NAS/FAS) at time point: " + str(dataLineCounter)
        self.fig.suptitle(titleName, fontsize=14)
                         
        plt.pause(1e-17)
        time.sleep(0.0001)
#       plt.show()                            

        horiNorm0, vertNorm0 = horiNorm, vertNorm
         
         
         

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
    global pause, indexLastDraw, index2Draw, dataLineCounter, xllx, xlly, xrlx, xrly, timeSegment, hFile, write2File, step4Every, sampleTime
                
    vd = Obj()
    keepGoing, pause = True, False
    
    sampleTime       = 1     # [s] by Canoe
    timeSegment      = 0
    if timeSegment==0:
        step4Every   = 1
    else:
        step4Every   = np.max([1, vd.numOfSample/timeSegment])

    index2Draw       = 0
    indexLastDraw    = -111
    xllxMin, xllyMin, xrlxMin, xrlyMin = 1e9,1e9,1e9,1e9
    xllxMax, xllyMax, xrlxMax, xrlyMax = -1e9,-1e9,-1e9,-1e9
    
    write2File = True

    if write2File:
        hFile = open("file4Far.txt", "w") 
    
    
    while keepGoing:
        
        plt.connect('key_press_event', keyEvent)

        if controlParGlbl == 1:
            if not pause:
                indexLastDraw   = index2Draw 
                index2Draw      = np.max([index2Draw+1, numOfSample4Avg+1, vd.numOfSample])
                dataLineCounter = index2Draw-1
            if not pause:  
                vd.update(-1)
            else:
                plt.pause(0.1)
            # print('controlParGlbl pause=', controlParGlbl, pause, index2Draw)
        elif controlParGlbl == 2:
            if not pause:
                # index2Draw = np.min([index2Draw, vd.numOfSample])+1
                indexLastDraw   = index2Draw 
                index2Draw      = np.min([index2Draw + int(step4Every), vd.numOfSample])
                if indexLastDraw==index2Draw:
                    
                    hFile.close() 
                    write2File = False
                    
                    print("Message(main): finished all ", index2Draw, " plots and press 'q' to exit.")
#                dataLineCounter = index2Draw-1

            # print('controlParGlbl pause=', controlParGlbl, pause, index2Draw)
            if not pause:  
                vd.update(index2Draw-1)
            else:
                plt.pause(1)
                
        xrlyMin = np.min([xrlyMin, xrly])
        xrlxMin = np.min([xrlxMin, xrlx])
        xllyMin = np.min([xllyMin, xlly])
        xllxMin = np.min([xllxMin, xllx])
        
        xrlyMax = np.max([xrlyMax, xrly])
        xrlxMax = np.max([xrlxMax, xrlx])
        xllyMax = np.max([xllyMax, xlly])
        xllxMax = np.max([xllxMax, xllx])
#        print("xllx  xlly xrly xrlx min: %10.7e %10.7e %10.7e %10.7e %10.7e %10.7e" %(xllxMin,xllyMin,xrlyMin,xrlxMin, np.min([xllxMin,xllyMin,xrlyMin,xrlxMin]), (xrlyMin+xrlxMin+xllyMin+xllxMin)/4))
#        print("xllx  xlly xrly xrlx max: %10.7e %10.7e %10.7e %10.7e %10.7e %10.7e" %(xllxMax,xrlyMax,xllyMax,xrlxMax, np.max([xllxMax,xrlyMax,xllyMax,xrlxMax]), (xrlyMax+xrlxMax+xllyMax+xllxMax)/4))
   
        
        
if __name__ == "__main__":
    main()
    
