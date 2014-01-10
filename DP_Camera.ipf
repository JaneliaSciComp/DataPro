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

	// If the data folder does not already exist, create it and set up the camera
	if (!DataFolderExists("root:DP_Camera"))
		// If the data folder doesn't exist, create it (and switch to it)
		// IMAGING GLOBALS
		NewDataFolder /O /S root:DP_Camera
				
		// SIDX stuff
		Variable /G areWeForReal		// boolean; if false, we have decided to fake the camera
		Variable /G isSidxRootValid=0	// boolean
		Variable /G sidxRoot
		Variable /G isSidxCameraValid=0	// boolean
		Variable /G sidxCamera	
		Variable /G isSidxAcquirerValid=0	// boolean
		Variable /G sidxAcquirer
		Make /N=(0,0,0) bufferFrame	// Will hold the acquired frames
		Variable /G widthCCD=nan		// width of the CCD
		Variable /G heightCCD=nan	// height of the CCD

		// This stuff is only needed/used if there's no camera and we're faking
		Variable /G modeTriggerFake=0		// the trigger mode of the fake camera. 0=>free-running, 1=> each frame is triggered, and there are other settings
		Variable /G widthBinFake=1
		Variable /G heightBinFake=1
		Variable /G iLeftROIFake=0
		Variable /G iTopROIFake=0
		Variable /G iBottomROIFake=heightCCD
		Variable /G iRightROIFake=widthCCD
		Variable /G exposureFake=0.1		// exposure for the fake camera, in sec
		Variable /G temperatureTargetFake=-20		// degC
		Variable /G nFramesBufferFake=1		// How many frames in the fake on-camera frame buffer
		Variable /G nFramesToAcquireFake=1		
		Variable /G isAcquireOpenFake=0		// Whether acquisition is "armed"
		Variable /G isAcquisitionOngoingFake=0
		Variable /G countReadFrameFake=0		// the first frame to be read by subsequent read commands
		String /G mostRecentErrorMessage=""		// When errors occur, they get stored here.

		// Create the SIDX root object, referenced by sidxRoot
		String errorMessage
		String license=""	// License file is stored in C:/Program Files/Bruxton/SIDX
		Variable sidxStatus
		SIDXRootOpen sidxRoot, license, sidxStatus
		if (sidxStatus!=0)
			SIDXRootGetLastError sidxRoot, errorMessage
			printf "Error in SIDXRootOpen: %s\r" errorMessage
		endif
		isSidxRootValid=(sidxStatus==0)
		//printf "isSidxRootValid: %d\r" isSidxRootValid
		Variable nCameras
		if (isSidxRootValid)
			Printf "Scanning for cameras..."
			SIDXRootCameraScan sidxRoot, sidxStatus
			Printf "done.\r"
			if (sidxStatus != 0)
				// Scan didn't work
				nCameras=0
			else
				// Scan worked				
				// For debugging purposes
				String report
				SIDXRootCameraScanGetReport sidxRoot, report, sidxStatus
				Print report
				// Get the number of cameras
				SIDXRootCameraScanGetCount sidxRoot, nCameras,sidxStatus
				if (sidxStatus != 0)
					nCameras=0
				endif
			endif
			Printf "# of cameras: %d\r", nCameras
			if (nCameras>0)
				// Create the SIDX camera object, referenced by sidxCamera
				String cameraName
				SIDXRootCameraScanGetName sidxRoot, 0, cameraName, sidxStatus
				if (sidxStatus!=0)
					SIDXRootGetLastError sidxRoot, errorMessage
					printf "Error in SIDXRootCameraScanGetName: %s\r" errorMessage
				endif
				printf "cameraName: %s\r", cameraName
				SIDXRootCameraOpenName sidxRoot, cameraName, sidxCamera, sidxStatus
				if (sidxStatus!=0)
					SIDXRootGetLastError sidxRoot, errorMessage
					printf "Error in SIDXRootCameraOpenName: %s\r" errorMessage
				endif	
				isSidxCameraValid= (sidxStatus==0)
				printf "isSidxCameraValid: %d\r", isSidxCameraValid
				areWeForReal=isSidxCameraValid		// if no valid camera, then we fake
				if (isSidxCameraValid)
					Variable x0, y0, xf, yf
					SIDXCameraROIGet sidxCamera, x0, y0, xf, yf, sidxStatus
					Printf "ROI: %d %d %d %d\r", x0, y0, xf, yf
					widthCCD=xf-x0+1
					heightCCD=yf-y0+1
				else
					// fake CCD size
					widthCCD=512
					heightCCD=512
				endif
			else
				// if zero cameras, then we fake
				areWeForReal=0;
				// fake CCD size
				widthCCD=512
				heightCCD=512
			endif
		endif
		//printf "areWeForReal: %d\r", areWeForReal
