//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function ImageBrowserModelConstructor()
	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_ImageBrowserModel"))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)

	// Create the data folder, switch to it
	NewDataFolder /O /S root:DP_ImageBrowserModel

	// Instance vars
	Variable /G iFrame=nan		// Frame index to show in the browser
	Variable /G blackCount=0		// the CCD count that gets mapped to black
	Variable /G whiteCount=2^16-1		// the CCD count that gets mapped to white
	Variable /G isCurrentImageWave=0	// whether there is a current image wave
	String /G imageWaveName=""		// the current wave being shown in the browser
	Variable /G autoscaleToData=1
		// Whether to automatically set blackCount, whiteCount to min/max of image/video

	// If there are any video wave around, make one of them the current one, make the first frame the current one
	String allVideoWaveNames=ImagerGetAllVideoWaveNames()
	if ( ItemsInList(allVideoWaveNames)>0 )
		imageWaveName=StringFromList(0,allVideoWaveNames)
		isCurrentImageWave=1
		iFrame=0
	endif
	
	// Sync the internal ROI boxes to the ROIs in the Imager
	ImageBrowserUpdateROIs()
	
	// Restore the original DF
	SetDataFolder savedDF	
End


Function ImageBrowserModGetAutoscToData()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR autoscaleToData

	Variable value=autoscaleToData

	// Restore the original DF
	SetDataFolder savedDF	

	return value
End



Function ImageBrowserModSetAutoscToData(newValue)
	Variable newValue

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR autoscaleToData

	// Set the field
	autoscaleToData=newValue
	
	// Auto-scale now, if needed
	if (autoscaleToData)
		ImageBrowserModelScaleToData()
	endif

	// Restore the original DF
	SetDataFolder savedDF	
End




Function /S ImageBrowserModGetImWaveName()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR isCurrentImageWave
	SVAR imageWaveName

	String value=stringFif(isCurrentImageWave,imageWaveName,"")

	// Restore the original DF
	SetDataFolder savedDF	

	return value
End



Function /S ImageBrowserModGetImWaveNameAbs()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR isCurrentImageWave
	SVAR imageWaveName

	String value=stringFif(isCurrentImageWave,"root:DP_Imager:"+imageWaveName,"")

	// Restore the original DF
	SetDataFolder savedDF	

	return value
End



Function ImageBrowserModelGetIFrame()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR iFrame

	Variable value=iFrame

	// Restore the original DF
	SetDataFolder savedDF	

	return value
End



Function ImageBrowserModelSetIFrame(newValue)
	Variable newValue

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR iFrame

	iFrame=newValue

	// Restore the original DF
	SetDataFolder savedDF	
End



Function ImageBrowserModelGetBlackCount()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR blackCount

	Variable value=blackCount

	// Restore the original DF
	SetDataFolder savedDF	

	return value
End



Function ImageBrowserModelSetBlackCount(newValue)
	Variable newValue

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR blackCount
	NVAR whiteCount	
	NVAR autoscaleToData

	if (!autoscaleToData)	// Can only set the black count if not auto-auto-scaling
		if (newValue<whiteCount)
			blackCount=newValue
		endif
	endif

	// Restore the original DF
	SetDataFolder savedDF	
End



Function ImageBrowserModelGetWhiteCount()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR whiteCount

	Variable value=whiteCount

	// Restore the original DF
	SetDataFolder savedDF	

	return value
End



Function ImageBrowserModelSetWhiteCount(newValue)
	Variable newValue

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR whiteCount
	NVAR blackCount
	NVAR autoscaleToData

	if (!autoscaleToData)	// Can only set the white count if not auto-auto-scaling
		if (newValue>blackCount)
			whiteCount=newValue
		endif
	endif

	// Restore the original DF
	SetDataFolder savedDF	
End





Function ImageBrowserModelSetVideo(imageWaveNameNew)
	String imageWaveNameNew
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR isCurrentImageWave
	NVAR iFrame
	SVAR imageWaveName
	NVAR autoscaleToData
	
	// Set instance vars appropriately
	String imageWaveNameNewAbs="root:DP_Imager:"+imageWaveNameNew
	if ( WaveExistsByName(imageWaveNameNewAbs) )
		isCurrentImageWave=1
		imageWaveName=imageWaveNameNew
		iFrame=0
		if (autoscaleToData)
			ImageBrowserModelScaleToData()
		endif
	else
		isCurrentImageWave=0
	endif

	// Restore the original DF
	SetDataFolder savedDF		
End




Function ImageBrowserModelScaleToData()
	// This sets blackCount and whiteCount to the min and max of the current frame

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR isCurrentImageWave
	NVAR blackCount
	NVAR whiteCount
	SVAR imageWaveName

	// Find the min and max of the first frame
	if (isCurrentImageWave)
		ImageStats /M=1 root:DP_Imager:$imageWaveName
		blackCount=V_min
		whiteCount=V_max
	endif

	// Restore the original DF
	SetDataFolder savedDF			
End




Function ImageBrowserModelFullScale()
	// This sets blackCount and whiteCount to the min and max possible values

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR autoscaleToData
	NVAR blackCount
	NVAR whiteCount

	// Set 'em
	if (!autoscaleToData)	// If autoscaling to data is checked, don't mess with the scale
		blackCount=0
		whiteCount=2^16-1
	endif

	// Restore the original DF
	SetDataFolder savedDF			
End




Function IBModelGetIsCurrentImageWave()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR isCurrentImageWave

	Variable value=isCurrentImageWave

	// Restore the original DF
	SetDataFolder savedDF	

	return value
End





Function ImageBrowserModelImagerChanged()
	ImageBrowserUpdateROIs()
End







// Private methods

Function ImageBrowserUpdateROIs()
	// Syncs the internal representation of the ROIs to that of the Imager.

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel

	// Populate the DF
	Wave roisWave=ImagerGetROIsWave()
	Variable nROIs=DimSize(roisWave,1)
	Variable iROI
	for (iROI=0; iROI<nROIs; iROI+=1)
		Variable xROILeft=roisWave[0][iROI]
		Variable yROITop=roisWave[1][iROI]
		Variable xROIRight=roisWave[2][iROI]
		Variable yROIBottom=roisWave[3][iROI]
		// Make a wave holding the x-coords of this ROI, for plotting
		String xBoxName=sprintf1v("xBox%d",iROI)
		Make /O $xBoxName={xROILeft, xROIRight, xROIRight, xROILeft, xROILeft}
		// Make a wave holding the y-coords of this ROI, for plotting
		String yBoxName=sprintf1v("yBox%d",iROI)
		Make /O $yBoxName={yROITop, yROITop, yROIBottom, yROIBottom, yROITop}
	endfor
	
	// Restore the original DF
	SetDataFolder savedDF	 
End

 