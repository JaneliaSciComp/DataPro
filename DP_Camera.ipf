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

		// This stuff is only needed/used if there's no camera and we're faking
		Variable /G widthCCDFake=512	// width of the fake CCD
		Variable /G heightCCDFake=512	// height of the fake CCD
		Variable /G modeTriggerFake=0		// the trigger mode of the fake camera. 0=>free-running, 1=> each frame is triggered, and there are other settings
		Variable /G widthBinFake=1
		Variable /G heightBinFake=1
		Variable /G iLeftROIFake=0
		Variable /G iTopROIFake=0
		Variable /G iBottomROIFake=heightCCDFake
		Variable /G iRightROIFake=widthCCDFake
		Variable /G exposureFake=0.1	// exposure for the fake camera, in sec
		Variable /G temperatureTargetFake=-20		// degC
		Variable /G countFrameFake=1		// How many frames to acquire for the fake camera
		Variable /G isAcquireOpenFake=0		// Whether acquisition is "armed"
		Variable /G isAcquisitionOngoingFake=0
		Variable /G countReadFrameFake=0		// the first frame to be read by subsequent read commands

		// Create the SIDX root object, referenced by sidxRoot
		String license=""	// License file is stored in C:/Program Files/Bruxton/SIDX
		Variable sidxStatus
		SIDXRootOpen sidxRoot, license, sidxStatus
		isSidxRootValid=(sidxStatus==0)
		//printf "isSidxRootValid: %d\r" isSidxRootValid
		Variable nCameras
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
				printf "isSidxCameraValid: %d\r", isSidxCameraValid
				areWeForReal=isSidxCameraValid		// if no valid camera, then we fake
			else
				// if zero cameras, then we fake
				areWeForReal=0;
			endif
		endif
		//printf "areWeForReal: %d\r", areWeForReal
//		if (!areWeForReal)
//			Redimension /N=(widthCCDFake,heightCCDFake,countFrameFake) bufferFrame		// sic: this is how Igor Pro organizes image data 
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
	NVAR widthCCDFake, heightCCDFake

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
		iRightROIFake=widthCCDFake
		iBottomROIFake=heightCCDFake
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

	// Check that the ROI dimensions are legal
	Variable nBinWidth=CameraGetBinWidth()
	if ( !IsInteger(iLeft/nBinWidth) )
		SetDataFolder savedDF	
		return 0
	endif
	if ( !IsInteger(iRight/nBinWidth) )
		SetDataFolder savedDF	
		return 0
	endif
	Variable nBinHeight=CameraGetBinHeight()
	if ( !IsInteger(iTop/nBinHeight) )
		SetDataFolder savedDF	
		return 0
	endif
	if ( !IsInteger(iBottom/nBinHeight) )
		SetDataFolder savedDF	
		return 0
	endif

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





Function CameraBinningSet(nBinWidth,nBinHeight)
	Variable nBinWidth, nBinHeight
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR widthBinFake, heightBinFake

	// Check that the bin size is an integer fraction of the CCD size
	// If not, return
	Variable nBinsWide=CameraCCDWidthGet()/nBinWidth
	if ( !IsInteger(nBinsWide) )
		SetDataFolder savedDF	
		return 0
	endif
	Variable nBinsHigh=CameraCCDHeightGet()/nBinHeight
	if ( !IsInteger(nBinsHigh) )
		SetDataFolder savedDF	
		return 0
	endif
	
	// Set the bin sizes
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
		widthBinFake=nBinWidth
		heightBinFake=nBinHeight
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







Function CameraBufferCountSet(nFrames)
	Variable nFrames
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR  countFrameFake

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
		 countFrameFake=nFrames
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraAcquireArm()
	// This basically "arms" the camera for acquisition
	
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

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraAcquireOpen sidxCamera, sidxAcquirer, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraAcquireOpen: %s",errorMessage)
			else
				isSidxAcquirerValid=0
			endif
		else
			Abort "Called CameraAcquireArm() before camera was created."
		endif
	else
		isAcquireOpenFake=1
	endif

	// Restore the data folder
	SetDataFolder savedDF	
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
	NVAR widthCCDFake, heightCCDFake
	NVAR widthBinFake, heightBinFake
	NVAR iLeftROIFake, iTopROIFake
	NVAR iRightROIFake, iBottomROIFake	// the ROI boundaries
	NVAR countFrameFake
	NVAR countReadFrameFake

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
		Redimension /N=(widthROIBinnedFake,heightROIBinnedFake,countFrameFake) bufferFrame	// sic, this is how Igor Pro organizes image data
		SetScale /P x, iLeftROIFake+0.5*widthBinFake, widthBinFake, bufferFrame		// Want the upper left corner of of the upper left pel to be at (0,0), not (-0.5,-0.5)
		SetScale /P y, iTopROIFake+0.5*heightBinFake, heightBinFake, bufferFrame
		SetScale /P z, 0.5, 1, bufferFrame		// Should probably incorporate timing info at some point
		bufferFrame=2^15+(2^12)*gnoise(1)
		countReadFrameFake=0
		//bufferFrame=p
		
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
			SIDXAcquireRead sidxAcquirer, nFramesToRead, frames, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXAcquireGetLastError sidxAcquirer, errorMessage
				Abort sprintf1s("Error in SIDXAcquireRead: %s",errorMessage)
			endif
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
				Abort sprintf1s("Error in SIDXCameraCoolingGetValue: %s",errorMessage)
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
	NVAR areWeForReal
	NVAR widthCCDFake
	NVAR sidxCamera

	if (areWeForReal)
		value=nan	// need to fill this in
	else
		value=widthCCDFake
	endif
	
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
	NVAR areWeForReal
	NVAR heightCCDFake

	if (areWeForReal)
		value=nan	// need to fill this in
	else
		value=heightCCDFake
	endif
	
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

	if (areWeForReal)
		value=nan	// need to fill this in
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

	if (areWeForReal)
		value=nan	// need to fill this in
	else
		value=heightBinFake
	endif
	
	// Restore the data folder
	SetDataFolder savedDF	
	
	return value
End




Function CameraIsValidBinWidth(nBinWidth)
	Variable nBinWidth
	
	Variable result
	Variable ccdWidth=CameraCCDWidthGet()
	if (1<=nBinWidth) && (nBinWidth<=ccdWidth) 
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
	if (1<=nBinHeight) && (nBinHeight<=ccdHeight) 
		Variable nBins=ccdHeight/nBinHeight
		result=IsInteger(nBins)
	else
		result=0
	endif
	return result
End

