//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

// The Camera "object" wraps all the SIDX functions, so the "FancyCamera" object doesn't have to deal 
// with them directly.  It also deals with errors internally, so you don't have to worry about them 
// at the next level up (where possible).  And it adds the ability to fake a camera, for when there is no 
// camera attached.

// Construct the object
Function CameraConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)

	// If the data folder does not already exist, create it and set up the camera
	String errorMessage
	if (DataFolderExists("root:DP_Camera"))
		// If the data folder exists, double check that any supposedly-valid SIDX handles really are valid.
		// We do this in case an experiment has just been loaded.  In this case, the camera constructor gets
		// called, so this is a good place to verify that any supposedly-valid SIDX handles really are valid.
		CameraValidifySidxHandles()
		CameraSetTransform( CameraGetUserFromCameraReflectX(), CameraGetUserFromCameraReflectY(), CameraGetUserFromCameraSwapXY() )
	else
		// If the data folder doesn't exist, create it (and switch to it)
		// IMAGING GLOBALS
		NewDataFolder /O /S root:DP_Camera
				
		// SIDX stuff
		Variable /G areWeForReal		// boolean; if false, we have decided to fake the camera
		Variable /G isSidxRootValid=0	// boolean
		Variable /G sidxRoot
		Variable /G isSidxCameraValid=0	// boolean
		Variable /G sidxCamera	
		Variable /G isSidxAcquireValid=0	// boolean
		Variable /G sidxAcquire
		//Make /N=(0,0,0) bufferFrame	// Will hold the acquired frames
		Variable /G widthCCD=nan		// width of the CCD
		Variable /G heightCCD=nan	// height of the CCD

		// This stuff is only needed/used if there's no camera and we're faking
		Variable /G modeTriggerFake=0		// the trigger mode of the fake camera. 0=>free-running, 1=> each frame is triggered, and there are other settings
		Variable /G binSize=nan		
			// We sometimes want to know this when the camera is armed, and it won't tell us when armed, so we store it
		//Variable /G binHeight=nan
		Variable /G iLeft=0		// The left bound of the ROI.  The includes the pels with this index.
		Variable /G iTop=0
		Variable /G iBottom=nan
		Variable /G iRight=nan
		Variable /G exposureWantedInSeconds=nan		// cached exposure wanted for the camera, in sec
		Variable /G temperatureTarget=-40		// degC
		Variable /G nFramesBufferFake=1		// How many frames in the fake on-camera frame buffer
		//Variable /G nFramesToAcquireFake=1		
		Variable /G isAcquireOpenFake=0		// Whether acquisition is "armed"
		Variable /G isAcquisitionOngoingFake=0
		Variable /G nFramesAcquiredFake
		//Variable /G countReadFrameFake=0		// the first frame to be read by subsequent read commands
		String /G mostRecentErrorMessage=""		// When errors occur, they get stored here.
		
		Variable /G userFromCameraReflectX=0	// boolean
		Variable /G userFromCameraReflectY=0	// boolean
		Variable /G userFromCameraSwapXY=0	// boolean
		// To go from camera to user, we reflect X (or not), reflect Y (or not), and then swap X and Y (or not)
		// In that order---(possible) reflections then (possible) swap
		// This covers all 8 possible transforms, including rotations and anything else
		
		// Create the SIDX root object, referenced by sidxRoot
		sidxRoot=CameraTryToGetSidxRootHandle()
		isSidxRootValid=(sidxRoot>=0)
		if (isSidxRootValid)
			sidxCamera=CameraTryToGetSidxCameraHandle(sidxRoot)
			if (sidxCamera<0)
				isSidxCameraValid=0
			else
				CameraInitCCDDims()
				isSidxCameraValid=CameraInitSidxCamera(sidxCamera)
			endif
		endif
		areWeForReal=isSidxCameraValid
		if (!areWeForReal)
			// if unable to get a camera object, we fake
			widthCCD=512
			heightCCD=512
			iBottom=heightCCD-1
			iRight=widthCCD-1
			binSize=1
			exposureWantedInSeconds=0.05
		endif		
	endif

	// Notify the hardware of the target temp
	CameraCoolingSetToInstanceVar()

	// Restore the data folder
	SetDataFolder savedDF	
End



//Function CameraSetUserFromCameraMatrix(userFromCameraMatrix)
Function CameraSetTransform(userFromCameraReflectXNew,userFromCameraReflectYNew,userFromCameraSwapXYNew)
	// This is currently hardcoded to one specific transform.
	// Need to generalize this--it's pretty embarassing at present.
	// Also need to handle this properly for a fake camera
	Variable userFromCameraReflectXNew	// boolean
	Variable userFromCameraReflectYNew	// boolean
	Variable userFromCameraSwapXYNew	// boolean

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR userFromCameraReflectX
	NVAR userFromCameraReflectY
	NVAR userFromCameraSwapXY

	// Set them
	userFromCameraReflectX=userFromCameraReflectXNew	// boolean
	userFromCameraReflectY=userFromCameraReflectYNew	// boolean
	userFromCameraSwapXY=userFromCameraSwapXYNew	// boolean

	// Need these below
	Variable sidxStatus
	String errorMessage

	// In it's current incarnation (SIDX 7.28), the SIDX software translations don't actually seem to do what they say they do.
	//SIDXCameraRotateMirrorX actually mirrors in y
	//SIDXCameraRotateMirrorY actually mirrors in x
	//SIDXCameraRotateSet(n) actually does n CCW rotations
	// We'll have to keep this in mind to translate our desired transformation into SIDX calls

