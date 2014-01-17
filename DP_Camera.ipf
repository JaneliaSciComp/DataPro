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
		//Make /N=(0,0,0) bufferFrame	// Will hold the acquired frames
		Variable /G widthCCD=nan		// width of the CCD
		Variable /G heightCCD=nan	// height of the CCD

		// This stuff is only needed/used if there's no camera and we're faking
		Variable /G modeTriggerFake=0		// the trigger mode of the fake camera. 0=>free-running, 1=> each frame is triggered, and there are other settings
		Variable /G binWidth=nan		// We sometimes want to know this when the camera is armed, and it therefore won't tell us, so we store it
		Variable /G binHeight=nan
		Variable /G iLeft=0		// The left bound of the ROI.  The includes the pels with this index.
		Variable /G iTop=0
		Variable /G iBottom=nan
		Variable /G iRight=nan
		Variable /G exposureInSeconds=nan		// cached exposure for the camera, in sec
		Variable /G temperatureTargetFake=-20		// degC
		Variable /G nFramesBufferFake=1		// How many frames in the fake on-camera frame buffer
		Variable /G nFramesToAcquireFake=1		
		Variable /G isAcquireOpenFake=0		// Whether acquisition is "armed"
		Variable /G isAcquisitionOngoingFake=0
		//Variable /G countReadFrameFake=0		// the first frame to be read by subsequent read commands
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
					SIDXCameraROIGetValue sidxCamera, iLeft, iTop, iRight, iBottom, sidxStatus
					if (sidxStatus!=0)
						SIDXCameraGetLastError sidxCamera, errorMessage
						Abort sprintf1s("Error in SIDXCameraROIGetValue: %s",errorMessage)
					endif						
					Printf "ROI: %d %d %d %d\r", iLeft, iTop, iRight, iBottom
					widthCCD=iRight-iLeft+1
					heightCCD=iBottom-iTop+1
					// Report on the camera state
					CameraProbeStatusAndPrintf(sidxCamera)
				else
					// fake CCD size
					widthCCD=512
					heightCCD=512
					iBottom=heightCCD-1
					iRight=widthCCD-1
				endif
			else
				// if zero cameras, then we fake
				areWeForReal=0;
				// fake CCD size
				widthCCD=512
				heightCCD=512
				iBottom=heightCCD-1
				iRight=widthCCD-1
				binWidth=1
				binHeight=1
				exposureInSeconds=0.05
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
	NVAR iLeft, iTop
	NVAR iRight, iBottom	 	// the ROI boundaries
	NVAR widthCCD, heightCCD

	Variable sidxStatus
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
		iLeft=0
		iTop=0
		iRight=widthCCD-1
		iBottom=heightCCD-1
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End





Function CameraROISet(iLeftNew, iTopNew, iRightNew, iBottomNew)
	// Set the camera ROI
	// The ROI is specified in the unbinned pixel coordinates, which are image-style coordinates, 
	// with the upper-left pels being (0,0)
	// The ROI includes x coordinates [iLeft,iRight].  That is, the pixel with coord iRight is included.
	// The ROI includes y coordinates [iTop,iBottom].  That is, the pixel with coord iBottom is included.
	// iRight, iLeft must be an integer multiple of the current bin width
	// iBottom, iTop must be an integer multiple of the current bin height
	// The ROI will be (iRight-iLeft+1)/nBinWidth bins wide, and
	// (iBottom-iTop+1)/nBinHeight bins high.	
	Variable iLeftNew,iTopNew,iRightNew,iBottomNew
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR iLeft, iTop
	NVAR iBottom, iRight	 // the ROI boundaries

	// Actually set the ROI coordinates
	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			String errorMessage
			SIDXCameraROISet sidxCamera, iLeftNew, iTopNew, iRightNew, iBottomNew, sidxStatus
			if (sidxStatus!=0)
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraROISet: %s",errorMessage)
			endif
			SIDXCameraROIGetValue sidxCamera, iLeft, iTop, iRight, iBottom, sidxStatus
			if (sidxStatus!=0)
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraROIGetValue: %s",errorMessage)
			endif			
			if ( (iLeft!=iLeftNew) || (iTop!=iTopNew) || (iRight!=iRightNew) || (iBottom!=iBottomNew) )
				Abort "ROI settings on camera do not match requested ROI settings."				
			endif
		else
			Abort "Called CameraROISet() before camera was created."
		endif
	else
		iLeft=iLeftNew
		iTop=iTopNew
		iRight=iRightNew
		iBottom=iBottomNew
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
	NVAR binWidth
	NVAR binHeight

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
			CameraSyncBinWidthAndHeight()
		else
			Abort "Called CameraBinningItemSet() before camera was created."
		endif
	else
		iBinningModeFake=iBinningMode
		// This next is entirely Ander iXon Ultra-specific
		binWidth=2^iBinningMode
		binHeight=2^iBinningMode
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






