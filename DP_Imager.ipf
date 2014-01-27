//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function ImagerConstructor()
	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_Imager"))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)

	// Make a new DF, switch to it
	NewDataFolder /O/S root:DP_Imager

	// Instance variables
	//String /G allVideoWaveNames		// a semicolon-separated list of all the video wave names
	//Variable /G wheelPositionForEpiLightOn=1	// Setting of something that results in epi-illumination being on
	//Variable /G wheelPositionForEpiLightOff=0	// Setting of something that results in epi-illumination being off
	Variable /G isTriggered		// boolean, true iff the video acquisition will be triggered (as opposed to free-running)
	Variable /G isFocusing=0		// boolean, whether or not we're currently focusing
	Variable /G isAcquiringVideo=0		// boolean, whether or not we're currently taking video
	//Variable /G image_focus	// image_focus may be unnecessary if there is a separate focus routine
	//Variable /G isROI=0		// is there a ROI? (false=>full frame)
	//Variable /G isBackgroundROIToo=0		// if isROI, is there a background ROI too? (if full-frame, this is unused)
	Variable /G ccdTargetTemperature= -40		// the setpoint CCD temperature
	Variable /G ccdTemperature=nan			// the CCD temperature as of last check
	Variable /G nFramesForVideo=4	// number of frames to acquire
	//Variable /G focusingExposure=100		// duration of each exposure when focusing, in ms
	Variable /G snapshotExposure=50		// duration of each frame exposure for full-frame images, in ms
	String /G videoExposureWanted="50"		// desired exposure duration for video, as a string, in ms
	Variable /G videoExposure=nan	// duration of each frame for triggered video, in ms
	Variable /G frameRate=nan	// Video frame rate, in Hz, based on exposure, binning, ROIs (if any)
	//Variable /G iFrame		// Frame index to show in the browser
	String /G snapshotWaveBaseName="snap"		// the base name of the full-frame image waves, including the underscore
	//String /G focusWaveBaseName="full_"		// the base name of the focusing image waves, including the underscore
	String /G videoWaveBaseName="video"	// the base name of the triggered video waves, including the underscore
	//Variable /G iFullFrameWave=1	// The "sweep number" to use for the next full-frame image
	//Variable /G iFocusWave=1		// The "sweep number" to use for the next focus image
	//Variable /G iVideoWave=1		// The "sweep number" to use for the video 
	Make /O /U binSizeList={1,2,4,8}		// CCD bin size, an unsigned int
	Variable /G binSizeIndex=0
	Variable /G iROI=nan		// indicates the current ROI
	//Variable /G binnedFrameWidth=(iROIRight-iROILeft+1)/binSize	// Width of the binned ROI image
	//Variable /G binnedFrameHeight=(iROIBottom-iROITop+1)/binSize		// Height of the binned ROI image
	//Variable /G blackCount=0		// the CCD count that gets mapped to black
	//Variable /G whiteCount=2^16-1	// the CCD count that gets mapped to white
	Variable /G moveAllROIs=0		// Whether to move all the ROIs when ImagerTranslateCurrentROIOrAll() is called
	
	// the list of possible calculations
	Make /O /T calculationList={"Mean","Sum","DF/F"}
	Variable /G calculationIndex=0		// default is mean
	
	Variable nROIs=0
	Make /O /N=(4,nROIs) roisWave		// a 2D wave holding a ROI specification in each column, order is : left, top, right, bottom
	Make /O /I /U /N=(nROIs) isBackgroundROI		// a 1D boolean wave indicating whether each ROI is a background ROI.  This should have at most one true element.
	
	// make average wave for imaging
	Variable /G nFramesInAverage=0		// number of frames to average, I think for calculating dF/F
	Make /O /N=(nFramesInAverage) dff_avg
	
	// Set the target CCD temp
	FancyCameraSetTemp(ccdTargetTemperature)
	
	// Update the frame rate
	ImagerUpdateFrameRateEtc()
	
	// Restore the original data folder
	SetDataFolder savedDF	
End

Function /S ImagerGetCalculationList()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE /T calculationList
	
	Variable nCalculations=numpnts(calculationList)
	String result=""
	Variable i
	for (i=0; i<nCalculations; i+=1)
		result+=(calculationList[i]+";")
	endfor
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return result
End

Function ImagerGetCalculationIndex()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR calculationIndex
	
	// get the value
	Variable value=calculationIndex
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End

Function ImagerSetCalculationIndex(newValue)
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR calculationIndex
	WAVE /T calculationList
	
	// Set the value
	Variable nCalculations=numpnts(calculationList)
	if ( 0<=newValue && newValue<nCalculations )
		calculationIndex=newValue
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	
End

Function /S ImagerGetCalculationName()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE /T calculationList
	NVAR calculationIndex
	
	// get the value
	String value=calculationList[calculationIndex]

	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End

