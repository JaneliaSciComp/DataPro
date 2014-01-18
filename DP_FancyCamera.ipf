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
		//Variable userFromCameraReflectX=0	// boolean
		//Variable userFromCameraReflectY=0	// boolean
		//Variable userFromCameraSwapXandY=0	// boolean
		// To go from camera to user, we reflect X (or not), reflect Y (or not), and then swap X and Y (or not)
		// This covers all 8 possible transforms, including rotations and anything else
		
		Make /O /N=(2,2) userFromCameraMatrix={{1,0},{0,1}}
	else
		// If it exists, switch to it
		SetDataFolder root:DP_FancyCamera
	endif

	// Initialize the camera
	CameraConstructor()
	
	// Tell the camera the userFromCameraMatrix, so it can properly transform the images
	// when we read them
	//Variable userFromCameraReflectX=0	// boolean
	//Variable userFromCameraReflectY=0	// boolean
	//Variable userFromCameraSwapXandY=0	// boolean
	userFromCameraMatrix={{0,-1},{-1,0}}	// CCW 90 deg rotation+mirroring in X, specific to Yitzhak's rig
	CameraSetUserFromCameraMatrix(userFromCameraMatrix)
	
	// Restore the data folder
	SetDataFolder savedDF	
End




Function FancyCameraSetupSnapshotAcq(exposure,targetTemperature)
	// This sets up the camera for a single snapshot acquisition.
	// This is typically called once per acquisition, just before the acquisition.
	Variable exposure	// frame exposure duration, in ms
	Variable targetTemperature
	
	// Set the binning and ROI
	Variable nBinWidth=1
	Variable nBinHeight=1
	Variable isTriggered=0
	FancyCameraBinningSet(nBinWidth, nBinHeight)
	FancyCameraROIClear()	// we don't use the rois for snapshots

	// Set the trigger mode
	Variable ALWAYS=0	// start immediately
	CameraTriggerModeSet(ALWAYS)
	
	// Set the exposure
	Variable exposureInSeconds=exposure/1000		// ms->s
	CameraExposeSet(exposureInSeconds)
	
	// Set the CCD temp, wait for it to stabilize
	//FancyCameraSetTempAndWait(targetTemperature)
End




Function FancyCameraSetupVideoAcq(nBinWidth,nBinHeight,roisWave,isTriggered,exposure,targetTemperature)
	// This sets up the camera for a single video acquisition.
	Variable nBinWidth
	Variable nBinHeight
	Wave roisWave
	Variable isTriggered
	Variable exposure	// frame exposure duration, in ms
	Variable targetTemperature
	
	// Set the binning and ROI
	FancyCameraBinningSet(nBinWidth, nBinHeight)
	//Variable nROIs=DimSize(roisWave,1)
	//Variable isAtLeastOneROI=(nROIs>0)
	//if (isAtLeastOneROI)
	//	Wave cameraROI=FancyCameraROIFromROIs(roisWave,nBinWidth,nBinHeight)
	//else
	//	Make /FREE cameraROI={nan,nan,nan,nan}
	//endif
	FancyCameraROISet(roisWave,nBinWidth,nBinHeight)
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






Function FancyCameraBinningSet(nBinWidth, nBinHeight)
	Variable nBinWidth, nBinHeight	
	// These are in user coordinate space, although currently it doesn't really matter
	
	// Translate the bin sizes into a binning mode
	// This code is entirely Andor iXon Ultra-specific
	Variable binningModeIndex
	if ( (nBinWidth==1) && (nBinHeight==1) )
		binningModeIndex=0
	elseif ( (nBinWidth==2) && (nBinHeight==2) )
		binningModeIndex=1
	elseif ( (nBinWidth==4) && (nBinHeight==4) )
		binningModeIndex=2
	elseif ( (nBinWidth==8) && (nBinHeight==8) )
		binningModeIndex=3
	else
		return 0
	endif	
	
	// Set the binning
	CameraBinningItemSet(binningModeIndex)	
End