#if (exists("SIDXRootOpen")==4)
	if (isSidxCameraValid)
		SIDXCameraRotateClear sidxCamera, sidxStatus
		if (sidxStatus!=0)
			SIDXCameraGetLastError sidxCamera, errorMessage
			DoAlert 0, sprintf1s("Error in SIDXCameraRotateClear: %s",errorMessage)
		endif
	endif
		
	if (isSidxCameraValid && userFromCameraReflectX)
		SIDXCameraRotateMirrorY sidxCamera, sidxStatus
		if (sidxStatus!=0)
			SIDXCameraGetLastError sidxCamera, errorMessage
			DoAlert 0, sprintf1s("Error in SIDXCameraRotateMirrorY: %s",errorMessage)
		endif
	endif
	
	if (isSidxCameraValid && userFromCameraReflectY)
		SIDXCameraRotateMirrorX sidxCamera, sidxStatus
		if (sidxStatus!=0)
			SIDXCameraGetLastError sidxCamera, errorMessage
			DoAlert 0, sprintf1s("Error in SIDXCameraRotateMirrorX: %s",errorMessage)
		endif
	endif
	
	if (isSidxCameraValid && userFromCameraSwapXY)
		// There may be a slightly cleaner way to do this, but this works.
		SIDXCameraRotateMirrorX sidxCamera, sidxStatus
		if (sidxStatus!=0)
			SIDXCameraGetLastError sidxCamera, errorMessage
			DoAlert 0, sprintf1s("Error in SIDXCameraRotateMirrorX: %s",errorMessage)
		endif
	
		Variable n90DegCCWRotations=3
		SIDXCameraRotateSet sidxCamera, n90DegCCWRotations, sidxStatus
		if (sidxStatus!=0)
			SIDXCameraGetLastError sidxCamera, errorMessage
			DoAlert 0, sprintf1s("Error in SIDXCameraRotateSet: %s",errorMessage)
		endif
	endif
#endif	

	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraROIClear(nBinSize)
	Variable nBinSize

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR iLeft, iTop
	NVAR iRight, iBottom	 	// the ROI boundaries
	NVAR widthCCD, heightCCD

	Variable sidxStatus
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxCameraValid)
			String errorMessage
			SIDXCameraROIClear sidxCamera, sidxStatus
			if (sidxStatus!=0)
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraROIClear: %s",errorMessage)
			endif	
			SIDXCameraROIGetValue sidxCamera, iLeft, iTop, iRight, iBottom, sidxStatus
			if (sidxStatus!=0)
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraROIGetValue: %s",errorMessage)
			endif	
		else
			Abort "Called CameraROIClear() before camera was created."
		endif
	else
#endif
		iLeft=0
		iTop=0
		iRight=widthCCD-1
		iBottom=heightCCD-1		
#if (exists("SIDXRootOpen")==4)
	endif
#endif		

	// Now, set the bin size
	CameraBinSizeSet(nBinSize)

	// Restore the data folder
	SetDataFolder savedDF	
End





Function CameraROISetToROIsInUserSpace(roisWave,nBinSize)
	// Set the ROI for the camera, given the user ROIs.  Note that the input coords are in user coordinate space, so
	// we have to translate them to CCD coordinate space.
	Wave roisWave
	Variable nBinSize
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR userFromCameraReflectX
	NVAR userFromCameraReflectY
	NVAR userFromCameraSwapXY

	// Clear the ROI	
	CameraROIClear(nBinSize)
	
	Variable nROIs=DimSize(roisWave,1)
	if (nROIs>0)
		// Calc the ROI that just includes all the ROIs, in same (user image heckbertian) coords as the ROIs themselves
		Wave boundingROIInUS=boundingROIFromROIs(roisWave)
		Wave boundingROIInCS=cameraROIFromUserROI(boundingROIInUS,userFromCameraReflectX,userFromCameraReflectY,userFromCameraSwapXY)
		Wave alignedROIInCS=alignCameraROIToGrid(boundingROIInCS,nBinSize)
		CameraSetROIInCSAndAligned(alignedROIInCS)
	endif
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
	
#if (exists("SIDXRootOpen")==4)
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
#endif
		modeTriggerFake=triggerMode
#if (exists("SIDXRootOpen")==4)
	endif
#endif

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
#if (exists("SIDXRootOpen")==4)
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
#endif
		triggerMode=modeTriggerFake
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	return triggerMode
End






Function CameraExposeGetValue()
	// Get the actual (not the desired) camera exposure duration, in seconds.
	// Returns nan if the value cannot be determined.

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR exposureWantedInSeconds

	Variable exposureInSeconds
	Variable sidxStatus
	String errorMessage
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraExposeGetValue sidxCamera, exposureInSeconds, sidxStatus
			if (sidxStatus!=0)
				SIDXCameraGetLastError sidxCamera, errorMessage
				CameraSetErrorMessage(sprintf1s("Error in SIDXCameraTriggerModeGet: %s",errorMessage))
				exposureInSeconds=nan
			endif
		else
			CameraSetErrorMessage("Called CameraExpsoreGetValue() before camera was created.")
			exposureInSeconds=nan
		endif
	else