//		if (!areWeForReal)
//			Redimension /N=(widthCCD,heightCCD,nFramesBufferFake) bufferFrame		// sic: this is how Igor Pro organizes image data 
//		endif
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
	NVAR iLeftROIFake, iTopROIFake
	NVAR iRightROIFake, iBottomROIFake	 	// the ROI boundaries
	NVAR widthCCD, heightCCD

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
		iLeftROIFake=0
		iTopROIFake=0
		iRightROIFake=widthCCD
		iBottomROIFake=heightCCD
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End





Function CameraROISet(iLeft, iTop, iRight, iBottom)
	// Set the camera ROI
	// The ROI is specified in the unbinned pixel coordinates, which are image-style coordinates, 
	// with the upper-left pels being (0,0)
	// The ROI includes x coordinates [iLeft,iRight).  That is, the pixel with coord iRight is _not_ included.
	// The ROI includes y coordinates [iTop,iBottom).  That is, the pixel with coord iBottom is _not_ included.
	// iRight, iLeft must be an integer multiple of the current bin width
	// iBottom, iTop must be an integer multiple of the current bin height
	// The ROI will be (iRight-iLeft)/nBinWidth bins wide, and
	// (iBottom-iTop)/nBinHeight bins high.	
	Variable iLeft,iTop,iRight,iBottom
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR iLeftROIFake, iTopROIFake
	NVAR iBottomROIFake, iRightROIFake	 // the ROI boundaries

	// Actually set the ROI coordinates
	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraROISet sidxCamera, iLeft, iTop, iRight, iBottom, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraROISet: %s",errorMessage)
			endif
		else
			Abort "Called CameraROISet() before camera was created."
		endif
	else
		iLeftROIFake=iLeft
		iTopROIFake=iTop
		iRightROIFake=iRight
		iBottomROIFake=iBottom
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End





Function CameraBinningItemSet(iBinningMode)
	Variable iBinningMode
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR iBinningModeFake

	// Set the bin sizes
	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraBinningItemSet sidxCamera, iBinningMode, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraBinningItemSet: %s",errorMessage)
			endif
		else
			Abort "Called CameraBinningItemSet() before camera was created."
		endif
	else
		iBinningModeFake=iBinningMode
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End





Function CameraTriggerModeSet(triggerMode)
	Variable triggerMode
	
	//Variable NO_TRIGGER=0	// start immediately
	//Variable TRIGGER_EXPOSURE_START=1	// start of each frame is TTL-triggered
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR modeTriggerFake

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
		modeTriggerFake=triggerMode
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End



Function CameraTriggerModeGet()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR modeTriggerFake

	Variable triggerMode
	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraTriggerModeGet sidxCamera, triggerMode, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraTriggerModeGet: %s",errorMessage)
			endif
		else
			Abort "Called CameraTriggerModeGet() before camera was created."
		endif
	else
	triggerMode=modeTriggerFake
	endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	return triggerMode
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
	NVAR exposureFake		// in seconds

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
		exposureFake=exposureInSeconds
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraAcquireImageSetLimit(nFrames)
	Variable nFrames
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR nFramesToAcquireFake

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraAcquireImageSetLimit sidxCamera, nFrames, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraAcquireImageSetLimit: %s",errorMessage)
			endif
		else
			Abort "Called CameraAcquireImageSetLimit() before camera was created."
		endif
	else
		 nFramesToAcquireFake=nFrames
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraBufferCountSet(nFrames)
	Variable nFrames
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR  nFramesBufferFake

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraBufferCountSet sidxCamera, nFrames, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraBufferCountSet: %s",errorMessage)
			endif
		else
			Abort "Called CameraBufferCountSet() before camera was created."
		endif
	else
		 nFramesBufferFake=nFrames
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraAcquireArm()
	// This basically "arms" the camera for acquisition.  It returns 1 if
	// this was successful, 0 otherwise.
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer
	NVAR isAcquireOpenFake

	Variable success
	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraAcquireOpen sidxCamera, sidxAcquirer, sidxStatus
			if (sidxStatus!=0)
				isSidxAcquirerValid=0
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				CameraSetErrorMessage(sprintf1s("Error in SIDXCameraAcquireOpen: %s",errorMessage))
				//Abort sprintf1s("Error in SIDXCameraAcquireOpen: %s",errorMessage)
				success=0
			else
				isSidxAcquirerValid=1
				success=1
			endif
		else
			Printf "Called CameraAcquireArm() before camera was created.\r"
			success=0
		endif
	else
		isAcquireOpenFake=1
		success=1
	endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	return success
