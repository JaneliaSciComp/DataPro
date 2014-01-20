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
		
		// Instance variables
		String /G mostRecentErrorMessage=""		// When errors occur, they get stored here.		
	else
		// If it exists, switch to it
		SetDataFolder root:DP_FancyCamera
	endif

	// instance vars
	
	// Initialize the camera
	CameraConstructor()
	
	// Tell the camera the userFromCameraMatrix, so it can properly transform the images
	// when we read them
	Variable userFromCameraReflectX=1	// boolean
	Variable userFromCameraReflectY=0	// boolean
	Variable userFromCameraSwapXandY=1	// boolean
	userFromCameraReflectX=0	// boolean
	userFromCameraReflectY=0	// boolean
	userFromCameraSwapXandY=0	// boolean
	CameraSetTransform(userFromCameraReflectX,userFromCameraReflectY,userFromCameraSwapXandY)
	
	// Restore the data folder
	SetDataFolder savedDF	
End




Function FancyCameraSetupSnapshotAcq(exposure,targetTemperature)
	// This sets up the camera for a single snapshot acquisition.
	// This is typically called once per acquisition, just before the acquisition.
	Variable exposure	// frame exposure duration, in ms
	Variable targetTemperature
	
	// Set the binning and ROI
	Variable nBinSize=1
	Variable isTriggered=0
	//FancyCameraBinningSet(nBinSize)
	FancyCameraROIClear(nBinSize)	// we don't use the rois for snapshots

	// Set the trigger mode
	Variable ALWAYS=0	// start immediately
	CameraTriggerModeSet(ALWAYS)
	
	// Set the exposure
	Variable exposureInSeconds=exposure/1000		// ms->s
	CameraExposeSet(exposureInSeconds)
	
	// Set the CCD temp, wait for it to stabilize
	//FancyCameraSetTempAndWait(targetTemperature)
End




Function FancyCameraSetupVideoAcq(nBinSize,roisWave,isTriggered,exposure,targetTemperature)
	// This sets up the camera for a single video acquisition.
	Variable nBinSize
	Wave roisWave
	Variable isTriggered
	Variable exposure	// frame exposure duration, in ms
	Variable targetTemperature
	
	// Set the binning and ROI
	//FancyCameraBinningSet(nBinSize)
	//Variable nROIs=DimSize(roisWave,1)
	//Variable isAtLeastOneROI=(nROIs>0)
	//if (isAtLeastOneROI)
	//	Wave cameraROI=FancyCameraROIFromROIs(roisWave,nBinSize,nBinHeight)
	//else
	//	Make /FREE cameraROI={nan,nan,nan,nan}
	//endif
	FancyCameraROISet(roisWave,nBinSize)
	//isAtLeastOneROI, cameraROI[0], cameraROI[1], cameraROI[2], cameraROI[3])

	// Set the trigger mode
	Variable ALWAYS=0	// start immediately
	Variable EXPOSURE_START=1	// start of each frame is TTL-triggered
	Variable SEQUENCE_START=3	// start of sequence is TTL-triggered
	Variable triggerMode=(isTriggered ? SEQUENCE_START : ALWAYS)
	CameraTriggerModeSet(triggerMode)
	
	// Set the exposure
	Variable exposureInSeconds=exposure/1000		// ms->s
	CameraExposeSet(exposureInSeconds)
	
	// Set the CCD temp, wait for it to stabilize
	//FancyCameraSetTempAndWait(targetTemperature)
End






Function FancyCameraROISet(roisWave,nBinSize)
	// Set the ROI for the camera, given the user ROIs.  Note that the input coords are in user coordinate space, so
	// we have to translate them to CCD coordinate space.
	Wave roisWave
	Variable nBinSize

	CameraROISetToROIsInUserSpace(roisWave,nBinSize)
End








Function FancyCameraROIClear(nBinSize)
	// Clear the ROI, i.e. set the camera to use the full CCD
	Variable nBinSize
	
	CameraROIClear(nBinSize)
End