#endif
		exposureInSeconds=exposureWantedInSeconds
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	return exposureInSeconds
End






Function CameraExposeSet(newValue)
	Variable newValue	// in seconds
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR exposureWantedInSeconds		// in seconds

	Variable sidxStatus
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraExposeSet sidxCamera, newValue, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraExposeSet: %s",errorMessage)
			endif
			CameraSyncExposureWanted()
		else
			Abort "Called CameraExposeSet() before camera was created."
		endif
	else
#endif
		exposureWantedInSeconds=newValue
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF	
End






//Function CameraAcquireImageSetLimit(nFrames)
//	Variable nFrames
//	
//	// Switch to the imaging data folder
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:DP_Camera
//
//	// Declare instance variables
//	NVAR areWeForReal
//	NVAR isSidxCameraValid
//	NVAR sidxCamera
//	NVAR nFramesToAcquireFake
//
//	Variable sidxStatus
//#if (exists("SIDXRootOpen")==4)
//	if (areWeForReal)
//		if (isSidxCameraValid)
//			SIDXCameraAcquireImageSetLimit sidxCamera, nFrames, sidxStatus
//			if (sidxStatus!=0)
//				String errorMessage
//				SIDXCameraGetLastError sidxCamera, errorMessage
//				Abort sprintf1s("Error in SIDXCameraAcquireImageSetLimit: %s",errorMessage)
//			endif
//		else
//			Abort "Called CameraAcquireImageSetLimit() before camera was created."
//		endif
//	else
//#endif
//		 nFramesToAcquireFake=nFrames
//#if (exists("SIDXRootOpen")==4)
//	endif
//#endif
//
//	// Restore the data folder
//	SetDataFolder savedDF	
//End






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
#if (exists("SIDXRootOpen")==4)
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
#endif
		 nFramesBufferFake=nFrames
#if (exists("SIDXRootOpen")==4)
	endif
#endif

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
	NVAR isSidxAcquireValid
	NVAR sidxAcquire
	NVAR isAcquireOpenFake

	Variable success
	Variable sidxStatus
	String errorMessage
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxCameraValid)
			// debug code here
			//CameraProbeStatusAndPrintf(sidxCamera)
			// real code starts here
			SIDXCameraAcquireOpen sidxCamera, sidxAcquire, sidxStatus
			if (sidxStatus!=0)
				isSidxAcquireValid=0
				SIDXCameraGetLastError sidxCamera, errorMessage
				CameraSetErrorMessage(sprintf1s("Error in SIDXCameraAcquireOpen: %s",errorMessage))
				//Abort sprintf1s("Error in SIDXCameraAcquireOpen: %s",errorMessage)
				success=0
			else
				isSidxAcquireValid=1
				success=1
			endif
		else
			CameraSetErrorMessage("Called CameraAcquireArm() before camera was created.")
			success=0
		endif
	else
#endif
		isAcquireOpenFake=1
		success=1
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	return success
End






Function CameraAcquireStart()
	// This starts the acquisition.  It returns 1 if
	// this was successful, 0 otherwise.

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquireValid
	NVAR sidxAcquire
	NVAR isAcquisitionOngoingFake
	NVAR nFramesAcquiredFake

	Variable success
	Variable sidxStatus
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxAcquireValid)
			SIDXAcquireStart sidxAcquire, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquire, errorMessage
				//Abort sprintf1s("Error in SIDXAcquireStart: %s",errorMessage)
				CameraSetErrorMessage(sprintf1s("Error in SIDXAcquireStart: %s",errorMessage))
				success=0
			else
				success=1
			endif
		else
			CameraSetErrorMessage("Called CameraAcquireStart() before acquisition was armed.")
			success=0
		endif
	else
#endif
		isAcquisitionOngoingFake=1
		nFramesAcquiredFake=0
		success=1
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	return success
End




Function CameraAcquireGetStatus()
	// Returns 1 if the camera is acquiring, 0 if not, and -1 on error

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquireValid
	NVAR sidxAcquire
	NVAR isAcquisitionOngoingFake

	Variable isAcquiring
	Variable sidxStatus
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxAcquireValid)
			SIDXAcquireGetStatus sidxAcquire, isAcquiring, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquire, errorMessage
				//Abort sprintf1s("Error in SIDXAcquireGetStatus: %s",errorMessage)
				CameraSetErrorMessage(sprintf1s("Error in SIDXAcquireGetStatus: %s",errorMessage))
				isAcquiring=-1
			endif
		else
			CameraSetErrorMessage("Called CameraAcquireGetStatus() before acquisition was armed.")
			isAcquiring=-1
		endif
	else
#endif
		isAcquiring=isAcquisitionOngoingFake
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	// return
	return isAcquiring
End





Function CameraAcquireImageGetCount()
	// Returns number of images acquires since acquisition started, or -1 on error

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquireValid
	NVAR sidxAcquire
	NVAR isAcquisitionOngoingFake
	NVAR nFramesAcquiredFake
	//NVAR nFramesToAcquireFake

	Variable nFramesAcquired
	Variable sidxStatus
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxAcquireValid)
			SIDXAcquireImageGetCount sidxAcquire, nFramesAcquired, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquire, errorMessage
				//Abort sprintf1s("Error in SIDXAcquireGetStatus: %s",errorMessage)
				CameraSetErrorMessage(sprintf1s("Error in SIDXAcquireImageGetCount: %s",errorMessage))
				nFramesAcquired=-1
			endif
		else
			CameraSetErrorMessage("Called CameraAcquireImageGetCount() before acquisition was armed.")
			nFramesAcquired=-1
		endif
	else