End






Function CameraAcquireStart()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer
	NVAR isAcquisitionOngoingFake

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxAcquirerValid)
			SIDXAcquireStart sidxAcquirer, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquirer, errorMessage
				Abort sprintf1s("Error in SIDXAcquireStart: %s",errorMessage)
			endif
		else
			Abort "Called CameraAcquireStart() before acquisition was armed."
		endif
	else
		isAcquisitionOngoingFake=1
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End




Function CameraAcquireGetStatus()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer
	NVAR isAcquisitionOngoingFake

	Variable isAcquiring
	Variable sidxStatus
	if (areWeForReal)
		if (isSidxAcquirerValid)
			SIDXAcquireGetStatus sidxAcquirer, isAcquiring, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquirer, errorMessage
				Abort sprintf1s("Error in SIDXAcquireStart: %s",errorMessage)
			endif
		else
			Abort "Called CameraAcquireGetStatus() before acquisition was armed."
		endif
	else
		isAcquiring=0	// if faking, we always claim that we're done
	endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	// return
	return isAcquiring
End





Function CameraAcquireStop()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer
	NVAR isAcquisitionOngoingFake
	WAVE bufferFrame
	NVAR widthCCD, heightCCD
	NVAR widthBinFake, heightBinFake
	NVAR iLeftROIFake, iTopROIFake
	NVAR iRightROIFake, iBottomROIFake	// the ROI boundaries
	NVAR nFramesBufferFake
	NVAR nFramesToAcquireFake
	NVAR countReadFrameFake
	NVAR exposureFake
	
	Variable sidxStatus
	if (areWeForReal)
		if (isSidxAcquirerValid)
			SIDXAcquireStop sidxAcquirer, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquirer, errorMessage
				Abort sprintf1s("Error in SIDXAcquireStop: %s",errorMessage)
			endif
		else
			Abort "Called CameraAcquireStop() before acquisition was armed."
		endif
	else
		// Fill the framebuffer with fake data
		Variable widthROIFake=iRightROIFake-iLeftROIFake
		Variable heightROIFake=iBottomROIFake-iTopROIFake
		Variable widthROIBinnedFake=floor(widthROIFake/widthBinFake)
		Variable heightROIBinnedFake=floor(heightROIFake/heightBinFake)			
		Redimension /N=(widthROIBinnedFake,heightROIBinnedFake,nFramesBufferFake) bufferFrame	// sic, this is how Igor Pro organizes image data
		SetScale /P x, iLeftROIFake+0.5*widthBinFake, widthBinFake, "px", bufferFrame		// Want the upper left corner of of the upper left pel to be at (0,0), not (-0.5,-0.5)
		SetScale /P y, iTopROIFake+0.5*heightBinFake, heightBinFake, "px", bufferFrame
		Variable interExposureDelay=0.001		// s, could be shift time for FT camera, or readout time for non-FT camera
		Variable frameInterval=exposureFake+interExposureDelay		// s, Add a millisecond of shift time, for fun
		Variable frameOffset=exposureFake/2
		// Assumes the first exposure starts at t==0, so the middle of it occurs at exposureFake/2.
		// After that, the middle of the next exposure comes frameInterval later, etc.
		SetScale /P z, 1000*frameOffset, 1000*frameInterval, "ms", bufferFrame		// s -> ms
		bufferFrame=2^15+(2^12)*gnoise(1)
		countReadFrameFake=0
		//bufferFrame=p
		
		// If there's a wave with base name "exposure" for this trial, overwrite it with a fake TTL exposure signal
		Variable iSweep=SweeperGetLastAcqSweepIndex()
		String exposureWaveNameRel=WaveNameFromBaseAndSweep("exposure",iSweep)
		String exposureWaveNameAbs=sprintf1s("root:%s",exposureWaveNameRel)
		if ( WaveExists($exposureWaveNameAbs) )
			Wave exposure=$exposureWaveNameAbs
			Variable dt=DimDelta(exposure,0)	// ms
			Variable nScans=DimSize(exposure,0)
			Variable delay=0	// ms
			Variable duration=1000*(frameInterval*nFramesToAcquireFake)	// s->ms
			Variable pulseRate=1/frameInterval	// Hz
			Variable pulseDuration=1000*exposureFake	// s->ms
			Variable baseLevel=0		// V
			Variable amplitude=5		// V, for a TTL signal
			Make /FREE parameters={delay,duration,pulseRate,pulseDuration,baseLevel,amplitude}
			Make /FREE /T parameterNames={"delay","duration","pulseRate","pulseDuration","baseLevel","amplitude"}
			fillTrainFromParamsBang(exposure,dt,nScans,parameters,parameterNames)
		endif
		
		// Note that the acquisiton is done
		isAcquisitionOngoingFake=0
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End