Function /S ImagerGetAllVideoWaveNames()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	SVAR snapshotWaveBaseName
	SVAR videoWaveBaseName

	// Construct the value
	String value=WaveList(snapshotWaveBaseName+"*",";","")+WaveList(videoWaveBaseName+"*",";","")

	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End

Function ImagerSetIROILeft(iROI,newValue)
	Variable iROI
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave

	// Set the value
	Variable ccdWidth=CameraCCDWidthGet()
	Variable iROIRight=roisWave[2][iROI]
	if ( (0<=newValue) && (newValue<=ccdWidth) && (newValue<=iROIRight) )
		roisWave[0][iROI]=newValue
	endif
	
	// Update the frame rate
	ImagerUpdateFrameRateEtc()
	
	// Restore the original DF
	SetDataFolder savedDF	
End



Function ImagerGetIROILeft(iROI)
	Variable iROI

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave

	// Get the value
	Variable value=nan
	Variable nROIs=ImagerGetNROIs()
	if ( (0<=iROI) && (iROI<nROIs) )
		value=roisWave[0][iROI]
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	
	
	// Return the value
	return value
End




Function ImagerSetIROIRight(iROI,newValue)
	Variable iROI
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave

	// Set the value
	Variable ccdWidth=CameraCCDWidthGet()
	Variable iROILeft=roisWave[0][iROI]
	if ( (0<=newValue) && (newValue<=ccdWidth) && (iROILeft<=newValue) )
		roisWave[2][iROI]=newValue
	endif
	
	// Update the frame rate
	ImagerUpdateFrameRateEtc()
	
	// Restore the original DF
	SetDataFolder savedDF	
End



Function ImagerGetIROIRight(iROI)
	Variable iROI

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave

	// Get the value
	Variable value=nan
	Variable nROIs=ImagerGetNROIs()
	if ( (0<=iROI) && (iROI<nROIs) )
		value=roisWave[2][iROI]
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerSetIROITop(iROI,newValue)
	Variable iROI
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave

	// Set the value
	Variable ccdHeight=CameraCCDHeightGet()
	Variable iROIBottom=roisWave[3][iROI]
	if ( (0<=newValue) && (newValue<=ccdHeight) && (newValue<=iROIBottom) )
		roisWave[1][iROI]=newValue
	endif
	
	// Update the frame rate
	ImagerUpdateFrameRateEtc()
	
	// Restore the original DF
	SetDataFolder savedDF	
End



Function ImagerGetIROITop(iROI)
	Variable iROI

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave

	// Get the value
	Variable value=nan
	Variable nROIs=ImagerGetNROIs()
	if ( (0<=iROI) && (iROI<nROIs) )
		value=roisWave[1][iROI]
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerSetIROIBottom(iROI,newValue)
	Variable iROI
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave

	// Set the value
	Variable ccdHeight=CameraCCDHeightGet()
	Variable iROITop=roisWave[1][iROI]
	if ( (0<=newValue) && (newValue<=ccdHeight) && (iROITop<=newValue) )
		roisWave[3][iROI]=newValue
	endif

	// Update the frame rate
	ImagerUpdateFrameRateEtc()	
	
	// Restore the original DF
	SetDataFolder savedDF	
End




Function ImagerGetIROIBottom(iROI)
	Variable iROI

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave

	// Get the value
	Variable value=nan
	Variable nROIs=ImagerGetNROIs()
	if ( (0<=iROI) && (iROI<nROIs) )
		value=roisWave[3][iROI]
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerSetBinSizeIndex(newValue)
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR binSizeIndex

	// Set the value
	binSizeIndex=newValue
	
	// Update the frame rate
	ImagerUpdateFrameRateEtc()
	
	// Restore the original DF
	SetDataFolder savedDF	
End



Function ImagerGetBinSize()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR binSizeIndex
	WAVE binSizeList

	// Get the value
	Variable value=binSizeList[binSizeIndex]
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerGetBinSizeIndex()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR binSizeIndex

	// Get the value
	Variable value=binSizeIndex
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerSetBinSize(newValue)
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR binSizeIndex
	WAVE binSizeList

	// Find the value in the list, and set
	FindValue /I=(newValue) binSizeList
	if (V_value>=0)
		binSizeIndex=V_value
	endif

	// Update the frame rate
	ImagerUpdateFrameRateEtc()
	
	// Restore the original DF
	SetDataFolder savedDF	
End




//Function ImagerGetBinHeight()
//	// Switch to the data folder
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:DP_Imager
//	
//	// Declare instance vars
//	NVAR binSizeIndex
//	WAVE binSizeList
//
//	// Get the value
//	Variable value=binSizeList[binSizeIndex]
//	
//	// Restore the original DF
//	SetDataFolder savedDF	
//
//	// Return the value
//	return value
//End