#endif
		nFramesAcquiredFake+=1
		nFramesAcquired=nFramesAcquiredFake	// if faking, we always say we've acquired one more frame than last time, unless we've acquired the full number of frames
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	// return
	return nFramesAcquired
End





//Function CameraAcquireStop()
//	// Switch to the imaging data folder
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:DP_Camera
//
//	// Declare instance variables
//	NVAR areWeForReal
//	NVAR isSidxAcquireValid
//	NVAR sidxAcquire
//	NVAR isAcquisitionOngoingFake
//	//WAVE bufferFrame
//	NVAR widthCCD, heightCCD
//	NVAR binSize
//	NVAR iLeft, iTop
//	NVAR iRight, iBottom	// the ROI boundaries
//	NVAR nFramesBufferFake
//	//NVAR nFramesToAcquireFake
//	NVAR nFramesAcquiredFake
//	//NVAR countReadFrameFake
//	NVAR exposureWantedInSeconds
//	
//	Variable sidxStatus
//#if (exists("SIDXRootOpen")==4)
//	if (areWeForReal)
//		if (isSidxAcquireValid)
//			SIDXAcquireStop sidxAcquire, sidxStatus
//			if (sidxStatus!=0)
//				String errorMessage
//				SIDXAcquireGetLastError sidxAcquire, errorMessage
//				Abort sprintf1s("Error in SIDXAcquireStop: %s",errorMessage)
//			endif
//		else
//			Abort "Called CameraAcquireStop() before acquisition was armed."
//		endif
//	else
//#endif
////		Variable interExposureDelay=0.001		// s, could be shift time for FT camera, or readout time for non-FT camera
////		Variable frameInterval=exposureWantedInSeconds+interExposureDelay		// s, Add a millisecond of shift time, for fun
////		Variable frameOffset=exposureWantedInSeconds/2
////		
////		// If there's a wave with base name "exposure" for this trial, overwrite it with a fake TTL exposure signal
////		Variable iSweep=SweeperGetLastAcqSweepIndex()
////		String exposureWaveNameRel=WaveNameFromBaseAndSweep("exposure",iSweep)
////		String exposureWaveNameAbs=sprintf1s("root:%s",exposureWaveNameRel)
////		if ( WaveExistsByName(exposureWaveNameAbs) )
////			Wave exposure=$exposureWaveNameAbs
////			Variable dt=DimDelta(exposure,0)	// ms
////			Variable nScans=DimSize(exposure,0)
////			Variable delay=0	// ms
////			Variable duration=1000*(frameInterval*nFramesAcquiredFake)	// s->ms
////			Variable pulseRate=1/frameInterval	// Hz
////			Variable pulseDuration=1000*exposureWantedInSeconds	// s->ms
////			Variable baseLevel=0		// V
////			Variable amplitude=5		// V, for a TTL signal
////			Make /FREE parameters={delay,duration,pulseRate,pulseDuration,baseLevel,amplitude}
////			Make /FREE /T parameterNames={"delay","duration","pulseRate","pulseDuration","baseLevel","amplitude"}
////			//fillTrainFromParamsBang(exposure,dt,nScans,parameters,parameterNames)
////			StimulusSetParams(exposure,parameters)
////		endif
//		
//		// Note that the acquisiton is done
//		isAcquisitionOngoingFake=0
//#if (exists("SIDXRootOpen")==4)
//	endif
//#endif
//
//	// Restore the data folder
//	SetDataFolder savedDF	
//End





Function CameraAcquireAbort()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquireValid
	NVAR sidxAcquire
	NVAR isAcquisitionOngoingFake
	//WAVE bufferFrame
	NVAR widthCCD, heightCCD
	NVAR binSize
	NVAR iLeft, iTop
	NVAR iRight, iBottom	// the ROI boundaries
	NVAR nFramesBufferFake
	//NVAR nFramesToAcquireFake
	NVAR nFramesAcquiredFake
	//NVAR countReadFrameFake
	NVAR exposureWantedInSeconds
	
	Variable sidxStatus
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxAcquireValid)
			SIDXAcquireAbort sidxAcquire, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquire, errorMessage
				Abort sprintf1s("Error in SIDXAcquireAbort: %s",errorMessage)
			endif
		else
			Abort "Called CameraAcquireAbort() before acquisition was armed."
		endif
	else
