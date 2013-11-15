//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

// The Camera "object" wraps all the SIDX functions, so the "FancyCamera" object doesn't have to deal 
// with them directly.  It also deals with errors internally, so you don't have to worry about them 
// at the next level up.  And it adds the ability to fake a camera, for when there is no camera attached.

// Construct the object
Function CameraConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)

	// If the data folder doesn't exist, create it (and switch to it)
	if (!DataFolderExists("root:DP_Camera"))
		// IMAGING GLOBALS
		NewDataFolder /O /S root:DP_Camera
				
		// SIDX stuff
		Variable /G areWeForReal=1	// boolean; if false, we have decided to fake the camera
		Variable /G isSidxRootValid=0	// boolean
		Variable /G sidxRoot
		Variable /G isSidxCameraValid=0	// boolean
		Variable /G sidxCamera	
		Variable /G isSidxAcquirerValid=0	// boolean
		Variable /G sidxAcquirer		
						
		// This stuff is only needed/used if there's no camera and we're faking
		Variable /G fakeNWidthCCD=512	// width of the fake CCD
		Variable /G fakeNHeightCCD=512	// height of the fake CCD
		Variable /G fakeTriggerMode=0		// the trigger mode of the fake camera. 0=>free-running, 1=> each frame is triggered, and there are other settings
		Variable /G fakeIsFullFrame=1		// are we doing full-frame for the fake camera?  (false=>ROI)
		Variable /G fakeNBinWidth=1
		Variable /G fakeNBinHeight=1
		Variable /G fakeJLeft, fakeITop, fakeJRight, fakeIBottom	// the ROI boundaries
		Variable /G fakeExposureInSeconds=0.1	// exposure for the fake camera, in sec
		Variable /G fakeTargetTemperature=-20		// degC
		Variable /G fakeNFrames=1		// How many frames to acquire for the fake camera
	endif

	// Create the SIDX root object, referenced by sidxRoot
	String license=""	// License file is stored in C:/Program Files/Bruxton/SIDX
	Variable sidxStatus
	SIDXRootOpen sidxRoot, license, sidxStatus
	isSidxRootValid=(sidxStatus==0)
	areWeForReal= isSidxRootValid	// if we can't get a valid sidx root, then fake

	Variable nCameras
	if (areWeForReal)
		if (isSidxRootValid)
			SIDXRootCameraScanGetCount sidxRoot, nCameras,sidxStatus
			if (sidxStatus != 0)
				nCameras=0
			endif
			//Printf "# of cameras: %d\r", nCameras
			if (nCameras>0)
				// Create the SIDX camera object, referenced by sidxCamera
				SIDXRootCameraOpenName sidxRoot, "", sidxCamera, sidxStatus
				isSidxCameraValid= (sidxStatus==0)
				areWeForReal=isSidxCameraValid		// if no valid camera, then we fake
			else
				// if zero cameras, then we fake
				areWeForReal=0;
			endif
		endif
	endif	
	
	// Restore the data folder
	SetDataFolder savedDF	
End





Function CameraROIClear()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR fakeIsFullFrame

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraROIClear sidxCamera, sidxStatus
			if (sidxStatus!=0)
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraROIClear: %s",errorMessage)
			endif	
		else
			Abort "Called CameraROIClear() before camera was created."
		endif
	else
		fakeIsFullFrame=1
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End




Function CameraROISet(jLeft, iTop, jRight, iBottom)
	Variable jLeft,iTop,jRight,iBottom
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR fakeJLeft, fakeITop, fakeJRight, fakeIBottom

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraROISet sidxCamera, jLeft, iTop, jRight, iBottom, sidxStatus
			if (sidxStatus!=0)
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraROISet: %s",errorMessage)
			endif
		else
			Abort "Called CameraROISet() before camera was created."
		endif
	else
		fakeJLeft=jLeft
		fakeITop=iTop
		fakeJRight=jRight
		fakeIBottom=iBottom
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End





