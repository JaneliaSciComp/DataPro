//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

// The FancyCamera "object" wraps all the SIDX functions, so the Imager doesn't have to deal with 
// them directly.

// Note that these functions were originally based on example code provided by Lin Ci Brown 
// of the Bruxton Corporation.






// Construct the object
Function FancyCameraConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)

	// If the data folder doesn't exist, create it (and switch to it)
	if (!DataFolderExists("root:DP_FancyCamera"))
		// IMAGING GLOBALS
		NewDataFolder /O /S root:DP_FancyCamera
		
	endif

	// Initialize the camera
	CameraConstructor()
	
	// Restore the data folder
	SetDataFolder savedDF	
End






Function FancyCameraSetupAcquisition(isBinnedAndROIed,roisWave,isTriggered,exposure,targetTemperature,nBinWidth,nBinHeight)
	// This sets up the camera for a single acquisition.  (A single aquisition could be a single frame, or it could be a video.)  
	// This is typically called once per acquisition, just before the acquisition.
	//Variable image_roi
	Variable isBinnedAndROIed	// if true, do binning, and limit acquire to bounding box of all ROIs.  If false, don't bin, do full frames
	Wave roisWave
	Variable isTriggered
	Variable exposure	// frame exposure duration, in ms
	Variable targetTemperature
	Variable nBinWidth
	Variable nBinHeight
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FancyCamera

	// Declare instance variables
	
	// Set up stuff
	Variable nROIs=DimSize(roisWave,1)
	CameraROIClear()
	// Set the binning
	if (isBinnedAndROIed)
		CameraBinningSet(nBinWidth, nBinHeight)
	else
		CameraBinningSet(1, 1)
	endif
	// Set the camera ROI
	if (isBinnedAndROIed && (nROIs>0))
		Wave cameraROI=FancyCameraROIFromROIs(roisWave)
		CameraROISet(cameraROI[0], cameraROI[1], cameraROI[2], cameraROI[3])
	endif

	// Set the trigger mode
	Variable NO_TRIGGER=0	// start immediately
	Variable TRIGGER_EXPOSURE_START=1	// start of each frame is TTL-triggered
	Variable triggerMode=(isTriggered ? TRIGGER_EXPOSURE_START : NO_TRIGGER)
	CameraTriggerModeSet(triggerMode)
	
	// Set the exposure
	Variable exposureInSeconds=exposure/1000		// ms->s
	CameraExposeSet(exposureInSeconds)
	
	// Set the CCD temp, wait for it to stabilize
	FancyCameraSetTemperature(targetTemperature)
	
	// Restore the data folder
	SetDataFolder savedDF	
End






Function FancyCameraArm(nFrames)
	// Acquire nFrames, and store the resulting video in imageWaveName.
	// If isTriggered is true, each-frame must be TTL triggered.  If false, the 
	// acquisition is free-running.
	Variable nFrames

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FancyCamera

	// instance vars

	// Allocate space in the frame buffer
	CameraBufferCountSet(nFrames)

	// Arm the acquisition
	CameraAcquireArm()
	
	// Restore the original DF
	SetDataFolder savedDF
End







Function /WAVE FancyCameraAcquire(nFrames)
	// Acquire nFrames, and store the resulting video in imageWaveName.
	// If isTriggered is true, each-frame must be TTL triggered.  If false, the 
	// acquisition is free-running.

	Variable nFrames
	//Variable isTriggered

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FancyCamera

	// instance vars
	
	// Prep for the acquisition (this will also start the acquisition unless it's a triggered acquire)
	CameraAcquireStart()

	// If the acquisition is external trigger mode, start the data acq, which will provide the per-frame triggers
	Variable NO_TRIGGER=0		// start immediately
	if (CameraTriggerModeGet()!=NO_TRIGGER)
		SweeperControllerAcquireTrial()	
	endif

	// Spin until the acquisition is done
	Variable isAcquiring
	do
		Sleep /S 0.1		// Sleep 0.1 seconds
		isAcquiring=CameraAcquireGetStatus()
	while (isAcquiring)
	
	// "Stop" the acquisition.  You're only supposed to call this after all frames are acquired...
	CameraAcquireStop()
	
	// Transfer images from acquisition buffer to IGOR wave
	Wave imageWave=CameraAcquireRead(nFrames)
	
	// Restore the original DF
	SetDataFolder savedDF
	
	// return
	return imageWave