#endif
//		Variable interExposureDelay=0.001		// s, could be shift time for FT camera, or readout time for non-FT camera
//		Variable frameInterval=exposureWantedInSeconds+interExposureDelay		// s, Add a millisecond of shift time, for fun
//		Variable frameOffset=exposureWantedInSeconds/2
//		
//		// If there's a wave with base name "exposure" for this trial, overwrite it with a fake TTL exposure signal
//		Variable iSweep=SweeperGetLastAcqSweepIndex()
//		String exposureWaveNameRel=WaveNameFromBaseAndSweep("exposure",iSweep)
//		String exposureWaveNameAbs=sprintf1s("root:%s",exposureWaveNameRel)
//		if ( WaveExistsByName(exposureWaveNameAbs) )
//			Wave exposure=$exposureWaveNameAbs
//			Variable dt=DimDelta(exposure,0)	// ms
//			Variable nScans=DimSize(exposure,0)
//			Variable delay=0	// ms
//			Variable duration=1000*(frameInterval*nFramesAcquiredFake)	// s->ms
//			Variable pulseRate=1/frameInterval	// Hz
//			Variable pulseDuration=1000*exposureWantedInSeconds	// s->ms
//			Variable baseLevel=0		// V
//			Variable amplitude=5		// V, for a TTL signal
//			Make /FREE parameters={delay,duration,pulseRate,pulseDuration,baseLevel,amplitude}
//			Make /FREE /T parameterNames={"delay","duration","pulseRate","pulseDuration","baseLevel","amplitude"}
//			//fillTrainFromParamsBang(exposure,dt,nScans,parameters,parameterNames)
//			//StimulusSetParams(exposure,parameters)
//			
//			// Have to fil the samples "manually", because want the WAVETYPE to stay "adc"
//			String stimulusType="TTLTrain"
//			String fillFunctionName=stimulusType+"FillFromParams"
//			Funcref StimulusFillFromParamsSig fillFunction=$fillFunctionName
//			fillFunction(exposure,parameters)
//
//		endif
		
		// Note that the acquisiton is done
		isAcquisitionOngoingFake=0
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF	
End





Function CameraAcquireReadBang(framesCaged,nFramesToRead)
	// Read the just-acquired frames from the camera.
	// Note that the returned wave will not have an accurate time offset, the offset will just be zero.
	// And the frame interval scaling for the time dimension will be whatever the camera tells us it was.
	Wave framesCaged	// A ref to a caged (non-free) wave, where the result is stored
	Variable nFramesToRead

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR sidxCamera
	NVAR isSidxAcquireValid
	NVAR sidxAcquire
	NVAR isAcquisitionOngoingFake
	//WAVE bufferFrame
	NVAR iLeft, iTop
	NVAR iRight, iBottom
	NVAR binSize
	//NVAR countReadFrameFake
	NVAR exposureWantedInSeconds

	Variable frameIntervalInSeconds	
	Variable sidxStatus
	String errorMessage
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxAcquireValid)
			Make /O framesCagedTemp
			//WAVE ref=$"framesCagedTemp"
			// OK, done allocating frames
			SIDXAcquireRead sidxAcquire, nFramesToRead, framesCagedTemp, sidxStatus	
				// doesn't seem to work if frames is a free wave, or a wave reference
			if (sidxStatus!=0)
				SIDXAcquireGetLastError sidxAcquire, errorMessage
				Abort sprintf1s("Error in SIDXAcquireRead: %s",errorMessage)
			endif
			Duplicate /O framesCagedTemp, framesCaged
			// Get the frame interval while we're here
			SIDXAcquireGetImageInterval sidxAcquire, frameIntervalInSeconds, sidxStatus
			if (sidxStatus!=0)
				SIDXAcquireGetLastError sidxAcquire, errorMessage
				Abort sprintf1s("Error in SIDXAcquireGetImageInterval: %s",errorMessage)
			endif
			
		else
			Abort "Called CameraAcquireReadBang() before acquisition was armed."
		endif
	else
#endif
		//if (isAcquisitionOngoingFake)
		//	Abort "Have to stop the fake acquisition before reading the fake data."
		//endif
		Variable widthROIFake=iRight-iLeft+1
		Variable heightROIFake=iBottom-iTop+1
		Variable widthROIBinnedFake=round(widthROIFake/binSize)
		Variable heightROIBinnedFake=round(heightROIFake/binSize)
		Redimension /N=(widthROIBinnedFake,heightROIBinnedFake,nFramesToRead) framesCaged
		framesCaged=2^15+(2^12)*gnoise(1)	// fill with noise
		frameIntervalInSeconds=exposureWantedInSeconds		// in a real acquire, the frame interval is always longer than the exposure, but whatevs
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	//
	// Set x, y, t axis for the frames
	//
		
	// set the time offset and scale
	Variable frameOffset=(1000*exposureWantedInSeconds)/2	// ms, middle of the first exposure
	Variable frameInterval=1000*frameIntervalInSeconds	// ms
	SetScale /P z, frameOffset, frameInterval, "ms", framesCaged	

	// Set the x and y offset and scale
	Wave roiInUS=CameraGetAlignedROIInUS()
	Variable xLeft=roiInUS[0]
	Variable yTop=roiInUS[1]
	SetScale /P x, xLeft+0.5*binSize, binSize, "px", framesCaged		// Want the upper left corner of of the upper left pel to be at (0,0), not (-0.5,-0.5)
	SetScale /P y, yTop+0.5*binSize, binSize, "px", framesCaged

	// Restore the data folder
	SetDataFolder savedDF		
End