Function FancyCameraROISet(roisWave,nBinWidth,nBinHeight)
	// Set the ROI for the camera, given the user ROIs.  Note that the input coords are in user coordinate space, so
	// we have to translate them to CCD coordinate space.
	Wave roisWave
	Variable nBinWidth,nBinHeight

	// Clear the ROI	
	CameraROIClear()
	
	Variable nROIs=DimSize(roisWave,1)
	if (nROIs>0)
		// Calc the ROI that just includes all the ROIs, in same (user image heckbertian) coords as the ROIs themselves
		Wave boundingROIInUS=FancyCameraBoundingROIFromROIs(roisWave)
		Wave boundingROIInCS=FancyCameraCameraROIFromUserROI(roisWave)
		Wave alignedROIInCS=FancyCameraAlignCameraROIToGrid(boundingROIInCS,nBinWidth,nBinHeight)
		CameraROISet(alignedROIInCS[0], alignedROIInCS[1], alignedROIInCS[2], alignedROIInCS[3])
	endif

	// Restore the original DF
	SetDataFolder savedDF
End








Function FancyCameraROIClear()
	// Clear the ROI, i.e. set the camera to use the full CCD
	CameraROIClear()
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





Function /WAVE FancyCameraBoundingROIFromROIs(roisWave)
	// Computes the axis-aligned ROI that just includes all of the ROIs in roisWave.
	// This doesn't do any aligning to the bin grid or translate the image-heckbertian userspace ROI coords
	// into CCD-space row/col indices.  That can be done elsewhere if needed.
	// It is an error to call this function if there are zero rois in roisWave.
	Wave roisWave
	
	Variable nROIs=DimSize(roisWave,1)
	Make /FREE /N=(4) boundingROI
	if (nROIs==0)
		Abort "Error: No ROIs in roisWave in  FancyCameraBoundingROIFromROIs()."
	else
		// Compute the bounding ROI, in user coordinates
		Make /FREE /N=(nROIs) temp
		temp=roisWave[0][p]
		Variable xLeft=WaveMin(temp)
		temp=roisWave[1][p]
		Variable yTop=WaveMin(temp)
		temp=roisWave[2][p]
		Variable xRight=WaveMax(temp)
		temp=roisWave[3][p]
		Variable yBottom=WaveMax(temp)
		boundingROI={xLeft,yTop,xRight,yBottom}		
	endif
	return boundingROI	
End