Function /S ImagerGetBinSizeListAsString()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE binSizeList

	// Build up the return value
	Variable n=numpnts(binSizeList)
	String value=""
	Variable i
	for (i=0; i<n; i+=1)
		value+=sprintf1v("%d;",binSizeList[i])
	endfor
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function /WAVE ImagerGetROIsWave()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave

	// Get the value
	Duplicate /FREE roisWave value
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End





Function ImagerGetNROIs()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave

	// Get the value
	Variable value=DimSize(roisWave,1)
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerGetCurrentROIIndex()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR iROI

	// Get the value
	Variable value=iROI
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerSetCurrentROIIndex(newValue)
	Variable newValue

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR iROI

	// Get the value
	if ( (0<=newValue) && (newValue<ImagerGetNROIs()) )
		iROI=newValue
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	
End




Function ImagerGetFrameRate()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR frameRate

	// Get the value
	Variable value=frameRate
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerGetVideoExposure()
	// Get the exposure duration for video frames, in ms

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR videoExposure 		//ms

	// Get the value
	Variable value=videoExposure
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function /S ImagerGetVideoExposureWanted()
	// Get the requested exposure duration for video frames, as a string, in ms

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	SVAR videoExposureWanted 		// ms

	// Get the value
	String value=videoExposureWanted
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerSetVideoExposureWanted(newValue)
	String newValue

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	SVAR videoExposureWanted

	// Set the value
	Variable newValueAsNumber=str2num(newValue)
	if ( !isnan(newValueAsNumber) && newValueAsNumber>=0 ) 
		videoExposureWanted=newValue
	endif
	
	// Update the frame rate
	ImagerUpdateFrameRateEtc()
	
	// Restore the original DF
	SetDataFolder savedDF	
End




Function ImagerAddROI(xROILeft, yROITop, xROIRight, yROIBottom)
	// Add a ROI.  The coords are in a coordinate system where the upper left corner
	// of the upper left pixel is at (0,0), and the lower right corner of the lower right pixel is at
	// (ccdWidth,ccdHeight).
	Variable xROILeft
	Variable xROIRight
	Variable yROITop
	Variable yROIBottom
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave
	WAVE isBackgroundROI
	NVAR iROI

	// Constrain bounds to image bounds
	Variable nWidthCCD=CameraCCDWidthGet()
	Variable nHeightCCD=CameraCCDHeightGet()
	xROILeft=max(0,min(xROILeft,nWidthCCD))
	yROITop=max(0,min(yROITop,nHeightCCD))
	xROIRight=max(0,min(xROIRight,nWidthCCD))
	yROIBottom=max(0,min(yROIBottom,nHeightCCD))
	
	// Add the new ROI
	Variable nROIsOriginal=ImagerGetNROIs()
	Variable nROIs=nROIsOriginal+1
	Redimension /N=(4,nROIs) roisWave
	iROI=nROIs-1
	roisWave[0][iROI]=xROILeft
	roisWave[1][iROI]=yROITop
	roisWave[2][iROI]=xROIRight
	roisWave[3][iROI]=yROIBottom

	// Add a new entry to isBackgroundROI
	Redimension /N=(nROIs) isBackgroundROI
	isBackgroundROI[iROI]=0	

	// Update the frame rate
	ImagerUpdateFrameRateEtc()
	
	// Restore the original DF
	SetDataFolder savedDF	
End




Function ImagerGetIsTriggered()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare instance vars
	NVAR isTriggered

	// Get the value
	Variable value=isTriggered
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerSetIsTriggered(newValue)
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR isTriggered

	// Set the value
	isTriggered=newValue
	
	// Restore the original DF
	SetDataFolder savedDF	
End



Function ImagerGetIsFocusing()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare instance vars
	NVAR isFocusing

	// Get the value
	Variable value=isFocusing
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerSetIsFocusing(newValue)
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR isFocusing

	// Set the value
	isFocusing=newValue
	
	// Restore the original DF
	SetDataFolder savedDF	
End



Function ImagerGetIsAcquiringVideo()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare instance vars
	NVAR isAcquiringVideo

	// Get the value
	Variable value=isAcquiringVideo
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerSetIsAcquiringVideo(newValue)
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR isAcquiringVideo

	// Set the value
	isAcquiringVideo=newValue
	
	// Restore the original DF
	SetDataFolder savedDF	
End





Function ImagerDeleteCurrentROI()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave
	NVAR iROI
	WAVE isBackgroundROI

	// Delete the current ROI
	Variable nROIsOriginal=ImagerGetNROIs()
	Variable iROIToDelete=iROI
	DeletePoints /M=1 iROIToDelete, 1, roisWave
	DeletePoints /M=0 iROIToDelete, 1, isBackgroundROI

	// If we just deleted the highest-numbered ROI in the list, adjust iROI
	if (iROIToDelete==nROIsOriginal-1)
		iROI=nROIsOriginal-2
	endif
	
	// Update the frame rate
	ImagerUpdateFrameRateEtc()
	
	// Restore the original DF
	SetDataFolder savedDF	
