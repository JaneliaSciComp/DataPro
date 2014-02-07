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


//
// private methods
//

Function CameraSyncBinSize()
	// Copy the bin dims according to the hardware into the instance var

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR binSize

	if (areWeForReal)
		if (isSidxCameraValid)
			Variable sidxStatus
			Variable binWidth, binHeight
			SIDXCameraBinningGet sidxCamera, binWidth, binHeight, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraBinningGet: %s", errorMessage)
			endif
			if (binWidth!=binHeight)
				Abort "Internal Error: Bin width and height should always be the same."
			endif
			binSize=binWidth
		else
			binSize=nan
		endif
	endif
	
	// Restore the data folder
	SetDataFolder savedDF	
End



Function CameraSyncExposureWanted()
	// Copy the exposure according to the hardware into the instance var
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR exposureWantedInSeconds		// in seconds

	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraExposeGet sidxCamera, exposureWantedInSeconds, sidxStatus
				// This gets the value set, not the realized value
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraExposeGet: %s",errorMessage)
			endif
		else
			exposureWantedInSeconds=nan
		endif
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End




Function CameraSetROIInCSAndAligned(roiInCSAndAlignedNew)
	// Set the camera ROI
	// The ROI is specified in the unbinned pixel coordinates, which are image-style coordinates, 
	// with the upper-left pels being (0,0)
	// The ROI includes x coordinates [iLeft,iRight].  That is, the pixel with coord iRight is included.
	// The ROI includes y coordinates [iTop,iBottom].  That is, the pixel with coord iBottom is included.
	// iRight, iLeft must be an integer multiple of the current bin size
	// iBottom, iTop must be an integer multiple of the current bin size
	// The ROI will be (iRight-iLeft+1)/nBinSize bins wide, and
	// (iBottom-iTop+1)/nBinSize bins high.
	// Note that all of these are in CCD coords, not user coords.
	Wave roiInCSAndAlignedNew
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR iLeft, iTop
	NVAR iBottom, iRight	 // the ROI boundaries as pel indices

	// Convert the ROI boundaries to pixel row/column indices that are _inclusive_
	// The boundaries in roiInCSAndAligned we think of as infinetesimally thin boundaries, 
	// in image heckbertian coordinates.  The SIDX function wants pixel row/col coords, and 
	// the rows and columns given are _included_ in the ROI.  So we have to translate, but
	// the translation is pretty trivial
	Variable iLeftNew=roiInCSAndAlignedNew[0]
	Variable iTopNew=roiInCSAndAlignedNew[1]
	Variable iRightNew=roiInCSAndAlignedNew[2]-1
	Variable iBottomNew=roiInCSAndAlignedNew[3]-1

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





Function CameraBinSizeSet(nBinSizeNew)
	Variable nBinSizeNew
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR binSize

	// Translate the bin sizes into a binning mode
	// This code is entirely Andor iXon Ultra-specific
	Variable binningModeIndex
	if ( (nBinSizeNew==1) )
		binningModeIndex=0
	elseif ( (nBinSizeNew==2) )
		binningModeIndex=1
	elseif ( (nBinSizeNew==4) )
		binningModeIndex=2
	elseif ( (nBinSizeNew==8) )
		binningModeIndex=3
	else
		// Just use one if value is invalid
		binningModeIndex=0
	endif	

	// Set the bin sizes
	Variable sidxStatus
	if (areWeForReal)
		if (isSidxCameraValid)
			SIDXCameraBinningItemSet sidxCamera, binningModeIndex, sidxStatus
			if (sidxStatus!=0)
				String errorMessage
				SIDXCameraGetLastError sidxCamera, errorMessage
				Abort sprintf1s("Error in SIDXCameraBinningItemSet: %s",errorMessage)
			endif
			CameraSyncBinSize()
		else
			Abort "Called CameraBinningItemSet() before camera was created."
		endif
	else
		//iBinningModeFake=binningModeIndex
		// This next is entirely Ander iXon Ultra-specific
		binSize=2^binningModeIndex
	endif

	// Restore the data folder
	SetDataFolder savedDF	
End