End











Function FancyCameraDisarm()
	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FancyCamera

	// instance vars

	// Do it
	CameraAcquireDisarm()
	
	// Restore the original DF
	SetDataFolder savedDF
End








Function /WAVE FancyCameraArmAcquireDisarm(nFrames)
	// Acquire nFrames, and return the resulting video
	// If isTriggered is true, each-frame must be TTL triggered.  If false, the 
	// acquisition is free-running.  This also handles the allocation and de-allocation
	// of the on-camera framebuffer.

	Variable nFrames

	FancyCameraArm(nFrames)
	Wave imageWave=FancyCameraAcquire(nFrames)
	FancyCameraDisarm()
	return imageWave
End








Function FancyCameraSetTemperature(targetTemperature)
	// I would have thought this was to set the setpoint of the CCD temperature controller, but it doesn't really seem like that...
	Variable targetTemperature

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FancyCamera

	// Declare instance variables

	// Set the target temperature	
	CameraCoolingSet(targetTemperature)

	// Spin until the actual temperature reaches the target, and stays there for a while
	Variable temperature
	Variable temperatureTolerance=0.1		// degC
	Variable secondsAtTargetMinimum=0.1
	Variable secondsBetweenChecks=0.1
	Variable itersAtTargetMinimum=ceil(secondsAtTargetMinimum/secondsBetweenChecks)
	Variable itersAtTarget=0
	do
		Sleep /S secondsBetweenChecks
		temperature=FancyCameraGetTemperature()
		if ( abs(temperature-targetTemperature)<temperatureTolerance ) 
			itersAtTarget+=1
		else
			itersAtTarget=0
		endif
	while (itersAtTarget<itersAtTargetMinimum)
	
	// Restore the data folder
	SetDataFolder savedDF	
	
	// Return the final temperature
	return temperature
End







Function FancyCameraGetTemperature()
	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FancyCamera

	// instance vars

	// Check the CCD temperature
	Variable temperature=CameraCoolingGetValue()
	
	// Return the temp
	return temperature
End





Function /WAVE FancyCameraROIFromROIs(roisWave)
	Wave roisWave
	
	Variable nROIs=DimSize(roisWave,1)
	Make /FREE /N=(4) cameraROI
	if (nROIs==0)
		cameraROI={0,0,CameraCCDWidthGet(),CameraCCDHeightGet()}
	else
		Make /FREE /N=(nROIs) temp
		temp=roisWave[0][p]
		Variable xLeft=WaveMin(temp)
		temp=roisWave[1][p]
		Variable yTop=WaveMin(temp)
		temp=roisWave[2][p]
		Variable xRight=WaveMax(temp)
		temp=roisWave[3][p]
		Variable yBottom=WaveMax(temp)
		// Now we have a bounding box, but need to align to the binning
		Variable nBinWidth=CameraGetBinWidth();
		Variable nBinHeight=CameraGetBinHeight();		
		Variable iLeft=floor(xLeft/nBinWidth)*nBinWidth
		Variable iTop=floor(yTop/nBinHeight)*nBinHeight
		Variable iRight=ceil(xRight/nBinWidth)*nBinWidth
		Variable iBottom=ceil(yBottom/nBinHeight)*nBinHeight		
		cameraROI={iLeft,iTop,iRight,iBottom}		
	endif
	return cameraROI	
End





Function /WAVE FancyCameraAlignROIToBins(roiWave)
	Wave roiWave
	
	Make /FREE /N=(4) alignedROI
	Variable nBinWidth=CameraGetBinWidth()
	Variable nBinHeight=CameraGetBinHeight()
	Variable iLeft=floor(roiWave[0]/nBinWidth)*nBinWidth
	Variable iTop=floor(roiWave[1]/nBinHeight)*nBinHeight
	Variable iRight=ceil(roiWave[2]/nBinWidth)*nBinWidth
	Variable iBottom=ceil(roiWave[3]/nBinHeight)*nBinHeight		
	alignedROI={iLeft,iTop,iRight,iBottom}		
	return alignedROI	
End