Function CameraExposeSet(newValue)
	Variable newValue	// in seconds
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR exposureInSeconds		// in seconds

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraExposeSet sidxCamera, newValue, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraExposeSet: %s",errorMessage)
			endif
			CameraSyncExposure()
		else
			Abort "Called CameraExposeSet() before camera was created."
		endif
	else
		exposureInSeconds=newValue
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
			// debug code here
			// Get the current operating mode, and the list of possible modes
			String errorMessage
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
				Printf "Camera device-specific setting %d is %s : %s\r", settingIndex, settingLabel,stringFromSIDXSettingTypeCode(typeCode)
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
			
			Variable frameTransferSettingIndex=6
			Variable isFrameTransferOn
			SIDXDeviceExtraBooleanGet sidxCamera, frameTransferSettingIndex, isFrameTransferOn, sidxStatus
			Printf "isFrameTransferOn: %d\r", isFrameTransferOn
			
			Variable accumulationCountSettingIndex=0
			Variable accumulationCount
			SIDXDeviceExtraIntegerGet sidxCamera, accumulationCountSettingIndex, accumulationCount, sidxStatus
			Printf "accumulationCount: %d\r", accumulationCount

			// real code starts here
			SIDXCameraAcquireOpen sidxCamera, sidxAcquirer, sidxStatus
			if (sidxStatus!=0)
				isSidxAcquirerValid=0
				SIDXCameraGetLastError sidxCamera, errorMessage
				CameraSetErrorMessage(sprintf1s("Error in SIDXCameraAcquireOpen: %s",errorMessage))
				//Abort sprintf1s("Error in SIDXCameraAcquireOpen: %s",errorMessage)
				success=0
			else
				isSidxAcquirerValid=1
				success=1
			endif
		else
			CameraSetErrorMessage("Called CameraAcquireArm() before camera was created.")
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
	// This starts the acquisition.  It returns 1 if
	// this was successful, 0 otherwise.

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer
	NVAR isAcquisitionOngoingFake

	Variable success
	Variable sidxStatus
	if (areWeForReal)
		if (isSidxAcquirerValid)
			SIDXAcquireStart sidxAcquirer, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquirer, errorMessage
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
		isAcquisitionOngoingFake=1
		success=1
	endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	return success
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
				Abort sprintf1s("Error in SIDXAcquireGetStatus: %s",errorMessage)
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
	//WAVE bufferFrame
	NVAR widthCCD, heightCCD
	NVAR binWidth, binHeight
	NVAR iLeft, iTop
	NVAR iRight, iBottom	// the ROI boundaries
	NVAR nFramesBufferFake
	NVAR nFramesToAcquireFake
	//NVAR countReadFrameFake
	NVAR exposureInSeconds
	
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
		//Variable widthROIFake=iRight-iLeft+1
		//Variable heightROIFake=iBottom-iTop+1
		//Variable widthROIBinnedFake=round(widthROIFake/binWidth)
		//Variable heightROIBinnedFake=round(heightROIFake/binHeight)
		//Redimension /N=(widthROIBinnedFake,heightROIBinnedFake,nFramesBufferFake) bufferFrame	// sic, this is how Igor Pro organizes image data
		//SetScale /P x, iLeft+0.5*binWidth, binWidth, "px", bufferFrame		// Want the upper left corner of of the upper left pel to be at (0,0), not (-0.5,-0.5)
		//SetScale /P y, iTop+0.5*binHeight, binHeight, "px", bufferFrame
		Variable interExposureDelay=0.001		// s, could be shift time for FT camera, or readout time for non-FT camera
		Variable frameInterval=exposureInSeconds+interExposureDelay		// s, Add a millisecond of shift time, for fun
		Variable frameOffset=exposureInSeconds/2
		// Assumes the first exposure starts at t==0, so the middle of it occurs at exposureInSeconds/2.
		// After that, the middle of the next exposure comes frameInterval later, etc.
		//SetScale /P z, 1000*frameOffset, 1000*frameInterval, "ms", bufferFrame		// s -> ms
		//bufferFrame=2^15+(2^12)*gnoise(1)
		//countReadFrameFake=0
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
			Variable pulseDuration=1000*exposureInSeconds	// s->ms
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
	NVAR isSidxAcquirerValid
	NVAR sidxAcquirer
	NVAR isAcquisitionOngoingFake
	//WAVE bufferFrame
	NVAR iLeft, iTop
	NVAR iRight, iBottom
	NVAR binWidth, binHeight
	//NVAR countReadFrameFake
	NVAR exposureInSeconds

	Variable frameIntervalInSeconds	
	Variable sidxStatus
	String errorMessage
	if (areWeForReal)
		if (isSidxAcquirerValid)
			Make /O framesCagedTemp
			//WAVE ref=$"framesCagedTemp"
			// OK, done allocating frames
			SIDXAcquireRead sidxAcquirer, nFramesToRead, framesCagedTemp, sidxStatus	
				// doesn't seem to work if frames is a free wave, or a wave reference
			if (sidxStatus!=0)
				SIDXAcquireGetLastError sidxAcquirer, errorMessage
				Abort sprintf1s("Error in SIDXAcquireRead: %s",errorMessage)
			endif
			Duplicate /O framesCagedTemp, framesCaged
			// Get the frame interval while we're here
			SIDXAcquireGetImageInterval sidxAcquirer, frameIntervalInSeconds, sidxStatus
			if (sidxStatus!=0)
				SIDXAcquireGetLastError sidxAcquirer, errorMessage
				Abort sprintf1s("Error in SIDXAcquireGetImageInterval: %s",errorMessage)
			endif
			
		else
			Abort "Called CameraAcquireReadBang() before acquisition was armed."
		endif
	else
		if (isAcquisitionOngoingFake)
			Abort "Have to stop the fake acquisition before reading the fake data."
		endif
		Variable widthROIFake=iRight-iLeft+1
		Variable heightROIFake=iBottom-iTop+1
		Variable widthROIBinnedFake=round(widthROIFake/binWidth)
		Variable heightROIBinnedFake=round(heightROIFake/binHeight)
		Redimension /N=(widthROIBinnedFake,heightROIBinnedFake,nFramesToRead) framesCaged
		framesCaged=2^15+(2^12)*gnoise(1)	// fill with noise
		frameIntervalInSeconds=exposureInSeconds		// in a real acquire, the frame interval is always longer than the exposure, but whatevs
	endif

	//
	// Set x, y, t axis for the frames
	//
		
	// Set the x and y offset and scale
	Variable frameOffset=(1000*exposureInSeconds)/2	// ms, middle of the first exposure
	Variable frameInterval=1000*frameIntervalInSeconds	// ms
	SetScale /P x, iLeft+0.5*binWidth, binWidth, "px", framesCaged		// Want the upper left corner of of the upper left pel to be at (0,0), not (-0.5,-0.5)
	SetScale /P y, iTop+0.5*binHeight, binHeight, "px", framesCaged
	SetScale /P z, frameOffset, frameInterval, "ms", framesCaged	

	// Restore the data folder
	SetDataFolder savedDF		
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
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera
	NVAR binWidth
	Variable value=binWidth
	SetDataFolder savedDF		
	return value
