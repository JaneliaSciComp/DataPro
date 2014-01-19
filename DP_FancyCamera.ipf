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
		Variable /G userFromCameraReflectX=0	// boolean
		Variable /G userFromCameraReflectY=0	// boolean
		Variable /G userFromCameraSwapXandY=0	// boolean
		// To go from camera to user, we reflect X (or not), reflect Y (or not), and then swap X and Y (or not)
		// In that order---(possible) reflections then (possible) swap
		// This covers all 8 possible transforms, including rotations and anything else
	else
		// If it exists, switch to it
		SetDataFolder root:DP_FancyCamera
	endif

	// instance vars
	NVAR userFromCameraReflectX
	NVAR userFromCameraReflectY
	NVAR userFromCameraSwapXandY
	
	// Initialize the camera
	CameraConstructor()
	
	// Tell the camera the userFromCameraMatrix, so it can properly transform the images
	// when we read them
	userFromCameraReflectX=0	// boolean
	userFromCameraReflectY=1	// boolean
	userFromCameraSwapXandY=1	// boolean
	CameraSetTransform(userFromCameraSwapXandY,userFromCameraReflectX,userFromCameraReflectY)
	
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
	NVAR userFromCameraReflectX	// boolean
	NVAR userFromCameraReflectY	// boolean
	NVAR userFromCameraSwapXandY	// boolean

	// Get the CCD size in the camera sapce
 	Variable ccdWidthInCS=CameraCCDWidthGet()
 	Variable ccdHeightInCS=CameraCCDHeightGet()
 	Make /FREE /N=(2,2) farCornerReppedInCS={ {ccdWidthInCS,ccdHeightInCS}, {ccdWidthInCS,ccdHeightInCS} }

	// Make a 2x2 matrix of the ROI corners in user space, with each corner a column
	// In Igor,  { { a ,b } , { c , d } } means that a and b are in the first _column_
	Make /FREE /N=(2,2) roiCornersInUS={ {roiInUS[0], roiInUS[1]} , {roiInUS[2], roiInUS[3]} }
	
	// Make the transformation matrices
	Variable p=userFromCameraSwapXandY
	Variable bx=userFromCameraReflectX
	Variable by=userFromCameraReflectY
	Variable sx=1-2*bx
	Variable sy=1-2*by
	Make /FREE /N=(2,2) Pwap={ { 1-p, p }, {p, 1-p} }		// Does the x-y swap, if called for
	Make /FREE /N=(2,2) ScaleMatrix={ { sx, 0 }, {0, sy} }	// Scales x, y to do the appropriate reflections
	Make /FREE /N=(2,2) B={ { bx, 0 }, {0, by} }		// Gates x, y depending on who is being reflected
	
	// Transform the ROI corners
	MatrixOp /FREE roiCornersInCS = ScaleMatrix x (Pwap x roiCornersInUS - B x farCornerReppedInCS)
	
	Make /FREE /N=(2) xCornersInCS
	xCornersInCS=roiCornersInCS[0][p]
	Make /FREE /N=(2) yCornersInCS
	yCornersInCS=roiCornersInCS[1][p]
	Variable xMinInCS=WaveMin(xCornersInCS)
	Variable yMinInCS=WaveMin(yCornersInCS)
	Variable xMaxInCS=WaveMax(xCornersInCS)
	Variable yMaxInCS=WaveMax(yCornersInCS)
		
	// Package as a ROI
	Make /FREE /N=(4) roiInCS={xMinInCS, yMinInCS, xMaxInCS, yMaxInCS}
	
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
	Variable iRight=ceil(roiInCS[2]/nBinWidth)*nBinWidth-1
	Variable iBottom=ceil(roiInCS[3]/nBinHeight)*nBinHeight-1
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