Function CameraBinningSet(nBinWidth,nBinHeight)
	Variable nBinWidth, nBinHeight
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR fakeNBinWidth, fakeNBinHeight

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraBinningSet sidxCamera, nBinWidth, nBinHeight, sidxStatus
			if (sidxStatus!=0)
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraBinningSet: %s",errorMessage)
			endif
		else
			Abort "Called CameraBinningSet() before camera was created."
		endif
	else
		fakeNBinWidth=nBinWidth
		fakeNBinHeight=nBinHeight
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraTriggerModeSet(triggerMode)
	Variable triggerMode
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR fakeTriggerMode

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraTriggerModeSet sidxCamera, triggerMode, sidxStatus
			if (sidxStatus!=0)
				SIDXRootGetLastError sidxRoot, errorMessage
				Abort sprintf1s("Error in SIDXCameraTriggerModeSet: %s",errorMessage)
			endif
		else
			Abort "Called CameraTriggerModeSet() before camera was created."
		endif
	else
		fakeTriggerMode=triggerMode
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End







Function CameraExposeSet(exposureInSeconds)
	Variable exposureInSeconds
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR fakeExposureInSeconds

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraExposeSet sidxCamera, exposureInSeconds, sidxStatus
			if (sidxStatus!=0)
				SIDXRootGetLastError sidxRoot, errorMessage
				Abort sprintf1s("Error in SIDXCameraExposeSet: %s",errorMessage)
			endif
		else
			Abort "Called CameraExposeSet() before camera was created."
		endif
	else
		fakeExposureInSeconds=exposureInSeconds
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End