Function CameraAcquireReadAndAppendBang(framesCaged,nFramesToRead,nFramesReadAlready)
	// Read the just-acquired frames from the camera, and append them into framesCaged.
	// Note that this assumes framesCaged has been dimensioned already, and it doesn't change any 
	// of the axis scaling.
	Wave framesCaged	// A ref to a caged (non-free) wave, where the result is stored
	Variable nFramesToRead
	Variable nFramesReadAlready

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR sidxCamera
	NVAR isSidxAcquireValid
	NVAR sidxAcquire

	Variable i
	Variable sidxStatus
	String errorMessage
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxAcquireValid)
			Make /O newFramesCagedTemp
			SIDXAcquireRead sidxAcquire, nFramesToRead, newFramesCagedTemp, sidxStatus	
				// doesn't seem to work if frames is a free wave, or a wave reference
			if (sidxStatus!=0)
				SIDXAcquireGetLastError sidxAcquire, errorMessage
				Abort sprintf1s("Error in SIDXAcquireRead: %s",errorMessage)
			endif
			// Copy the new frames into framesCaged, in the right place
			for (i=0; i<nFramesToRead; i+=1)
				framesCaged[][][nFramesReadAlready+i]=newFramesCagedTemp[p][q][i]
			endfor
		else
			Abort "Called CameraAcquireReadAndAppendBang() before acquisition was armed."
		endif
	else
#endif
		for (i=0; i<nFramesToRead; i+=1)
			framesCaged[][][nFramesReadAlready+i]=2^15+(2^12)*gnoise(1)	// fill with noise
		endfor
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF		
End






Function CameraGetImageInterval()
	// Get the inter-frame interval, in seconds.
	// Returns nan if querying the camera fails

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquireValid
	NVAR sidxAcquire
	NVAR exposureWantedInSeconds

	Variable frameIntervalInSeconds
	Variable sidxStatus
	String errorMessage
	Variable wasCameraArmedAtEntry=isSidxAcquireValid
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (!isSidxAcquireValid)
			// If no valid acquire, need to get one
			Variable wasArmingSuccessful=CameraAcquireArm()
			if (!wasArmingSuccessful)
				frameIntervalInSeconds= nan
			endif
		endif
		if (isSidxAcquireValid)
			// Get the frame interval
			SIDXAcquireGetImageInterval sidxAcquire, frameIntervalInSeconds, sidxStatus
			if (sidxStatus!=0)
				SIDXAcquireGetLastError sidxAcquire, errorMessage
				CameraSetErrorMessage(sprintf1s("Error in SIDXAcquireGetImageInterval: %s",errorMessage))
				frameIntervalInSeconds= nan
			endif
		endif
	else
#endif
		// We're faking
		frameIntervalInSeconds=exposureWantedInSeconds		// in a real acquire, the frame interval is always longer than the exposure, but whatevs
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Disarm the camera if it was not armed on entry
	if (isSidxAcquireValid && !wasCameraArmedAtEntry)
		CameraAcquireDisarm()
	endif

	// Restore the data folder
	SetDataFolder savedDF
	
	// Return the value
	return frameIntervalInSeconds
End






Function CameraAcquireDisarm()
	// This "disarms" acquisition, allowing settings to be set again

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquireValid
	NVAR sidxAcquire		
	NVAR isAcquireOpenFake
	NVAR isAcquisitionOngoingFake

	// Close the SIDX Acquire object	
	Variable sidxStatus
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxAcquireValid)
			SIDXAcquireClose sidxAcquire, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquire, errorMessage
				Abort sprintf1s("Error in SIDXAcquireClose: %s",errorMessage)
			else
				// Successfully close the acquirer
				isSidxAcquireValid=0
			endif
		else
			// Don't throw an error here---if the user disarms the camera before arming it, that's not really a problem.
			//Abort "Called CameraAcquireDisarm() before acquisition was armed."
		endif
	else
#endif
		//if (isAcquisitionOngoingFake)
		//	Abort "Have to stop the fake acquisition before disarming."
		//endif
		isAcquisitionOngoingFake=0
		isAcquireOpenFake=0		// Whether acquisition is "armed"
#if (exists("SIDXRootOpen")==4)
	endif
#endif
	
	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraCoolingSet(newValue)
	Variable newValue

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR temperatureTarget

	Variable sidxStatus
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraCoolingSet sidxCamera, newValue, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraCoolingSet: %s",errorMessage)
			endif
			CameraSyncTemperatureTarget()	// copy the temp target in the hardware (which is hopefully the new value) back to the instance var
		else
			Abort "Called CameraCoolingSet() before camera was created."
		endif
	else
#endif
		temperatureTarget=newValue
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraCoolingGet()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR temperatureTarget

	Variable sidxStatus
	Variable targetTemp
#if (exists("SIDXRootOpen")==4)
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraCoolingGet sidxCamera, targetTemp, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				//Abort sprintf1s("Error in SIDXCameraCoolingGetValue: %s",errorMessage)
				Printf "Error in SIDXCameraCoolingGet: %s\r", errorMessage
				targetTemp=nan
			endif
		else
			Abort "Called CameraCoolingGet() before camera was created."
		endif
	else
#endif
		targetTemp=temperatureTarget
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	return targetTemp
End






Function CameraCoolingGetValue()
	if (!CameraExists())
		return nan
	endif
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR temperatureTarget

	Variable sidxStatus
	Variable temperature
#if (exists("SIDXRootOpen")==4)
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
#endif
		temperature=temperatureTarget
#if (exists("SIDXRootOpen")==4)
	endif
#endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	return temperature
End