End




Function CameraGetBinHeight()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera
	NVAR binHeight
	Variable value=binHeight
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





Function CameraProbeStatusAndPrintf(sidxCamera)
	// This is mainly for debugging
	Variable sidxCamera

	Variable sidxStatus
	String errorMessage

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

End





// private methods
Function CameraSyncBinWidthAndHeight()
	// Copy the bin dims according to the hardware into the instance var

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR binWidth
	NVAR binHeight

	if (areWeForReal)
		if (isSidxCameraValid)
			Variable sidxStatus
			SIDXCameraBinningGet sidxCamera, binWidth, binHeight, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraBinningGet: %s", errorMessage)
			endif
		else
			binWidth=nan
			binHeight=nan
		endif
	endif
	
	// Restore the data folder
	SetDataFolder savedDF	
End



Function CameraSyncExposure()
	// Copy the exposure according to the hardware into the instance var
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR exposureInSeconds		// in seconds

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraExposeGet sidxCamera, exposureInSeconds, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraExposeGet: %s",errorMessage)
			endif
		else
			exposureInSeconds=nan
		endif
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End





// utility functions
Function /S stringFromSIDXSettingTypeCode(settingTypeCode)
	Variable settingTypeCode
	String result=""
	if (settingTypeCode==0)
		result="boolean"
	elseif (settingTypeCode==1)
		result="integer"
	elseif (settingTypeCode==2)
		result="list"
	elseif (settingTypeCode==3)
		result="none"
	elseif (settingTypeCode==4)
		result="real"
	elseif (settingTypeCode==5)
		result="sequence"
	elseif (settingTypeCode==6)
		result="string"
	endif
	return result
