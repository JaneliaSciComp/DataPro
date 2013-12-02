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
	Variable /G isTriggered		// boolean, true iff the image acquisition will be triggered (as opposed to free-running)
	Variable /G isFocusing=0		// boolean, whether or not we're currently focusing
	Variable /G isAcquiringVideo=0		// boolean, whether or not we're currently taking video
	//Variable /G image_focus	// image_focus may be unnecessary if there is a separate focus routine
	Variable /G isROI=0		// is there a ROI? (false=>full frame)
	Variable /G isBackgroundROIToo=0		// if isROI, is there a background ROI too? (if full-frame, this is unused)
	Variable /G ccdTargetTemperature= -20		// the setpoint CCD temperature
	//Variable /G ccdTemperature=nan			// the current CCD temperature
	Variable /G nFramesForVideo=56	// number of frames to acquire
	//Variable /G focusingExposure=100		// duration of each exposure when focusing, in ms
	Variable /G snapshotExposure=100		// duration of each frame exposure for full-frame images, in ms
	Variable /G videoExposure=50	// duration of each frame for triggered video, in ms
	//Variable /G iFrame		// Frame index to show in the browser
	String /G fullFrameWaveBaseName="snap"		// the base name of the full-frame image waves, including the underscore
	//String /G focusWaveBaseName="full_"		// the base name of the focusing image waves, including the underscore
	String /G videoWaveBaseName="video"	// the base name of the triggered video waves, including the underscore
	//Variable /G iFullFrameWave=1	// The "sweep number" to use for the next full-frame image
	//Variable /G iFocusWave=1		// The "sweep number" to use for the next focus image
	//Variable /G iVideoWave=1		// The "sweep number" to use for the video 
	Variable /G binWidth=8	// CCD bins per pixel in x dimension
	Variable /G binHeight=8	// CCD bins per pixel in y dimension
	Variable /G iROI=nan		// indicates the current ROI
	//Variable /G binnedFrameWidth=(iROIRight-iROILeft+1)/binWidth	// Width of the binned ROI image
	//Variable /G binnedFrameHeight=(iROIBottom-iROITop+1)/binHeight		// Height of the binned ROI image
	//Variable /G blackCount=0		// the CCD count that gets mapped to black
	//Variable /G whiteCount=2^16-1	// the CCD count that gets mapped to white
	
	Variable nROIs=0
	Make /O /N=(4,nROIs) /I roisWave		// a 2D wave holding a ROI specification in each column
	
	// make average wave for imaging
	Variable /G nFramesInAverage=0		// number of frames to average, I think for calculating dF/F
	Make /O /N=(nFramesInAverage) dff_avg
	
	// Restore the original data folder
	SetDataFolder savedDF	
End

Function /S ImagerGetAllVideoWaveNames()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	SVAR fullFrameWaveBaseName
	SVAR videoWaveBaseName

	// Construct the value
	String value=WaveList(fullFrameWaveBaseName+"*",";","")+WaveList(videoWaveBaseName+"*",";","")

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
	Variable iROIRight=roisWave[1][iROI]
	if ( (0<=newValue) && (newValue<ccdWidth) && (newValue<=iROIRight) )
		roisWave[0][iROI]=newValue
	endif
	
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
	if ( (0<=newValue) && (newValue<ccdWidth) && (iROILeft<=newValue) )
		roisWave[1][iROI]=newValue
	endif
	
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
		value=roisWave[1][iROI]
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
	Variable ccdWidth=CameraCCDWidthGet()
	Variable iROIBottom=roisWave[1][iROI]
	if ( (0<=newValue) && (newValue<ccdWidth) && (newValue<=iROIBottom) )
		roisWave[2][iROI]=newValue
	endif
	
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
		value=roisWave[2][iROI]
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
	Variable ccdWidth=CameraCCDWidthGet()
	Variable iROITop=roisWave[0][iROI]
	if ( (0<=newValue) && (newValue<ccdWidth) && (iROITop<=newValue) )
		roisWave[3][iROI]=newValue
	endif
	
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




Function ImagerSetBinWidth(newValue)
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR binWidth

	// Set the value
	Variable ccdWidth=CameraCCDWidthGet()
	if ( (1<=newValue) && (newValue<=ccdWidth) )
		binWidth=newValue
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	
End



Function ImagerGetBinWidth()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR binWidth

	// Get the value
	Variable value=binWidth
	
	// Restore the original DF
	SetDataFolder savedDF	

	// Return the value
	return value
End




Function ImagerSetBinHeight(newValue)
	Variable newValue
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR binHeight

	// Set the value
	Variable ccdHeight=CameraCCDHeightGet()
	if ( (1<=newValue) && (newValue<=ccdHeight) )
		binHeight=newValue
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	
End




Function ImagerGetBinHeight()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	NVAR binHeight

	// Get the value
	Variable value=binHeight
	
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




Function ImagerGetIROI()
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




Function ImagerAddROI(iROILeft, iROIRight, iROITop, iROIBottom)
	Variable iROILeft
	Variable iROIRight
	Variable iROITop
	Variable iROIBottom
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// Declare instance vars
	WAVE roisWave
	NVAR iROI
	
	// Add the new ROI
	Variable nROIsOriginal=ImagerGetNROIs()
	Variable nROIs=nROIsOriginal+1
	Redimension /N=(4,nROIs) roisWave
	iROI=nROIs-1
	roisWave[0][iROI]=iROILeft
	roisWave[1][iROI]=iROIRight
	roisWave[2][iROI]=iROITop
	roisWave[3][iROI]=iROIBottom
	
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