Function /WAVE CameraAcquireRead(nFramesToRead)
	Variable nFramesToRead

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer
	NVAR isAcquisitionOngoingFake
	WAVE bufferFrame
	NVAR iLeftROIFake, iTopROIFake
	NVAR iRightROIFake, iBottomROIFake
	NVAR widthBinFake, heightBinFake
	NVAR countReadFrameFake

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxAcquirerValid)
			Make /O framesCaged
			// OK, done allocating frames
			SIDXAcquireRead sidxAcquirer, nFramesToRead, framesCaged, sidxStatus	// doesn't seem to work if frames is a free wave
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquirer, errorMessage
				Abort sprintf1s("Error in SIDXAcquireRead: %s",errorMessage)
			endif
			Duplicate /FREE framesCaged, frames
		else
			Abort "Called CameraAcquireRead() before acquisition was armed."
		endif
	else
		if (isAcquisitionOngoingFake)
			Abort "Have to stop the fake acquisition before reading the fake data."
		endif
		Variable widthROIFake=iRightROIFake-iLeftROIFake
		Variable heightROIFake=iBottomROIFake-iTopROIFake
		Variable widthROIBinnedFake=floor(widthROIFake/widthBinFake)
		Variable heightROIBinnedFake=floor(heightROIFake/heightBinFake)			
		Duplicate /FREE /R=[][][countReadFrameFake,countReadFrameFake+nFramesToRead] bufferFrame frames
		countReadFrameFake+=nFramesToRead
	endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	// Return result
	return frames
End






Function CameraAcquireDisarm()
	// This "disarms" acquisition, allowing settings to be set again

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer		
	NVAR isAcquireOpenFake
	NVAR isAcquisitionOngoingFake

	// Close the SIDX Acquire object	
	Variable sidxStatus
	if (areWeForReal)
		if (isSidxAcquirerValid)
			SIDXAcquireClose sidxAcquirer, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquirer, errorMessage
				Abort sprintf1s("Error in SIDXAcquireClose: %s",errorMessage)
			else
				// Successfully close the acquirer
				isSidxAcquirerValid=0
			endif
		else
			Abort "Called CameraAcquireDisarm() before acquisition was armed."
		endif
	else
		if (isAcquisitionOngoingFake)
			Abort "Have to stop the fake acquisition before disarming."
		endif
		isAcquireOpenFake=0		// Whether acquisition is "armed"
	endif
	
	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraCoolingSet(temperatureTarget)
	Variable temperatureTarget

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR temperatureTargetFake

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraCoolingSet sidxCamera, temperatureTarget, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraCoolingSet: %s",errorMessage)
			endif
		else
			Abort "Called CameraCoolingSet() before camera was created."
		endif
	else
		temperatureTargetFake=temperatureTarget
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraCoolingGetValue()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR temperatureTargetFake

	Variable sidxStatus
	Variable temperature
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraCoolingGetValue sidxCamera, temperature, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				//Abort sprintf1s("Error in SIDXCameraCoolingGetValue: %s",errorMessage)
				Printf "Error in SIDXCameraCoolingGetValue: %s\r", errorMessage
				temperature=nan
			endif
		else
			Abort "Called CameraCoolingGetValue() before camera was created."
		endif
	else
		temperature=temperatureTargetFake
	endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	return temperature