Function /WAVE boundROITranslation(roiWave,dx,dy)
	Wave roiWave
	Variable dx,dy
	
	// Unpack the input ROI
	Variable xROILeft=roiWave[0]
	Variable yROITop=roiWave[1]
	Variable xROIRight=roiWave[2]
	Variable yROIBottom=roiWave[3]
	Variable width=xROIRight-xROILeft
	Variable height=yROIBottom-yROITop
	
	// Shift them the indicated amount
	Variable xROILeftNew=xROILeft+dx
	Variable yROITopNew=yROITop+dy
	Variable xROIRightNew=xROIRight+dx
	Variable yROIBottomNew=yROIBottom+dy
	
	// Initial guess at the translation to be returned
	Variable dxNew=dx
	Variable dyNew=dy
	
	// Limit the ROI to stay in bounds
	Variable nWidthCCD=CameraCCDWidthGetInUS()
	Variable nHeightCCD=CameraCCDHeightGetInUS()
	if (dx<0)
		// moved to the left
		if (xROILeftNew<0)
			xROILeftNew=0
			xROIRightNew=width
		endif
	else
		// moved to the right
		if (xROIRightNew>nWidthCCD)
			xROILeftNew=nWidthCCD-width
			xROIRightNew=nWidthCCD
		endif
	endif
	if (dy<0)
		// moved up
		if (yROITopNew<0)
			yROITopNew=0
			yROIBottomNew=height
		endif
	else
		// moved down
		if (yROIBottomNew>nHeightCCD)
			yROITopNew=nHeightCCD-height
			yROIBottomNew=nHeightCCD
		endif
	endif
	
	// package the result in a wave
	Make /FREE /N=4 roiWaveNew
	roiWaveNew[0]=xROILeftNew
	roiWaveNew[1]=yROITopNew
	roiWaveNew[2]=xROIRightNew
	roiWaveNew[3]=yROIBottomNew

	// return	
	return roiWaveNew
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



Function CameraIsSidxRootReallyValid(sidxRoot)
	// Called to check the validity of sidxRoot instance var, 
	// in situations where we suspect that isSidxRootValid might be
	// true even though sidxRoot is invalid.
	// Note that this does not read or write instance variables.  
	Variable sidxRoot
	
	// Try a sidx call that should succeed iff sidxRoot is valid
	Variable sidxStatus
	String serialNumber
	SIDXRootSoftwareGetSerial sidxRoot, serialNumber, sidxStatus
	Variable result=(sidxStatus==0)

	return result
End



Function CameraTryToGetSidxRootHandle()
	// Attempts to obtain a valid SIDX root handle.
	// If the SDIX root handle is already valid, behavior is unspecified.
	// Returns the handle, or -1 if failure.
	// Note that this doesn't change any instance variables, except the camera
	// error message on failure.
	
	// Create the SIDX root object, referenced by sidxRoot
	String errorMessage
	String license=""	// License file is stored in C:/Program Files/Bruxton/SIDX
	Variable sidxStatus
	Variable sidxRoot
	SIDXRootOpen sidxRoot, license, sidxStatus
	if (sidxStatus!=0)
		CameraSetErrorMessage("Unable to open SIDX root object")
		sidxRoot=-1
	endif
	
	return sidxRoot
End



Function CameraIsSidxCameraReallyValid(sidxCamera)
	// Check whether the sidxCamera handle is valid, in situations where we
	// no longer trust isSidxCameraValid
	Variable sidxCamera
	
	// Do stuff
	Variable sidxStatus
	Variable isTempAvailable
	try
		SIDXCameraTemperatureExists sidxCamera, isTempAvailable, sidxStatus; AbortOnRTE
	catch
		sidxStatus=-1	// indicates the camera is invalid
	endtry
	Variable result=(sidxStatus==0)

	return result
End



Function CameraTryToGetSidxCameraHandle(sidxRoot)
	// Attempts to obtain a valid SIDX camera handle.
	// Returns the camera handle or -1 on failure
	// Note that this doesn't change any instance vars except the Camera error msg on failure.
	Variable sidxRoot

	Variable sidxStatus
	String errorMessage
	Variable nCameras
	SIDXRootCameraScan sidxRoot, sidxStatus
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
	//Printf "# of cameras: %d\r", nCameras
	if (nCameras<=0)
		CameraSetErrorMessage("No cameras detected during scan")
		return -1
	endif		
	// Create the SIDX camera object, referenced by sidxCamera
	String sidxCameraName
	SIDXRootCameraScanGetName sidxRoot, 0, sidxCameraName, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		CameraSetErrorMessage(sprintf1s("Error in SIDXRootCameraScanGetName: %s",errorMessage))
		return -1
	endif
	//printf "sidxCameraName: %s\r", sidxCameraName
	Variable sidxCamera
	SIDXRootCameraOpenName sidxRoot, sidxCameraName, sidxCamera, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		CameraSetErrorMessage(sprintf1s("Error in SIDXRootCameraOpenName: %s",errorMessage))
		sidxCamera=-1
	endif
	
	return sidxCamera
End



Function CameraInitSidxCamera(sidxCamera)
	// Attempts to initialize the sidx Camera indicated by the handle
	// Returns 1 if successful, 0 otherwise.
	Variable sidxCamera

	// Set the EM gain to 100, the Solis default
	Variable sidxStatus
	String errorMessage
	Variable emGainSettingWant=100
	SIDXCameraEMGainSet sidxCamera, emGainSettingWant, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		CameraSetErrorMessage(sprintf1s("Error in SIDXCameraEMGainSet: %s",errorMessage))
		return 0
	endif		
	// Set the vertical shift speed to the Solis default
	Variable verticalShiftSpeedSettingIndex=15		
	Variable verticalShiftSpeedValueIndex=2		// Corresponds to "[0.9]" in Solis drop-down list, whatever that means
	SIDXDeviceExtraListSet sidxCamera, verticalShiftSpeedSettingIndex, verticalShiftSpeedValueIndex, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		CameraSetErrorMessage(sprintf1s("Error in SIDXDeviceExtraListSet: %s",errorMessage))
		return 0
	endif
	// Report on the camera state
	CameraProbeStatusAndPrintf(sidxCamera)

	return 1