Function /WAVE FancyCameraCameraROIFromUserROI(roiInUS)
	// Translates a userspace image heckbertian ROI into a cameraspace
	// image heckbertian ROI.
	// InUS == in userspace
	// InCS == in cameraspace
	Wave roiInUS
	
	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FancyCamera

	// instance vars
	WAVE userFromCameraMatrix
	
	Variable ccdWidthInUS, ccdHeightInUS
	if (userFromCameraMatrix[0][0]==0)
		// This means that x stays x, and y stays y, in going between camera and user spaces
	 	ccdWidthInUS=CameraCCDWidthGet()
	 	ccdHeightInUS=CameraCCDHeightGet()
	else
		// This means that x and y swap, in going between camera and user spaces
	 	ccdWidthInUS=CameraCCDHeightGet()
	 	ccdHeightInUS=CameraCCDWidthGet()
	endif
	
	// Since the corners can move in terms of left/right, upper/lower, we label them in like so (in userspace):
	//        1 *             * 2
	//
	//        3 *             * 4

	Make /FREE /N=(2) ccdCorner1InUS={0,0}
	Make /FREE /N=(2) ccdCorner2InUS={ccdWidthInUS,0}
	Make /FREE /N=(2) ccdCorner3InUS={0,ccdHeightInUS}
	Make /FREE /N=(2) ccdCorner4InUS={ccdWidthInUS,ccdHeightInUS}

	Make /FREE /N=(2) roiCorner1InUS={roiInUS[0], roiInUS[1]}
	Make /FREE /N=(2) roiCorner2InUS={roiInUS[2], roiInUS[1]}
	Make /FREE /N=(2) roiCorner3InUS={roiInUS[0], roiInUS[3]}
	Make /FREE /N=(2) roiCorner4InUS={roiInUS[2], roiInUS[3]}
		
	MatrixOp /FREE cameraFromUserMatrix=userFromCameraMatrix^t		// Transpose to invert, b/c orthogonal
	
	// Since the corners can move in terms of left/right, upper/lower, we label them in like so (in userspace):
	//        1 *             * 2
	//
	//        3 *             * 4
	
	MatrixOp /FREE roiCorner1InCSAlmost=cameraFromUserMatrix x roiCorner1InUS
	MatrixOp /FREE roiCorner2InCSAlmost=cameraFromUserMatrix x roiCorner2InUS
	MatrixOp /FREE roiCorner3InCSAlmost=cameraFromUserMatrix x roiCorner3InUS
	MatrixOp /FREE roiCorner4InCSAlmost=cameraFromUserMatrix x roiCorner4InUS
	
	// We've just done a linear transformation of the ROI corners, but we still need to do a translation.
	// That's because if the ROI was the whole CCD (in userspace), we would now have a ROI where the corner at
	// the origin wouldn't have moved, but some or all of the other corners could have negative coordinate values.
	// So we need to translate everything to bring the upper-right corner of the CCD (in cameraspace) to the origin
	
	Variable xMinInCSAlmost=min(roiCorner1InCSAlmost[0],roiCorner4InCSAlmost[0])
	Variable yMinInCSAlmost=min(roiCorner1InCSAlmost[1],roiCorner4InCSAlmost[1])
	Variable xMaxInCSAlmost=max(roiCorner1InCSAlmost[0],roiCorner4InCSAlmost[0])
	Variable yMaxInCSAlmost=max(roiCorner1InCSAlmost[1],roiCorner4InCSAlmost[1])
	
	Make /FREE /N=2 roiUpperLeftCornerInCSAlmost={xMinInCSAlmost,yMinInCSAlmost}
	Make /FREE /N=2 roiLowerRightCornerInCSAlmost={xMaxInCSAlmost,yMaxInCSAlmost}

	//MatrixOp ccdCorner1InCSAlmost=cameraFromUserMatrix x ccdCorner1InUS
	//MatrixOp ccdCorner2InCSAlmost=cameraFromUserMatrix x ccdCorner2InUS
	//MatrixOp ccdCorner3InCSAlmost=cameraFromUserMatrix x ccdCorner3InUS
	//MatrixOp ccdCorner4InCSAlmost=cameraFromUserMatrix x ccdCorner4InUS
		
	Make /FREE /N=(2) pivotalCCDCornerInUS		// The coordinates of the corner that ends up being in the upper left in CS, but in US coords
	if ( abs(roiCorner1InCSAlmost[0]-xMinInCSAlmost)<0.01 && abs(roiCorner1InCSAlmost[1]-yMinInCSAlmost)<0.01 )
		// Corner one is now in upper left --- That means the cameraspace projection of (0,0) in userspace should
		// be shifted to the origin
		pivotalCCDCornerInUS=ccdCorner1InUS
	elseif ( abs(roiCorner2InCSAlmost[0]-xMinInCSAlmost)<0.01 && abs(roiCorner2InCSAlmost[1]-yMinInCSAlmost)<0.01 )
		pivotalCCDCornerInUS=ccdCorner2InUS
	elseif ( abs(roiCorner3InCSAlmost[0]-xMinInCSAlmost)<0.01 && abs(roiCorner3InCSAlmost[1]-yMinInCSAlmost)<0.01 )
		pivotalCCDCornerInUS=ccdCorner3InUS
	elseif ( abs(roiCorner4InCSAlmost[0]-xMinInCSAlmost)<0.01 && abs(roiCorner4InCSAlmost[1]-yMinInCSAlmost)<0.01 )
		pivotalCCDCornerInUS=ccdCorner4InUS
	else
		Abort "Internal error."
	endif
	
	// Translate to get into camera coords
	MatrixOp offset=cameraFromUserMatrix x pivotalCCDCornerInUS
	Make /FREE /N=2 roiUpperLeftCornerInCS= roiUpperLeftCornerInCSAlmost-offset
	Make /FREE /N=2  roiLowerRightCornerInCS=roiLowerRightCornerInCSAlmost-offset

	// Package as a ROI
	Make /FREE /N=(4) roiInCS={roiUpperLeftCornerInCS[0], roiUpperLeftCornerInCS[1], roiLowerRightCornerInCS[0], roiLowerRightCornerInCS[1]}
	
	// Restore the data folder
	SetDataFolder savedDF		

	return roiInCS