Function CameraSetupAcquisition(isROI,isBackgroundROIToo,roisWave,isTriggered,exposure,targetTemperature,nBinWidth,nBinHeight)
	// This sets up the camera for a single acquisition.  (A single aquisition could be a single frame, or it could be a video.)  
	// This is typically called once per acquisition, just before the acquisition.
	//Variable image_roi
	Variable isROI
	Variable isBackgroundROIToo
	Wave roisWave
	Variable isTriggered
	Variable exposure	// frame exposure duration, in ms
	Variable targetTemperature
	Variable nBinWidth
	Variable nBinHeight
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR isSidxRootValid
	NVAR sidxRoot
	NVAR isSidxCameraValid
	NVAR sidxCamera
	
	// Make sure there's a valid camera
	if (!isSidxCameraValid)
		Abort "Error in CameraSetupAcquisition(): No valid camera."
	endif
	
	// This is used in lots of places
	Variable sidxStatus
	String errorMessage

	// Set up stuff
	SIDXCameraROIClear sidxCamera, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort sprintf1s("Error in SIDXCameraROIClear: %s",errorMessage)
	endif
	Variable jLeft, iTop, jRight, iBottom	
	if (isROI)
		Variable iROI=0  // the foreground ROI
		jLeft=roisWave[0][iROI]; iTop=roisWave[3][iROI]; jRight=roisWave[1][iROI]; iBottom=roisWave[2][iROI]
		SIDXCameraROISet sidxCamera, jLeft, iTop, jRight, iBottom, sidxStatus
		if (sidxStatus!=0)
			SIDXRootGetLastError sidxRoot, errorMessage
			Abort sprintf1s("Error in SIDXCameraROISet: %s",errorMessage)
		endif
		//print jLeft, iTop, jRight, iBottom
		if (isBackgroundROIToo)	// add bkgnd ROI
			iROI=1  // the background ROI
			jLeft=roisWave[0][iROI]; iTop=roisWave[3][iROI]; jRight=roisWave[1][iROI]; iBottom=roisWave[2][iROI]
			SIDXCameraROISet sidxCamera, jLeft, iTop, jRight, iBottom, sidxStatus
			if (sidxStatus!=0)
				SIDXRootGetLastError sidxRoot, errorMessage
				Abort sprintf1s("Error in SIDXCameraROISet: %s",errorMessage)
			endif
			//printf "ROI sidxStatus=%d\r", sidxStatus
			//print jLeft, iTop, jRight, iBottom
		endif
		//Variable roi_count
		//SIDXImageGetROICount sidxRoot, roi_count, sidxStatus
		//printf "%d ROIs set\r", roi_count
	endif
	SIDXCameraBinningSet sidxCamera, nBinWidth, nBinHeight, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort sprintf1s("Error in SIDXCameraBinningSet: %s",errorMessage)
	endif

	// Set the amplifier gain 
	//SIDXImageSetGain sidxRoot, 0, sidxStatus
	// Maybe the default is OK?  Let's try that...
	
	// Set the trigger mode
	Variable NO_TRIGGER=0	// start immediately
	Variable TRIGGER_EXPOSURE_START=1	// start of each frame is TTL-triggered
	Variable triggerMode=(isTriggered ? TRIGGER_EXPOSURE_START : NO_TRIGGER)
	SIDXCameraTriggerModeSet sidxCamera, triggerMode, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort sprintf1s("Error in SIDXCameraTriggerModeSet: %s",errorMessage)
	endif
	
	// Set the exposure
	Variable exposureInSeconds=exposure/1000	// ms->s
	SIDXCameraExposeSet sidxCamera, exposureInSeconds, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort sprintf1s("Error in SIDXCameraExposeSet: %s",errorMessage)
	endif
	
	// Set the CCD temp, wait for it to stabilize
	CameraSetTemperature(targetTemperature)
	
	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraArm(imageWaveName, nFrames)
	// Acquire nFrames, and store the resulting video in imageWaveName.
	// If isTriggered is true, each-frame must be TTL triggered.  If false, the 
	// acquisition is free-running.

	String imageWaveName
	Variable nFrames

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// instance vars
	NVAR sidxRoot
	NVAR sidxCamera
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer

	// This is used in lots of places
	Variable sidxStatus
	String errorMessage

	// The old code called SIDXAcquisitonBegin, then SIDXAcquisitionAllocate
	//  The SIDX 7 library seems to require that these be switched
	
	// Allocate space in the frame buffer
	//SIDXAcquisitionAllocate sidxRoot, nFrames, iBuffer, sidxStatus
	SIDXCameraBufferCountSet sidxCamera, nFrames, sidxStatus
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort errorMessage
	endif

	//  "Arm" the camera to start an acquisition, which 
	// returns a SIDX "Acquire" object, which should maybe be called an
	// "Acquirer"	
	//SIDXAcquisitionBegin sidxRoot, nFrames, sidxStatus
	SIDXCameraAcquireOpen sidxCamera, sidxAcquirer, sidxStatus
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort errorMessage
	endif
	isSidxAcquirerValid=1
	
	// Restore the original DF
	SetDataFolder savedDF
End







Function CameraAcquire(imageWaveName, nFrames, isTriggered)
	// Acquire nFrames, and store the resulting video in imageWaveName.
	// If isTriggered is true, each-frame must be TTL triggered.  If false, the 
	// acquisition is free-running.

	String imageWaveName
	Variable nFrames
	Variable isTriggered

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// instance vars
	NVAR sidxRoot
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer

	// This is used in lots of places
	Variable sidxStatus
	String errorMessage
	
	// Check that the framebuffer is allocated
	if (!isSidxAcquirerValid)
		return 0		// Have to return something
	endif

	// Prep for the acquisition (this will also start the acquisition unless it's a triggered acquire)
	SIDXAcquireStart sidxAcquirer, sidxStatus
	if (sidxStatus != 0)		
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort errorMessage
	endif

	// If the acquisition is external trigger mode, start the data acq, which will provide the per-frame triggers
	if (isTriggered)
		//DoDataAcq()	// will have to sub in new method call
	endif

	// Spin until the acquisition is done
	Variable isAcquiring
	do
		SIDXAcquireGetStatus sidxAcquirer, isAcquiring, sidxStatus
		if (sidxStatus != 0)
			SIDXRootGetLastError sidxRoot, errorMessage
			SIDXAcquireAbort sidxAcquirer, sidxStatus
			Abort errorMessage
		endif
	while (isAcquiring)
	
	// "Stop" the acquisition.  You're only supposed to call this after all frames are acquired...
	SIDXAcquireStop sidxAcquirer, sidxStatus
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort errorMessage
	endif
	
	// Transfer images from acquisition buffer to IGOR wave
	SIDXAcquireRead sidxAcquirer, nFrames, imageWaveName, sidxStatus
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort errorMessage
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End











