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
	String /G imageWaveName=""
	Variable /G autoscaleOnTheFly=0
		// Whether to automatically set blackCount, whiteCount to min/max of image/video
	
	// Restore the original DF
	SetDataFolder savedDF	
End


Function ImageBrowserModGetAutoscaleFly()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR autoscaleOnTheFly

	Variable value=autoscaleOnTheFly

	// Restore the original DF
	SetDataFolder savedDF	

	return value
End


Function /S ImageBrowserModGetImageWaveName()
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	SVAR imageWaveName

	String value=imageWaveName

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





Function ImageBrowserModelSetVideo(imageWaveNameNew)
	String imageWaveNameNew
	
	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR iFrame
	SVAR imageWaveName
	NVAR autoscaleOnTheFly
	
	// Set instance vars appropriately
	imageWaveName=imageWaveNameNew
	iFrame=0
	if (autoscaleOnTheFly)
		ImageBrowserModelAutoscale()
	endif

	// Restore the original DF
	SetDataFolder savedDF		
End




// Private methods
Function ImageBrowserModelAutoscale()
	// This sets blackCount and whiteCount to the min and max of the current frame

	// Switch to the data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ImageBrowserModel
	
	// Declare instance vars
	NVAR blackCount
	NVAR whiteCount
	SVAR imageWaveName

	// Find the min and max of the first frame
	ImageStats /M=1 $imageWaveName
	blackCount=V_min
	whiteCount=V_max

	// Restore the original DF
	SetDataFolder savedDF			
End