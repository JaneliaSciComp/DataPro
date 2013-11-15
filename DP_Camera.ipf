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
				String errorMessage
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
				String errorMessage
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
				String errorMessage
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
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
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
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
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