End






Function CameraDestructor()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
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
		if (sidxStatus!=0)
			SIDXAcquireGetLastError sidxAcquirer, errorMessage
			Printf "Error in SIDXAcquireClose: %s\r", errorMessage
		endif
		isSidxAcquirerValid=0	
	endif
	
	// Close the SIDX Camera object
	if (isSidxCameraValid)
		SIDXCameraClose sidxCamera, sidxStatus
		if (sidxStatus!=0)
			SIDXCameraGetLastError sidxCamera, errorMessage
			Printf "Error in SIDXCameraClose: %s\r", errorMessage
		endif
		isSidxCameraValid=0	
	endif
	
	// Close the SIDX root object
	if (isSidxRootValid)
		SIDXRootClose sidxRoot, sidxStatus
		if (sidxStatus!=0)
			SIDXRootGetLastError sidxCamera, errorMessage
			Printf "Error in SIDXRootClose: %s\r", errorMessage
		endif
		isSidxRootValid=0
	endif
	
	// Restore the data folder
	SetDataFolder savedDF	

	// Switch to the root data folder
	SetDataFolder root:
	
	// Delete the camera DF
	KillDataFolder /Z root:DP_Camera
End






Function CameraCCDWidthGet()
	Variable value
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR widthCCD

	value=widthCCD
	
	// Restore the data folder
	SetDataFolder savedDF	
	
	return value
End





Function CameraCCDHeightGet()
	Variable value
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR heightCCD

	value=heightCCD
	
	// Restore the data folder
	SetDataFolder savedDF	

	return value
End



Function CameraGetBinWidth()
	Variable value
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR widthBinFake
	NVAR sidxCamera

	if (areWeForReal)
		Variable binWidth, binHeight
		Variable sidxStatus
		SIDXCameraBinningGet sidxCamera, binWidth, binHeight, sidxStatus
		if (sidxStatus==0)
			value=binWidth
		else
			value=nan
			String errorMessage
			SIDXCameraGetLastError sidxCamera, errorMessage
			Printf "Error in SIDXCameraBinningGet: %s", errorMessage
		endif
	else
		value=widthBinFake
	endif
	
	// Restore the data folder
	SetDataFolder savedDF	
	
	return value
End




Function CameraGetBinHeight()
	Variable value
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR heightBinFake
	NVAR sidxCamera

	if (areWeForReal)
		Variable binWidth, binHeight
		Variable sidxStatus
		SIDXCameraBinningGet sidxCamera, binWidth, binHeight, sidxStatus
		if (sidxStatus==0)
			value=binHeight
		else
			value=nan
			String errorMessage			
			SIDXCameraGetLastError sidxCamera, errorMessage
			Printf "Error in SIDXCameraBinningGet: %s", errorMessage
		endif
	else
		value=heightBinFake
	endif
	
	// Restore the data folder
	SetDataFolder savedDF	
	
	return value
End




Function /S CameraGetErrorMessage()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	SVAR mostRecentErrorMessage

	String result=mostRecentErrorMessage

	// Restore the data folder
	SetDataFolder savedDF	
	
	return result
End




Function CameraSetErrorMessage(newValue)
	String newValue

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	SVAR mostRecentErrorMessage

	mostRecentErrorMessage=newValue

	// Restore the data folder
	SetDataFolder savedDF	
End




Function CameraIsValidBinWidth(nBinWidth)
	Variable nBinWidth
	
	Variable result
	Variable ccdWidth=CameraCCDWidthGet()
	if ( (1<=nBinWidth) && (nBinWidth<=ccdWidth) )
		Variable nBins=ccdWidth/nBinWidth
		result=IsInteger(nBins)
	else
		result=0
	endif
	return result
End





Function CameraIsValidBinHeight(nBinHeight)
	Variable nBinHeight
	
	Variable result
	Variable ccdHeight=CameraCCDHeightGet()
	if ( (1<=nBinHeight) && (nBinHeight<=ccdHeight) )
		Variable nBins=ccdHeight/nBinHeight
		result=IsInteger(nBins)
	else
		result=0
	endif
	return result
End




