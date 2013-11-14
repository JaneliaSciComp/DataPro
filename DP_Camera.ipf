//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

// The Camera "object" wraps all the SIDX functions, so the Imager doesn't have to deal with 
// them directly.

// Note that these functions were originally based on example code provided by Lin Ci Brown 
// of the Bruxton Corporation.






// Construct the object
Function CameraConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)

	// If the data folder doesn't exist, create it (and switch to it)
	if (!DataFolderExists("root:DP_Camera"))
		// IMAGING GLOBALS
		NewDataFolder /O /S root:DP_Camera
		
		// SIDX stuff
		Variable /G isSidxRootValid=0	// boolean
		Variable /G sidxRoot
		Variable /G isSidxCameraValid=0	// boolean
		Variable /G sidxCamera	
		Variable /G isSidxAcquirerValid=0	// boolean
		Variable /G sidxAcquirer		
	endif

	// Initialize the camera
	CameraInitialize()
	
	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraInitialize()
	// Initializes the SIDX interface to the camera.  Generally this will be called once per imaging session.
	// But calling it multiple times won't hurt anything---if the camera is already initialized, it doesn't do
	// anything.

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR sidxRoot
	NVAR isSidxRootValid
	NVAR sidxCamera
	NVAR isSidxCameraValid	
	
	// If the sidxCamera object is already valid, nothing to do
	if (isSidxCameraValid)
		return 0		// have to return something
	endif
	
	// This is used in lots of places
	Variable sidxStatus
	String errorMessage
	
	// Create the SIDX root object, referenced by sidxRoot
	String license=""	// License file is stored in C:/Program Files/Bruxton/SIDX
	SIDXRootOpen sidxRoot, license, sidxStatus
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort sprintf1s("Error in SIDXRootOpen: %s", errorMessage)
	endif
	isSidxRootValid=1
	
	// Just for fun, enumerate the available cameras
	Variable nCameras
	SIDXRootCameraScanGetCount sidxRoot, nCameras,sidxStatus
	Printf "# of cameras: %d\r", nCameras
	Variable iCamera
	for (iCamera=0; iCamera<nCameras; iCamera+=1)
		String thisCameraName
		SIDXRootCameraScanGetName sidxRoot, iCamera, thisCameraName, sidxStatus
		Printf "Camera %d of %d is named %s\r", iCamera, nCameras, thisCameraName
	endfor
	
	// Create the SIDX camera object, referenced by sidxCamera
	SIDXRootCameraOpenName sidxRoot, "", sidxCamera, sidxStatus
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort sprintf1s("Error in SIDXRootCameraOpenName: %s", errorMessage)
	endif
	isSidxCameraValid=1
	
	// Restore the data folder
	SetDataFolder savedDF
End








Function CameraSetupAcquisition(image_roi,roiwave,isTriggered,ccd_fullexp,targetTemperature,nBinWidth,nBinHeight)
	// This sets up the camera for a single acquisition.  (A single aquisition could be a single frame, or it could be a video.)  
	// This is typically called once per acquisition, just before the acquisition.
	Variable image_roi
	Wave roiwave
	Variable isTriggered
	Variable ccd_fullexp
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
	
	//Variable sidxStatus, canceled
	//Variable x1, y1, x2, y2
	//String errorMessage, camera_set, image_set, driver_set, hardware_set
	//sprintf camera_set "RoperPIAD=\"1\" RoperPIGain=\"0\" RoperPITiming=\"0\" RoperPITemperature=\"-25.0\" RoperPIExposure=\"0.030000\""
	//SIDXCameraSetSettings sidxRoot, camera_set, sidxStatus
	//if (sidxStatus != 0)
	//	SIDXRootGetLastError sidxRoot, errorMessage
	//	//SIDXHardwareEnd sidxRoot, sidxStatus
	//	//SIDXDriverEnd sidxRoot, sidxStatus
	//	SIDXRootClose sidxRoot, sidxStatus
	//	printf "%s: %s", "SIDXCameraSetSettings", errorMessage
	//	return 0
	//endif
	//SIDXCameraSetSetting sidxRoot, "RoperPICleanScans", "1", sidxStatus
	//SIDXCameraSetSetting sidxRoot, "RoperPIStripsPerScan", "512", sidxStatus
	//SIDXCameraSetShutterMode sidxRoot, 4, sidxStatus
//	if (sidxStatus != 0)
//		SIDXRootGetLastError sidxRoot, errorMessage
//		SIDXRootClose sidxRoot, errorMessage
//		printf "%s: %s", "SIDXCameraSetSetting", errorMessage
//		return 0
//	endif
	//SIDXCameraGetSettings sidxRoot, errorMessage, sidxStatus
	//print errorMessage
	
	//SIDXImageROIFullFrame sidxRoot, sidxStatus
	SIDXCameraROIClear sidxCamera, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Abort sprintf1s("Error in SIDXCameraROIClear: %s",errorMessage)
	endif
	Variable jLeft, iTop, jRight, iBottom	
	if (image_roi>0)
		jLeft=roiwave[0][1]; iTop=roiwave[3][1]; jRight=roiwave[1][1]; iBottom=roiwave[2][1]
		SIDXCameraROISet sidxCamera, jLeft, iTop, jRight, iBottom, sidxStatus
		if (sidxStatus!=0)
			SIDXRootGetLastError sidxRoot, errorMessage
			Abort sprintf1s("Error in SIDXCameraROISet: %s",errorMessage)
		endif
		//print jLeft, iTop, jRight, iBottom
		if (image_roi>1)	// add bkgnd ROI
			jLeft=roiwave[0][2]; iTop=roiwave[3][2]; jRight=roiwave[1][2]; iBottom=roiwave[2][2]
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
	Variable exposure=ccd_fullexp/1000	// ms->s
	SIDXCameraExposeSet sidxCamera, exposure, sidxStatus
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
		SIDXCameraCoolingGetValue sidxCamera, temperature, sidxStatus
		if (sidxStatus != 0)
			SIDXRootGetLastError sidxRoot, errorMessage
			Abort errorMessage
		endif
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