Function CameraDestructor()
	if (!CameraExists())
		return 0
	endif
	
	// Switch to the imaging data folder
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR isSidxRootValid
	NVAR sidxRoot
	NVAR isSidxCameraValid
	NVAR sidxCamera	
	NVAR isSidxAcquireValid
	NVAR sidxAcquire		

	// This is used in lots of places
	Variable sidxStatus
	String errorMessage

#if (exists("SIDXRootOpen")==4)
	// Close the SIDX Acquire object
	if (isSidxAcquireValid)
		SIDXAcquireClose sidxAcquire, sidxStatus
		if (sidxStatus!=0)
			SIDXAcquireGetLastError sidxAcquire, errorMessage
			Printf "Error in SIDXAcquireClose: %s\r", errorMessage
		endif
		isSidxAcquireValid=0	
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
#endif
	
	// Switch to the root data folder
	SetDataFolder root:
	
	// Delete the camera DF
	KillDataFolder /Z root:DP_Camera
End






Function CameraGetIsForReal()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera
	NVAR areWeForReal
	Variable value=areWeForReal
	SetDataFolder savedDF		
	return value
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



Function CameraGetBinSize()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera
	NVAR binSize
	Variable value=binSize
	SetDataFolder savedDF		
	return value
End




//Function CameraGetBinHeight()
//	// Switch to the imaging data folder
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:DP_Camera
//	NVAR binSize
//	Variable value=binSize
//	SetDataFolder savedDF		
//	return value
//End




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




Function CameraIsValidBinSize(nBinSize)
	Variable nBinSize
	
	Variable result
	Variable ccdWidth=CameraCCDWidthGet()
	if ( (1<=nBinSize) && (nBinSize<=ccdWidth) )
		Variable nBins=ccdWidth/nBinSize
		result=IsInteger(nBins)
	else
		result=0
	endif
	return result
End





//Function CameraIsValidBinHeight(nBinHeight)
//	Variable nBinHeight
//	
//	Variable result
//	Variable ccdHeight=CameraCCDHeightGet()
//	if ( (1<=nBinHeight) && (nBinHeight<=ccdHeight) )
//		Variable nBins=ccdHeight/nBinHeight
//		result=IsInteger(nBins)
//	else
//		result=0
//	endif
//	return result
//End





Function CameraProbeStatusAndPrintf(sidxCamera)
	// This is mainly for debugging
	Variable sidxCamera

	Variable sidxStatus
	String errorMessage

#if (exists("SIDXRootOpen")==4)
	// Get the current operating mode, and the list of possible modes
	String modeAsString
	SIDXCameraOperateGet sidxCamera, modeAsString, sidxStatus
	if (sidxStatus==0)
		Printf "Camera mode is: %s\r", modeAsString
	else
		Printf "Unable to get camera mode.\r"
	endif
	Variable nModes
	SIDXCameraOperateItemGetCount sidxCamera, nModes, sidxStatus
	Variable modeIndex
	for (modeIndex=0; modeIndex<nModes; modeIndex+=1)
		SIDXCameraOperateItemGetLocal sidxCamera, modeIndex, modeAsString, sidxStatus
		Printf "Camera mode %d is: %s\r", modeIndex, modeAsString
	endfor
	
	// Probe the EM gain settings
	Variable emGainTypeCode
	SIDXCameraEMGainGetType sidxCamera, emGainTypeCode, sidxStatus
	if (sidxStatus==0)
		Printf "Camera EM gain type is %d, i.e. %s\r", emGainTypeCode, stringFromSIDXSettingTypeCode(emGainTypeCode)
	else
		Printf "Unable to get camera EM gain type.\r"
	endif				
	Variable minEMGain, maxEMGain
	SIDXCameraEMGainGetRange sidxCamera, minEMGain, maxEMGain, sidxStatus
	if (sidxStatus==0)
		Printf "Camera EM gain range is %d--%d\r", minEMGain, maxEMGain
	else
		Printf "Unable to get camera EM gain range.\r"
	endif							
	Variable emGainSetting
	SIDXCameraEMGainGet sidxCamera, emGainSetting, sidxStatus
	if (sidxStatus==0)
		Printf "Camera EM gain (as set) is %d\r", emGainSetting
	else
		Printf "Unable to get camera EM gain setting.\r"
	endif							
	Variable emGainActual
	SIDXCameraEMGainGetValue sidxCamera, emGainActual, sidxStatus
	if (sidxStatus==0)
		Printf "Camera EM gain (actual) is %d\r", emGainActual
	else
		Printf "Unable to get camera EM gain.\r"
	endif
	
	// Probe device-specific settings
	Variable nDeviceSpecificSettings
	SIDXDeviceExtraGetCount sidxCamera, nDeviceSpecificSettings, sidxStatus
	if (sidxStatus==0)
		Printf "Number of extra settings is %d\r", nDeviceSpecificSettings
	else
		Printf "Unable to get number of extra settings.\r"
	endif
	Variable settingIndex, typeCode
	String settingLabel
	for (settingIndex=0; settingIndex<nDeviceSpecificSettings; settingIndex+=1)
		SIDXDeviceExtraGetLabel sidxCamera, settingIndex, settingLabel, sidxStatus
		SIDXDeviceExtraGetType sidxCamera, settingIndex, typeCode, sidxStatus
		String settingValueAsString=getDeviceSettingValueAsString(sidxCamera, settingIndex)
		Printf "Camera device-specific setting %d is %s : %s, value is %s\r", settingIndex, settingLabel,stringFromSIDXSettingTypeCode(typeCode), settingValueAsString
	endfor