End






Function /WAVE FancyCameraAlignCameraROIToGrid(roiInCS,nBinWidth,nBinHeight)
	// Computes the camera given all the individual ROIs.  Roughly, the camera ROI is a single
	// ROI that just includes all the individual ROIs.  But things are slightly more complicated b/c the 
	// user ROIs are specified in "image Heckbertian" coordinates, and the camera ROI is specified in 
	// "image pixel" coordinates.  That is, for the user ROIs, the upper left corner of the upper left pixel 
	// is (0,0), and the lower right corner of the lower right pixel is (n_cols, n_rows).  Further, we consider
	// the user ROI bounds to be infinitesimally thin.  The camera ROI is simply the index of the first/last 
	// column/row to be included in the ROI, with the indices being zero-based.	
	Wave roiInCS
	Variable nBinWidth, nBinHeight
	
	// Now we have a bounding box, but need to align to the binning
	Variable iLeft=floor(roiInCS[0]/nBinWidth)*nBinWidth
	Variable iTop=floor(roiInCS[1]/nBinHeight)*nBinHeight
	Variable iRight=ceil(roiInCS[3]/nBinWidth)*nBinWidth-1
	Variable iBottom=ceil(roiInCS[4]/nBinHeight)*nBinHeight-1
	Make /FREE /N=4 roiInCSAligned={iLeft,iTop,iRight,iBottom}		
	return roiInCSAligned
End



//Function /WAVE FancyCameraROIFromROIs(roisWave,nBinWidth,nBinHeight)
//	// Computes the camera given all the individual ROIs.  Roughly, the camera ROI is a single
//	// ROI that just includes all the individual ROIs.  But things are slightly more complicated b/c the 
//	// user ROIs are specified in "image Heckbertian" coordinates, and the camera ROI is specified in 
//	// "image pixel" coordinates.  That is, for the user ROIs, the upper left corner of the upper left pixel 
//	// is (0,0), and the lower right corner of the lower right pixel is (n_cols, n_rows).  Further, we consider
//	// the user ROI bounds to be infinitesimally thin.  The camera ROI is simply the index of the first/last 
//	// column/row to be included in the ROI, with the indices being zero-based.	
//	Wave roisWave
//	Variable nBinWidth, nBinHeight
//	
//	Variable nROIs=DimSize(roisWave,1)
//	Make /FREE /N=(4) cameraROI
//	if (nROIs==0)
//		cameraROI={0,0,CameraCCDWidthGet()-1,CameraCCDHeightGet()-1}
//	else
//		// Compute the bounding ROI, in user coordinates
//		Make /FREE /N=(nROIs) temp
//		temp=roisWave[0][p]
//		Variable xLeft=WaveMin(temp)
//		temp=roisWave[1][p]
//		Variable yTop=WaveMin(temp)
//		temp=roisWave[2][p]
//		Variable xRight=WaveMax(temp)
//		temp=roisWave[3][p]
//		Variable yBottom=WaveMax(temp)
//		// Now we have a bounding box, but need to align to the binning
//		Variable iLeft=floor(xLeft/nBinWidth)*nBinWidth
//		Variable iTop=floor(yTop/nBinHeight)*nBinHeight
//		Variable iRight=ceil(xRight/nBinWidth)*nBinWidth-1
//		Variable iBottom=ceil(yBottom/nBinHeight)*nBinHeight-1
//		cameraROI={iLeft,iTop,iRight,iBottom}		
//	endif
//	return cameraROI	
//End




Function /WAVE FancyCameraAlignROIToBins(roiWave)
	Wave roiWave
	
	Variable nBinWidth=CameraGetBinWidth()
	Variable nBinHeight=CameraGetBinHeight()
	Variable iLeft=floor(roiWave[0]/nBinWidth)*nBinWidth
	Variable iTop=floor(roiWave[1]/nBinHeight)*nBinHeight
	Variable iRight=ceil(roiWave[2]/nBinWidth)*nBinWidth
	Variable iBottom=ceil(roiWave[3]/nBinHeight)*nBinHeight		
	Make /FREE /N=(4) alignedROI
	alignedROI={iLeft,iTop,iRight,iBottom}		
	return alignedROI	
End





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