End


Function /S getDeviceSettingValueAsString(sidxCamera, settingIndex)
	Variable sidxCamera
	Variable settingIndex

	Variable sidxStatus
	Variable errorMessage

	// Get the type of the setting
	Variable typeCode
	SIDXDeviceExtraGetType sidxCamera, settingIndex, typeCode, sidxStatus
	String settingType=stringFromSIDXSettingTypeCode(typeCode)
	
	// Use the proper function to get that kind of setting, convert to string
	Variable value
	String valueAsString=""
	if ( AreStringsEqual(settingType,"boolean") )
		SIDXDeviceExtraBooleanGet sidxCamera, settingIndex, value, sidxStatus
		valueAsString=stringFif(value,"true","false")
	elseif ( AreStringsEqual(settingType,"integer") )
		SIDXDeviceExtraIntegerGetValue sidxCamera, settingIndex, value, sidxStatus
		valueAsString=sprintf1v("%d",value)
	elseif ( AreStringsEqual(settingType,"list") )
		SIDXDeviceExtraListGet sidxCamera, settingIndex, value, sidxStatus	// value here is an index into the list
		SIDXDeviceExtraListGetLocal sidxCamera, settingIndex, value, valueAsString, sidxStatus
	elseif ( AreStringsEqual(settingType,"none") )
		valueAsString="none"
	elseif ( AreStringsEqual(settingType,"real") )
		SIDXDeviceExtraRealGetValue sidxCamera, settingIndex, value, sidxStatus
		valueAsString=sprintf1v("%f",value)
	elseif ( AreStringsEqual(settingType,"sequence") )
		Make /FREE valueWave
		SIDXDeviceExtraSequenceGet sidxCamera, settingIndex, valueWave, sidxStatus
		valueAsString=stringFromIntegerWave(valueWave)
	elseif ( AreStringsEqual(settingType,"string") )
		SIDXDeviceExtraStringGet sidxCamera, settingIndex, valueAsString, sidxStatus
	endif

	return valueAsString
End