Function CameraDisarm()
	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// instance vars
	NVAR sidxRoot
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer

	// This is used in lots of places
	Variable sidxStatus
	String errorMessage
	
	if (isSidxAcquirerValid)
		SIDXAcquireClose sidxAcquirer, sidxStatus
		isSidxAcquirerValid=0
		// Seems like we don't need to deallocate the framebuffer when using SIDX 7
 		//SIDXAcquisitionDeallocate sidxRoot, iBuffer, sidxStatus
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End








Function CameraArmAcquireDisarm(imageWaveName, nFrames, isTriggered)
	// Acquire nFrames, and store the resulting video in imageWaveName.
	// If isTriggered is true, each-frame must be TTL triggered.  If false, the 
	// acquisition is free-running.  This also handles the allocation and de-allocation
	// of the on-camera framebuffer.

	String imageWaveName
	Variable nFrames
	Variable isTriggered

	CameraArm(imageWaveName, nFrames)
	CameraAcquire(imageWaveName, nFrames, isTriggered)
	CameraDisarm()
End








Function CameraFinalize()
	// Called to allow the SIDX library to do any required cleanup operations.
	// Generally called at the end of an imaging session.  This is the "partner" of 
	// CameraInitialize().

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// instance vars
	NVAR isSidxRootValid
	NVAR sidxRoot
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer
	
	// This is used in lots of places
	Variable sidxStatus
	String errorMessage

	// Close the SIDX Acquire object
	if (isSidxAcquirerValid)
		SIDXAcquireClose sidxAcquirer, sidxStatus
		isSidxAcquirerValid=0	
	endif
	
	// Close the SIDX Camera object
	if (isSidxCameraValid)
		SIDXCameraClose sidxCamera, sidxStatus
		isSidxCameraValid=0	
	endif
	
	// Close the SIDX root object
	if (isSidxRootValid)
		SIDXRootClose sidxRoot, errorMessage
		isSidxRootValid=0
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End









Function CameraSetTemperature(targetTemperature)
	// I would have thought this was to set the setpoint of the CCD temperature controller, but it doesn't really seem like that...
	Variable targetTemperature

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR sidxRoot
	NVAR isSidxCameraValid
	NVAR sidxCamera

	// Make sure there's a camera
	if (!isSidxCameraValid)
		Abort "There is no valid camera object."
	endif

	// This is used in lots of places
	Variable sidxStatus
	String errorMessage

	// Set the target temperature	
	SIDXCameraCoolingSet sidxCamera, targetTemperature, sidxStatus
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort errorMessage
	endif

	// Spin until the actual temperature reaches the target, and stays there for a while
	Variable temperature
	Variable temperatureTolerance=0.1		// degC
	Variable secondsAtTargetMinimum=5
	Variable secondsBetweenChecks=0.1
	Variable itersAtTargetMinimum=ceil(secondsAtTargetMinimum/secondsBetweenChecks)
	Variable itersAtTarget=0
	do
		temperature=CameraGetTemperature()
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







Function CameraGetTemperature()
	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// instance vars
	NVAR sidxRoot
	NVAR isSidxCameraValid
	NVAR sidxCamera

	// This is used in lots of places
	Variable sidxStatus
	String errorMessage
	
	// Check that the framebuffer is allocated
	if (!isSidxCameraValid)
		return nan		// Have to return something
	endif

	// Check the CCD temperature
	Variable temperature
	SIDXCameraCoolingGetValue sidxCamera, temperature, sidxStatus
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort errorMessage
	endif
	
	// Return the temp
	return temperature
End