End





Function ImagerSetCurrentROIIsBackground(isThisROIBackgroundNew)
	Variable isThisROIBackgroundNew
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR iROI
	WAVE isBackgroundROI

	// Update the isBackgroundROI array, making sure no more than one element is true on exit
	if (isThisROIBackgroundNew)
		isBackgroundROI=0		// Set all elements to false
		isBackgroundROI[iROI]=1
	else
		isBackgroundROI[iROI]=0
	endif	
	
	// Restore the original DF
	SetDataFolder savedDF	
End




Function ImagerGetCurrentROIIsBackground()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE isBackgroundROI
	NVAR iROI

	// Get the value to return
	Variable value
	Variable nROIs=numpnts(isBackgroundROI)
	if (nROIs>0)
		value=isBackgroundROI[iROI]
	else
		value=nan
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	
	
	return value
End



Function ImagerGetBackgroundROIIndex()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE isBackgroundROI

	// Get the value to return
	Variable value
	FindValue /I=1 isBackgroundROI
	Variable backgroundROIIndex=V_value
	backgroundROIIndex = (backgroundROIIndex<0) ? nan : backgroundROIIndex
	
	// Restore the original DF
	SetDataFolder savedDF	
	
	return backgroundROIIndex
End



Function ImagerTranslateCurrentROIOrAll(dx,dy)
	Variable dx, dy
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR iROI
	NVAR moveAllROIs

	// Do stuff
	if (moveAllROIs)
		Variable nROIs=ImagerGetNROIs()
		Variable i
		for (i=0; i<nROIs; i+=1)
			ImagerTranslateROI(i,dx,dy)			
		endfor
	else
		ImagerTranslateROI(iROI,dx,dy)
	endif
	
	// Restore the original DF
	SetDataFolder savedDF		
End



Function ImagerTranslateROI(iROI,dx,dy)
	// Translate the ROI iROI.  We assume it exists.
	Variable iROI
	Variable dx, dy
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave		// a 2D wave holding a ROI specification in each column, order is : left, top, right, bottom

	// Do stuff
	roisWave[0][iROI]+=dx
	roisWave[1][iROI]+=dy
	roisWave[2][iROI]+=dx
	roisWave[3][iROI]+=dy
	
	// Update the frame rate
	ImagerUpdateFrameRateEtc()
	
	// Restore the original DF
	SetDataFolder savedDF		
End



Function ImagerSetMoveAllROIs(moveAllROIsNew)
	Variable moveAllROIsNew
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR moveAllROIs

	// Set the variable
	moveAllROIs=moveAllROIsNew
	
	// Restore the original DF
	SetDataFolder savedDF	
End



Function ImagerUpdateCCDTemperature()
	// Sometimes this gets called by a background task, so make it extra-robust
	if (!DataFolderExists("root:DP_Imager"))
		return 0
	endif

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR ccdTemperature

	ccdTemperature=FancyCameraGetTemperature()

	// Restore the original DF
	SetDataFolder savedDF	
End



Function ImagerGetCCDTemperature()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR ccdTemperature

	Variable result=ccdTemperature

	// Restore the original DF
	SetDataFolder savedDF	
	
	// Return the current CCD temp
	return result
End




Function ImagerSetCCDTargetTemp(newValue)
	Variable newValue

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR ccdTargetTemperature

	ccdTargetTemperature=newValue
	FancyCameraSetTemp(ccdTargetTemperature)

	// Restore the original DF
	SetDataFolder savedDF	
End




Function ImagerGetCCDTargetTemp()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR ccdTargetTemperature

	Variable result=ccdTargetTemperature

	// Restore the original DF
	SetDataFolder savedDF	
	
	// Return the target CCD temp
	return result
End





//
// Private methods
//

Function ImagerUpdateFrameRateEtc()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR videoExposure  // Hz
	NVAR frameRate		// Hz

	// Get the frame interval for video acquisition, given the current settings, in ms
	String videoExposureWanted=ImagerGetVideoExposureWanted()
	Variable videoExposureWantedAsNumber=str2num(videoExposureWanted)
	Variable nBinSize=ImagerGetBinSize()
	Wave roisWave=ImagerGetROIsWave()
	Wave frameIntervalEtc=FancyCameraGetFrameIntervalEtc(nBinSize,roisWave,videoExposureWantedAsNumber)		// ms
	Variable frameInterval=frameIntervalEtc[0]	// ms
	videoExposure=frameIntervalEtc[1]	// ms
	
	// Set the frame rate
	frameRate=1000/frameInterval		// Hz

	// Restore the original DF
	SetDataFolder savedDF	
End