End



Function CameraInitCCDDims()
	// sidxCamera has to be valid
	// returns success boolean
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR sidxCamera
	NVAR widthCCD
	NVAR heightCCD
	NVAR iLeft
	NVAR iTop
	NVAR iRight
	NVAR iBottom

	// Initialize the camera
	Variable sidxStatus
	String errorMessage	
	SIDXCameraROIGetValue sidxCamera, iLeft, iTop, iRight, iBottom, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		CameraSetErrorMessage(sprintf1s("Error in SIDXCameraROIGetValue: %s",errorMessage))
		SetDataFolder savedDF		
		return 0
	endif						
	Printf "ROI: %d %d %d %d\r", iLeft, iTop, iRight, iBottom
	widthCCD=iRight-iLeft+1
	heightCCD=iBottom-iTop+1
	SetDataFolder savedDF		
	return 1
End


Function CameraValidifySidxHandles()
	// Check the sidx handles and get valid ones if they are marked as valid but aren't.
	// Return 1 if we can restore the handles that are supposed to be valid.
	// Return 0 if at least one of the handles is supposed to be valid and we couldn't restore it.

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR areWeForReal
	NVAR isSidxRootValid
	NVAR sidxRoot
	NVAR isSidxCameraValid
	NVAR sidxCamera
	NVAR isSidxAcquireValid

	// If we're faking the camera, this is easy
	if (!areWeForReal)
		SetDataFolder savedDF	
		return 1
	endif

	// Check the SIDX handles, and if they're not valid, restore them
	Variable restoredSidxRoot=0
	if (isSidxRootValid)
		// Object claims that sidxRoot is valid, but let's check
		Variable isSidxRootReallyValid=CameraIsSidxRootReallyValid(sidxRoot)
		if (isSidxRootReallyValid)
			if (isSidxCameraValid)
				// If we get here, we're in kind of a quandry.
				// sidxRoot really did turn out to be valid. 
				// But we don't really have a good way to test the validity of the sidxCamera
				// We'll just assume that sidxCamera is OK too...
			else
				// nothing more to do
			endif
		else
			// As we suspected, sidxRoot is not really valid.  So we try to obtain a valid sidxRoot
			sidxRoot=CameraTryToGetSidxRootHandle()
			if (sidxRoot>=0)
				// Yay!  We succeeded in getting a valid sidx root handle
				// If we get to this point, isSidxRootValid was true on call, sidxRoot is now valid, and isSidxRootValid is now true
				// We proceed to check the sidx camera handle
				if (isSidxCameraValid)
					// Object claims that sidxCamera is valid, but let's check
					// In this case, the old sdixCamera can't possibly be valid, so we try to obtain a new, valid sidxCamera
					sidxCamera=CameraTryToGetSidxCameraHandle(sidxRoot)
					if (sidxCamera>=0)
						// Yay!  We succeeded in getting a valid sidx root handle
					else
						// Hrm.  We were unable to get a valid sidx camera handle.
						// Hopefully CameraTryToGetSidxCameraHandle() set the camera error message
						isSidxCameraValid=0				
						isSidxAcquireValid=0				
						SetDataFolder savedDF	
						return 0
					endif
					// If we get to this point, isSidxRootValid was true on call, sidxRoot is now valid, and isSidxRootValid is now true
					// If we get to this point, isSidxCameraValid was true on call, sidxCamera is now valid, and isSidxCameraValid is now true
					// We proceed to initialize the camera
					Variable isCameraInited=CameraInitSidxCamera(sidxCamera)
					if (isCameraInited)
						// Camera was sucessfully initialized.
						isSidxCameraValid=1
						// Go ahead and clear isSidxAcquireValid.  Doesn't matter what it was before.
						isSidxAcquireValid=0
						// If we get here, all is good
					else
						// Failure, exit with error
						isSidxCameraValid=0
						isSidxAcquireValid=0
						SetDataFolder savedDF	
						return 0				
					endif
				else
					// Object makes no claim that sidxCamera is valid, so nothing more to do
					// In this case, it should always be the case that
					// isSidxAcquireValid==0
				endif				
			else
				// Hrm.  We were unable to get a valid sidx root handle.
				// Hopefully CameraTryToGetSidxRootHandle() set the camera error message
				isSidxRootValid=0
				isSidxCameraValid=0
				isSidxAcquireValid=0				
				SetDataFolder savedDF	
				return 0
			endif
		endif
	else
		// Object makes no claim that sidxRoot is valid, so nothing to do
		// In this case, it should always be the case that
		// isSidxCameraValid==isSidxAcquireValid==0
	endif

	// Restore the data folder
	SetDataFolder savedDF	
	
	return 1
End



