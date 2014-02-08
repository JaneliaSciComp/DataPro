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

	// Igor has a thing like Matlab where most images you need to reverse the y axis in the plot in order for it
	// to be right-side up.  It seems that SIDX returns it's images in such a way that it assumes you are _not_ going to do this.
	// Since we _do_ reverse the y axis to maintain easy compatibility with Igor's imagesave operation (and also
	// to generally fit in with how most people do images), we need to do a single y reflection just to make sure 
	// both cameraspace and userspace are using the same (image-style) coordinate system.  This does _not_ count as one of the 
	// transformations specified by userFromCameraSwapXYNew, userFromCameraReflectXNew, and userFromCameraReflectYNew.
	// And I think you have to do x instead of y because of the funny way Igor deals with image data: If you want something
	// in row i, col j of the image, it's at image[j][i].
		
	// For Yitzhak's rig, we need to mirror in Y (this seems to be because of the SIDX weirdness above), then rotate CW 90 deg.
	// Those two combined work out to a transpose.
	
	// Tell the camera the userFromCameraMatrix, so it can properly transform the images
	// when we read them
	Variable userFromCameraReflectX=0	// boolean
	Variable userFromCameraReflectY=0	// boolean
	Variable userFromCameraSwapXY=1	// boolean
//	userFromCameraReflectX=0	// boolean
//	userFromCameraReflectY=0	// boolean
//	userFromCameraSwapXY=0	// boolean
	CameraSetTransform(userFromCameraReflectX,userFromCameraReflectY,userFromCameraSwapXY)
	//Variable defaultSetpointTemp=-40		// degC
	//FancyCameraSetTargetTemp(defaultSetpointTemp)
	
	// Restore the data folder
	SetDataFolder savedDF	
End




Function FancyCameraSetupSnapshotAcq(exposure)
	// This sets up the camera for a single snapshot acquisition.
	// This is typically called once per acquisition, just before the acquisition.
	Variable exposure	// frame exposure duration, in ms
	
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
	//FancyCameraSetTargetTempAndWait(targetTemperature)
End




Function FancyCameraSetupVideoAcq(nBinSize,roisWave,isTriggered,exposure)
	// This sets up the camera for a single video acquisition.
	Variable nBinSize
	Wave roisWave
	Variable isTriggered
	Variable exposure	// frame exposure duration, in ms
	
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





Function /WAVE FancyCameraGetVideoParams(nBinSize,roisWave,exposureWanted)
	Variable nBinSize
	Wave roisWave
	Variable exposureWanted	// frame exposure duration, in ms
	// First, configure the camera for video acq
	Variable isTriggered=0
	FancyCameraSetupVideoAcq(nBinSize,roisWave,isTriggered,exposureWanted)
	// Get the frame interval, in ms
	Variable frameIntervalInSeconds=CameraGetImageInterval()
	if (isnan(frameIntervalInSeconds))
		// This signals an error, propagate the error message
		FancyCameraSetErrorMessage(CameraGetErrorMessage())
	endif
	Variable frameInterval=1000*frameIntervalInSeconds	// in ms
	// Get the actual exposure, in ms
	Variable exposureInSeconds=CameraExposeGetValue()
	Variable exposure=1000*exposureInSeconds
	if (isnan(exposure))
		// This signals an error, propagate the error message
		FancyCameraSetErrorMessage(CameraGetErrorMessage())
	endif
	Make /FREE /N=2 result={frameInterval,exposure}
	return result
End





Function FancyCameraGetSnapshotExposure(exposureWanted)
	Variable exposureWanted	// frame exposure duration, in ms
	// First, configure the camera for video acq
	FancyCameraSetupSnapshotAcq(exposureWanted)
//	// Get the frame interval, in ms
//	Variable frameIntervalInSeconds=CameraGetImageInterval()
//	if (isnan(frameIntervalInSeconds))
//		// This signals an error, propagate the error message
//		FancyCameraSetErrorMessage(CameraGetErrorMessage())
//	endif
//	Variable frameInterval=1000*frameIntervalInSeconds	// in ms
	// Get the actual exposure, in ms
	Variable exposureInSeconds=CameraExposeGetValue()
	Variable exposure=1000*exposureInSeconds
	if (isnan(exposure))
		// This signals an error, propagate the error message
		FancyCameraSetErrorMessage(CameraGetErrorMessage())
	endif
	return exposure
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



Function FancyCameraWaitForFramesBang(framesCaged,nFrames)
	// Block until the camera is done acquiring, then write the acquired frames to framesCaged.
	// Note that the returned wave will not have an accurate time offset, the offset will just be zero.
	// And the frame interval scaling for the time dimension will be whatever the camera tells us it was.
	// Returns 1 is successful, 0 otherwise.
	Wave framesCaged	// a ref to a caged (non-free) wave, where the result is stored
	Variable nFrames
	
	// Spin until the acquisition is done
	Variable isAcquiring
	do
		Sleep /S 0.1		// Sleep 0.1 seconds
		isAcquiring=CameraAcquireGetStatus()
		if (isAcquiring<0)
			// This signals an error in getting the camera status
			break
		endif
	while (isAcquiring)
	
	// "Stop" the acquisition.  You're only supposed to call this after all frames are acquired...
	CameraAcquireStop()
	
	// Read frames if no problems so far
	Variable sucess
	if (isAcquiring<0)
		// If there was an error, note this for return and don't read frames
		sucess=0
	else	
		// Transfer images from acquisition buffer to IGOR wave
		CameraAcquireReadBang(framesCaged,nFrames)
		sucess=1
	endif
	
	return sucess
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







Function FancyCameraSetTargetTemp(targetTemperature)
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



Function FancyCameraGetTargetTemp()
	// Check the CCD temperature
	Variable targetTemp=CameraCoolingGet()
	
	// Return the temp
	return targetTemp
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




Function FancyCameraGetIsForReal()
	return CameraGetIsForReal()
End





Function FancyCameraReset()
	// Get the properties of the camera we want to preserve
	Variable userFromCameraReflectX=CameraGetUserFromCameraReflectX()
	Variable userFromCameraReflectY=CameraGetUserFromCameraReflectY()
	Variable userFromCameraSwapXY=CameraGetUserFromCameraSwapXY()
	Variable targetTemp=CameraCoolingGet()

	// Destruct the underlying camera
	CameraDestructor()

	// Initialize the camera
	CameraConstructor()

	// Re-set the transform, temp
	CameraSetTransform(userFromCameraReflectX,userFromCameraReflectY,userFromCameraSwapXY)
	CameraCoolingSet(targetTemp)
End