Function FancyCameraArm(nFrames)
	// Arm the camera for acquiring n frames.
	// If isTriggered is true, each frame must be TTL triggered.  If false, the 
	// acquisition is free-running.
	// This returns 1 is the camera was successfully armed, 0 otherwise.
	Variable nFrames

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FancyCamera

	// instance vars

	// Allocate space in the frame buffer
	CameraAcquireImageSetLimit(nFrames)
	CameraBufferCountSet(nFrames)

	// Arm the acquisition
	Variable success=CameraAcquireArm()
	if (!success)
		// If a problem, propagate the error message
		FancyCameraSetErrorMessage(CameraGetErrorMessage())
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
	
	return success
End







Function FancyCameraStartAcquire()
	// Prep for the acquisition (this will also start the acquisition unless it's a triggered acquire).
	// Returns 1 on success, 0 on failure.
	Variable success=CameraAcquireStart()
	if (!success)
		// If a problem, propagate the error message
		FancyCameraSetErrorMessage(CameraGetErrorMessage())
	endif
	
	return success
End



Function /WAVE FancyCameraWaitForFramesBang(framesCaged,nFrames)
	// Block until the camera is done acquiring, then return the acquired frames.
	// Note that the returned wave will not have an accurate time offset, the offset will just be zero.
	// And the frame interval scaling for the time dimension will be whatever the camera tells us it was.
	Wave framesCaged	// a ref to a caged (non-free) wave, where the result is stored
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
	CameraAcquireReadBang(framesCaged,nFrames)
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








//Function FancyCameraSetTempAndWait(targetTemperature)
//	Variable targetTemperature
//
//	// Switch to the imaging data folder
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:DP_FancyCamera
//
//	// Declare instance variables
//
//	// Set the target temperature	
//	CameraCoolingSet(targetTemperature)
//
//	// Spin until the actual temperature reaches the target, and stays there for a while
//	Variable temperature
//	Variable temperatureTolerance=0.1		// degC
//	Variable secondsAtTargetMinimum=0.1
//	Variable secondsBetweenChecks=0.1
//	Variable itersAtTargetMinimum=ceil(secondsAtTargetMinimum/secondsBetweenChecks)
//	Variable itersAtTarget=0
//	do
//		Sleep /S secondsBetweenChecks
//		temperature=FancyCameraGetTemperature()
//		if ( abs(temperature-targetTemperature)<temperatureTolerance ) 
//			itersAtTarget+=1
//		else
//			itersAtTarget=0
//		endif
//	while (itersAtTarget<itersAtTargetMinimum)
//	
//	// Restore the data folder
//	SetDataFolder savedDF	
//	
//	// Return the final temperature
//	return temperature
//End







Function FancyCameraSetTemp(targetTemperature)
	Variable targetTemperature

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FancyCamera

	// Declare instance variables

	// Set the target temperature	
	CameraCoolingSet(targetTemperature)

	// Restore the data folder
	SetDataFolder savedDF		
End







Function FancyCameraGetTemperature()
	// Check the CCD temperature
	Variable temperature=CameraCoolingGetValue()
	
	// Return the temp
	return temperature
End





//Function /WAVE FancyCameraAlignROIToBins(roiWave)
//	Wave roiWave
//	
//	Variable nBinSize=CameraGetBinSize()
//	Variable iLeft=floor(roiWave[0]/nBinSize)*nBinSize
//	Variable iTop=floor(roiWave[1]/nBinSize)*nBinSize
//	Variable iRight=ceil(roiWave[2]/nBinSize)*nBinSize
//	Variable iBottom=ceil(roiWave[3]/nBinSize)*nBinHeight		
//	Make /FREE /N=(4) alignedROI
//	alignedROI={iLeft,iTop,iRight,iBottom}		
//	return alignedROI	
//End





Function /S FancyCameraGetErrorMessage()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FancyCamera

	// Declare instance variables
	SVAR mostRecentErrorMessage

	String result=mostRecentErrorMessage

	// Restore the data folder
	SetDataFolder savedDF	
	
	return result
End




Function FancyCameraSetErrorMessage(newValue)
	String newValue

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FancyCamera

	// Declare instance variables
	SVAR mostRecentErrorMessage

	mostRecentErrorMessage=newValue

	// Restore the data folder
	SetDataFolder savedDF	
End




Function FancyCameraDestructor()
	// Destruct the underlying camera
	CameraDestructor()
	
	// Switch to the root data folder
	SetDataFolder root:
	
	// Delete the FancyCamera DF
	KillDataFolder /Z root:DP_FancyCamera
End
