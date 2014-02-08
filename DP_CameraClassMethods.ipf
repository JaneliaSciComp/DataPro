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

// This just contains the Camera class methods.

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




Function /WAVE boundingROIFromROIs(roisWave)
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





Function /WAVE alignCameraROIToGrid(roiInCS,nBinSize)
	// This takes a ROI in image heckbertian coords in the camera space, and aligns it to the binning grid.
	// This is still dealing with ROI borders as infinitesimally thin lines between pixels, both on
	// input and output.
	
	Wave roiInCS
	Variable nBinSize
	
	// Aligned the ROI to the binning
	Variable iLeft=floor(roiInCS[0]/nBinSize)*nBinSize
	Variable iTop=floor(roiInCS[1]/nBinSize)*nBinSize
	Variable iRight=ceil(roiInCS[2]/nBinSize)*nBinSize
	Variable iBottom=ceil(roiInCS[3]/nBinSize)*nBinSize
	Make /FREE /N=4 roiInCSAligned={iLeft,iTop,iRight,iBottom}		
	return roiInCSAligned
End




//Function /WAVE pelIndicesFromROIInCSAndAligned(roiInCSAndAligned)
//	// Computes the camera given all the individual ROIs.  Roughly, the camera ROI is a single
//	// ROI that just includes all the individual ROIs.  But things are slightly more complicated b/c the 
//	// user ROIs are specified in "image Heckbertian" coordinates, and the camera ROI is specified in 
//	// "image pixel" coordinates.  That is, for the user ROIs, the upper left corner of the upper left pixel 
//	// is (0,0), and the lower right corner of the lower right pixel is (n_cols, n_rows).  Further, we consider
//	// the user ROI bounds to be infinitesimally thin.  The camera ROI is simply the index of the first/last 
//	// column/row to be included in the ROI, with the indices being zero-based.	
//	Wave roiInCSAndAligned
//	
//	// Now we have a bounding box, but need to align to the binning
//	Variable iLeft=floor(roiInCS[0]/nBinSize)*nBinSize
//	Variable iTop=floor(roiInCS[1]/nBinSize)*nBinSize
//	Variable iRight=ceil(roiInCS[2]/nBinSize)*nBinSize-1
//	Variable iBottom=ceil(roiInCS[3]/nBinSize)*nBinSize-1
//	Make /FREE /N=4 roiInCSAligned={iLeft,iTop,iRight,iBottom}		
//	return roiInCSAligned
//End
//




Function /WAVE cameraROIFromUserROI(roiInUS,userFromCameraReflectX,userFromCameraReflectY,userFromCameraSwapXY)
	// Translates a userspace image heckbertian ROI into a cameraspace
	// image heckbertian ROI.
	// InUS == in userspace
	// InCS == in cameraspace
	Wave roiInUS
	Variable userFromCameraReflectX	// boolean
	Variable userFromCameraReflectY	// boolean
	Variable userFromCameraSwapXY	// boolean
	
	// Get the CCD size in the camera sapce
 	Variable ccdWidthInCS=CameraCCDWidthGet()
 	Variable ccdHeightInCS=CameraCCDHeightGet()

	// Make a 2x2 matrix of the ROI corners in user space, with each corner a column
	// In Igor,  { { a ,b } , { c , d } } means that a and b are in the first _column_
	Make /FREE /N=(2,2) roiCornersInUS={ {roiInUS[0], roiInUS[1]} , {roiInUS[2], roiInUS[3]} }
	Duplicate /FREE roiCornersInUS, roiCornersInCS
	
	// Swap x and y
	if (userFromCameraSwapXY)
		Duplicate /FREE roiCornersInCS, temp	
		roiCornersInCS[0][]=temp[1][q]
		roiCornersInCS[1][]=temp[0][q]
	endif	

	// Reflect y
	if (userFromCameraReflectY)
		roiCornersInCS[1][]=ccdHeightInCS-roiCornersInCS[1][q]
	endif

	// Reflect x
	if (userFromCameraReflectX)
		roiCornersInCS[0][]=ccdWidthInCS-roiCornersInCS[0][q]
	endif

	// "Normalize" the ROI	
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
	
	return roiInCS
End






Function /WAVE userROIFromCameraROI(roiInCS,userFromCameraReflectX,userFromCameraReflectY,userFromCameraSwapXY)
	// Translates a cameraspace image heckbertian ROI into a userspace
	// image heckbertian ROI.
	// InUS == in userspace
	// InCS == in cameraspace
	Wave roiInCS
	Variable userFromCameraReflectX	// boolean
	Variable userFromCameraReflectY	// boolean
	Variable userFromCameraSwapXY	// boolean
	
	// Get the CCD size in the camera sapce
 	Variable ccdWidthInCS=CameraCCDWidthGet()
 	Variable ccdHeightInCS=CameraCCDHeightGet()

	// Make a 2x2 matrix of the ROI corners in camera space, with each corner a column
	// In Igor,  { { a ,b } , { c , d } } means that a and b are in the first _column_
	Make /FREE /N=(2,2) roiCornersInCS={ {roiInCS[0], roiInCS[1]} , {roiInCS[2], roiInCS[3]} }
	Duplicate /FREE roiCornersInCS, roiCornersInUS
	
	// Reflect x
	if (userFromCameraReflectX)
		roiCornersInUS[0][]=ccdWidthInCS-roiCornersInUS[0][q]
	endif

	// Reflect y
	if (userFromCameraReflectY)
		roiCornersInUS[1][]=ccdHeightInCS-roiCornersInUS[1][q]
	endif
	
	// Swap x and y
	if (userFromCameraSwapXY)
		Duplicate /FREE roiCornersInUS, temp	
		roiCornersInUS[0][]=temp[1][q]
		roiCornersInUS[1][]=temp[0][q]
	endif	

	// "Normalize" the ROI
	Make /FREE /N=(2) xCornersInUS
	xCornersInUS=roiCornersInUS[0][p]
	Make /FREE /N=(2) yCornersInUS
	yCornersInUS=roiCornersInUS[1][p]
	Variable xMinInUS=WaveMin(xCornersInUS)
	Variable yMinInUS=WaveMin(yCornersInUS)
	Variable xMaxInUS=WaveMax(xCornersInUS)
	Variable yMaxInUS=WaveMax(yCornersInUS)
		
	// Package as a ROI
	Make /FREE /N=(4) roiInUS={xMinInUS, yMinInUS, xMaxInUS, yMaxInUS}
	
	return roiInUS
End





Function CameraExists()
	return DataFolderExists("root:DP_Camera")
End
