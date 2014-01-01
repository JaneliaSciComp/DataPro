//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

// This "object" is, at least in spirit, a subclass of Camera that adds additional, generally higher-level methods for taking images and video.
// Even though it creates its own data folder, at present it has no instance variables, so it really is just a collection of additional methods 
// for the Camera object.




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




Function FancyCameraSetupSnapshotAcq(exposure,targetTemperature)
	// This sets up the camera for a single snapshot acquisition.
	// This is typically called once per acquisition, just before the acquisition.
	Variable exposure	// frame exposure duration, in ms
	Variable targetTemperature
	
	// Set the binning and ROI
	Variable nBinWidth=1
	Variable nBinHeight=1
	Variable isTriggered=0
	Variable isAtLeastOneROI=0
	FancyCameraBinningAndROISet(nBinWidth, nBinHeight, isAtLeastOneROI, nan, nan, nan, nan)

	// Set the trigger mode
	Variable NO_TRIGGER=0	// start immediately
	CameraTriggerModeSet(NO_TRIGGER)
	
	// Set the exposure
	Variable exposureInSeconds=exposure/1000		// ms->s
	CameraExposeSet(exposureInSeconds)
	
	// Set the CCD temp, wait for it to stabilize
	FancyCameraSetTempAndWait(targetTemperature)
End




Function FancyCameraSetupVideoAcq(nBinWidth,nBinHeight,roisWave,isTriggered,exposure,targetTemperature)
	// This sets up the camera for a single video acquisition.
	Variable nBinWidth
	Variable nBinHeight
	Wave roisWave
	Variable isTriggered
	Variable exposure	// frame exposure duration, in ms
	Variable targetTemperature
	
	// Set the binning and ROI
	Variable nROIs=DimSize(roisWave,1)
	Variable isAtLeastOneROI=(nROIs>0)
	if (isAtLeastOneROI)
		Wave cameraROI=FancyCameraROIFromROIs(roisWave,nBinWidth,nBinHeight)
	else
		Make /FREE cameraROI={nan,nan,nan,nan}
	endif
	FancyCameraBinningAndROISet(nBinWidth, nBinHeight, isAtLeastOneROI, cameraROI[0], cameraROI[1], cameraROI[2], cameraROI[3])

	// Set the trigger mode
	Variable NO_TRIGGER=0	// start immediately
	Variable TRIGGER_EXPOSURE_START=1	// start of each frame is TTL-triggered
	Variable triggerMode=(isTriggered ? TRIGGER_EXPOSURE_START : NO_TRIGGER)
	CameraTriggerModeSet(triggerMode)
	
	// Set the exposure
	Variable exposureInSeconds=exposure/1000		// ms->s
	CameraExposeSet(exposureInSeconds)
	
	// Set the CCD temp, wait for it to stabilize
	FancyCameraSetTempAndWait(targetTemperature)
End






Function FancyCameraBinningAndROISet(nBinWidth, nBinHeight, isROI, iLeft, iTop, iRight, iBottom)
	Variable nBinWidth, nBinHeight
	Variable isROI
	Variable iLeft,iTop,iRight,iBottom
	
	// Check that the bin size is an integer fraction of the CCD size
	// If not, return
	Variable nBinsWide=CameraCCDWidthGet()/nBinWidth
	if ( !IsInteger(nBinsWide) )
		//SetDataFolder savedDF	
		return 0
	endif
	Variable nBinsHigh=CameraCCDHeightGet()/nBinHeight
	if ( !IsInteger(nBinsHigh) )
		//SetDataFolder savedDF	
		return 0
	endif

	// Check that the ROI dimensions are legal
	if (isROI)
		if ( !IsInteger(iLeft/nBinWidth) )
			return 0
		endif
		if ( !IsInteger(iRight/nBinWidth) )
			return 0
		endif
		if ( !IsInteger(iTop/nBinHeight) )
			return 0
		endif
		if ( !IsInteger(iBottom/nBinHeight) )
			return 0
		endif
	endif
	
	// Clear the ROI	
	CameraROIClear()
	
	// Set the binning
	CameraBinningSet(nBinWidth, nBinHeight)
	// Set the camera ROI
	if (isROI)
		CameraROISet(iLeft, iTop, iRight, iBottom)
	endif

End








Function FancyCameraArm(nFrames)
	// Arm the camera for acquiring n frames.
	// If isTriggered is true, each frame must be TTL triggered.  If false, the 
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







//Function /WAVE FancyCameraAcquire(nFrames)
//	// Acquire nFrames, and store the resulting video in imageWaveName.
//	// If isTriggered is true, each-frame must be TTL triggered.  If false, the 
//	// acquisition is free-running.
//
//	Variable nFrames
//	//Variable isTriggered
//
//	// Change to the imaging data folder
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:DP_FancyCamera
//
//	// instance vars
//	
//	// Prep for the acquisition (this will also start the acquisition unless it's a triggered acquire)
//	CameraAcquireStart()
//
//	// If the acquisition is external trigger mode, start the data acq
//	Variable NO_TRIGGER=0		// start immediately
//	if (CameraTriggerModeGet()!=NO_TRIGGER)
//		SweeperControllerAcquireTrial()	
//	endif
//
//	// Spin until the acquisition is done
//	Variable isAcquiring
//	do
//		Sleep /S 0.1		// Sleep 0.1 seconds
//		isAcquiring=CameraAcquireGetStatus()
//	while (isAcquiring)
//	
//	// "Stop" the acquisition.  You're only supposed to call this after all frames are acquired...
//	CameraAcquireStop()
//	
//	// Transfer images from acquisition buffer to IGOR wave
//	Wave imageWave=CameraAcquireRead(nFrames)
//	
//	// Restore the original DF
//	SetDataFolder savedDF
//	
//	// return
//	return imageWave
//End



Function FancyCameraStartAcquire()
	// Prep for the acquisition (this will also start the acquisition unless it's a triggered acquire)
	CameraAcquireStart()
End



Function /WAVE FancyCameraWaitForFrames(nFrames)
	Variable nFrames
	
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








//Function /WAVE FancyCameraArmAcquireDisarm(nFrames)
//	// Acquire nFrames, and return the resulting video
//	// If isTriggered is true, each-frame must be TTL triggered.  If false, the 
//	// acquisition is free-running.  This also handles the allocation and de-allocation
//	// of the on-camera framebuffer.
//
//	Variable nFrames
//
//	FancyCameraArm(nFrames)
//	Wave imageWave=FancyCameraAcquire(nFrames)		// This will call SweeperControllerAcquireTrial() if in triggered mode
//	FancyCameraDisarm()
//	return imageWave
//End








Function FancyCameraSetTempAndWait(targetTemperature)
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





Function /WAVE FancyCameraROIFromROIs(roisWave,nBinWidth,nBinHeight)
	Wave roisWave
	Variable nBinWidth, nBinHeight
	
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