//			Make /FREE /T settingNames={"Accumulation count", "Frame transfer"}
//			Variable nSettings=numpnts(settingNames)
//			Variable i, settingValue
//			for (i=0; i<nSettings; i+=1)
//				String thisSettingName=settingNames[i]
//				SIDXDeviceExtraGetByName sidxCamera, thisSettingName, settingValue, sidxStatus	// this doesn't work, or I'm not using it right...
//				if (sidxStatus==0)
//					Printf "Camera device-specific setting %s is: %d\r", thisSettingName, settingValue
//				else
//					SIDXCameraGetLastError sidxCamera, errorMessage
//					Printf "Error in SIDXDeviceExtraGetByName: %s\r", errorMessage
//				endif
//			endfor
	
	// check the frame transfer mode
	Variable frameTransferSettingIndex=6
	Variable isFrameTransferOn
	SIDXDeviceExtraBooleanGet sidxCamera, frameTransferSettingIndex, isFrameTransferOn, sidxStatus
	Printf "isFrameTransferOn: %d\r", isFrameTransferOn
	
	// Check the accumulation count
	Variable accumulationCountSettingIndex=0
	Variable accumulationCount
	SIDXDeviceExtraIntegerGet sidxCamera, accumulationCountSettingIndex, accumulationCount, sidxStatus
	Printf "accumulationCount: %d\r", accumulationCount
	
	// Probe the device-specific actions
	Variable nDeviceSpecificActions
	SIDXDeviceActionGetCount sidxCamera, nDeviceSpecificActions, sidxStatus
	if (sidxStatus==0)
		Printf "Number of extra actions is %d\r", nDeviceSpecificActions
	else
		Printf "Unable to get number of extra actions.\r"
	endif
	Variable actionIndex
	String actionName
	for (actionIndex=0; actionIndex<nDeviceSpecificActions; actionIndex+=1)
		SIDXDeviceActionGetName sidxCamera, actionIndex, actionName, sidxStatus
		Printf "Camera device-specific action %d is %s\r", actionIndex, actionName
	endfor
#endif

End



Function /WAVE CameraGetAlignedROIInCS()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR iLeft, iTop
	NVAR iRight, iBottom	 	// the ROI boundaries, as pixel indices

	Make /FREE /N=4 roiInCSAligned={iLeft, iTop, iRight+1, iBottom+1}	// convert to heckbertian infinetesmal line coords

	// Restore the data folder
	SetDataFolder savedDF	
	
	return roiInCSAligned
End





Function /WAVE CameraGetAlignedROIInUS()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR userFromCameraReflectX
	NVAR userFromCameraReflectY
	NVAR userFromCameraSwapXY

	// Get the ROI, convert
	Wave roiInCS=CameraGetAlignedROIInCS()
	Wave roiInUS=userROIFromCameraROI(roiInCS,userFromCameraReflectX,userFromCameraReflectY,userFromCameraSwapXY)

	// Restore the data folder
	SetDataFolder savedDF	
	
	return roiInUS
End





Function CameraCCDWidthGetInUS()
	// This returns the "width" of the CCD in userspace.
	// Note that this may be equal to the CCD width or the CCD height, depending
	// on the userspace<->cameraspace transform.
		
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR userFromCameraReflectX
	NVAR userFromCameraReflectY
	NVAR userFromCameraSwapXY

	// Get the ROI, convert
	Make /FREE /N=4 roiInCS={0,0,CameraCCDWidthGet(),CameraCCDHeightGet()}
	Wave roiInUS=userROIFromCameraROI(roiInCS,userFromCameraReflectX,userFromCameraReflectY,userFromCameraSwapXY)

	// Restore the data folder
	SetDataFolder savedDF	
	
	return (roiInUS[2])
End





Function CameraCCDHeightGetInUS()
	// This returns the "height" of the CCD in userspace.
	// Note that this may be equal to the CCD width or the CCD height, depending
	// on the userspace<->cameraspace transform.
		
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR userFromCameraReflectX
	NVAR userFromCameraReflectY
	NVAR userFromCameraSwapXY

	// Get the ROI, convert
	Make /FREE /N=4 roiInCS={0,0,CameraCCDWidthGet(),CameraCCDHeightGet()}
	Wave roiInUS=userROIFromCameraROI(roiInCS,userFromCameraReflectX,userFromCameraReflectY,userFromCameraSwapXY)

	// Restore the data folder
	SetDataFolder savedDF	
	
	return (roiInUS[3])
End





Function CameraGetUserFromCameraReflectX()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera	
	NVAR userFromCameraReflectX
	Variable result=userFromCameraReflectX
	SetDataFolder savedDF	
	return result	
End





Function CameraGetUserFromCameraReflectY()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera	
	NVAR userFromCameraReflectY
	Variable result=userFromCameraReflectY
	SetDataFolder savedDF	
	return result	
End





Function CameraGetUserFromCameraSwapXY()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera	
	NVAR userFromCameraSwapXY
	Variable result=userFromCameraSwapXY
	SetDataFolder savedDF	
	return result	
End




