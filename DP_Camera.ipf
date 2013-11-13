//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

// The Camera "object" wraps all the SIDX functions, so the Imager doesn't have to deal with 
// them directly.

// Note that these functions were originally based on example code provided by Lin Ci Brown 
// of the Bruston Corporation.






// Construct the object
Function CameraConstructor()
	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_Camera"))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)

	// IMAGING GLOBALS
	NewDataFolder /O /S root:DP_Camera
	
	// SIDX stuff
	Variable /G isSidxHandleValid=0	// boolean
	Variable /G sidxHandle

	// Restore the data folder
	SetDataFolder savedDF	
End







Function CameraInitialize()
	// Initializes the SIDX interface to the camera.  Generally this will be called once per imaging session.

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR sidxHandle
	NVAR isSidxHandleValid
	
	// Create the SIDX object, referenced by sidxHandle
	Variable status
	String message
	SIDXOpen sidxHandle, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		printf "%s: %s", "SIDXOpen", message
		return 0
	endif
	
//	// Restore the camera settings (I guess...) 
//	//SIDXSettingsLoad sidxHandle, status		// doesn't seem to be part of SIDX 6
//	Variable cameraHandle
//	SIDXSettingsRestoreCamera sidxHandle, cameraHandle, status
//	if (status != 0)
//		SIDXGetStatusText sidxHandle, status, message
//		printf "%s: %s", "SIDXSettingsRestoreCamera", message
//		return 0
//	endif
	
//	String driver_set="Driver=\"3\""
//	SIDXDriverSetSettings sidxHandle, driver_set, status
//	sprintf hardware_set, "RoperPIController=\"10\" RoperPIInterface=\"20\" RoperPICCD=\"94\""
//	message = ""
//	SIDXDriverBegin sidxHandle, $message, status
//	if (status != 0)
//		SIDXGetStatusText sidxHandle, status, message
//		SIDXClose sidxHandle
//		printf "%s: %s", "SIDXDriverBegin", message
//		return 0
//	endif
	
//	String hardware_set
//	sprintf hardware_set, "RoperPIController=\"10\" RoperPIInterface=\"20\" RoperPICCD=\"94\""
//	SIDXHardwareSetSettings sidxHandle, hardware_set, status
//	sprintf hardware_set, "RoperPIReadout=\"2\" RoperPIShutterType=\"1\""
//	SIDXHardwareSetSettings sidxHandle, hardware_set, status
//	
//	String message = ""
//	SIDXHardwareBegin sidxHandle, $message, status
//	if (status != 0)
//		SIDXGetStatusText sidxHandle, status, message
//		SIDXDriverEnd sidxHandle, status
//		SIDXClose sidxHandle
//		printf "%s: %s", "SIDXHardwareBegin", message
//		return 0
//	endif
	isSidxHandleValid=1	// Nelson added this flag so this procedure only needs to be run once each expt.
	
	// Restore the data folder
	SetDataFolder savedDF
End








Function CameraSetupAcquisition(image_roi,roiwave,isTriggered,ccd_fullexp,targetTemperature)
	// This sets up the camera for a single acquisition.  (A single aquisition could be a single frame, or it could be a video.)  
	// This is typically called once per acquisition, just before the acquisition.
	Variable image_roi
	Wave roiwave
	Variable isTriggered
	Variable ccd_fullexp
	Variable targetTemperature
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR sidxHandle
	
	Variable status, canceled
	Variable x1, y1, x2, y2
	String message, camera_set, image_set, driver_set, hardware_set
	sprintf camera_set "RoperPIAD=\"1\" RoperPIGain=\"0\" RoperPITiming=\"0\" RoperPITemperature=\"-25.0\" RoperPIExposure=\"0.030000\""
	//SIDXCameraSetSettings sidxHandle, camera_set, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXHardwareEnd sidxHandle, status
		//SIDXDriverEnd sidxHandle, status
		SIDXClose sidxHandle
		printf "%s: %s", "SIDXCameraSetSettings", message
		return 0
	endif
	//SIDXCameraSetSetting sidxHandle, "RoperPICleanScans", "1", status
	//SIDXCameraSetSetting sidxHandle, "RoperPIStripsPerScan", "512", status
	//SIDXCameraSetShutterMode sidxHandle, 4, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		SIDXClose sidxHandle
		printf "%s: %s", "SIDXCameraSetSetting", message
		return 0
	endif
	//	The next several lines can be uncommented to determine values set in menus
	//SIDXCameraGetSettings sidxHandle, message, status
	print message
	//SIDXImageROIFullFrame sidxHandle, status
	if (image_roi>0)
		x1=roiwave[0][1]; y1=roiwave[3][1]; x2=roiwave[1][1]; y2=roiwave[2][1]
		//SIDXImageAddROI sidxHandle, x1, y1, x2, y2, status
		printf "ROI status=%d\r", status
		print x1, y1, x2, y2
		if (image_roi>1)	// add bkgnd ROI
			x1=roiwave[0][2]; y1=roiwave[3][2]; x2=roiwave[1][2]; y2=roiwave[2][2]
			//SIDXImageAddROI sidxHandle, x1, y1, x2, y2, status
			printf "ROI status=%d\r", status
			print x1, y1, x2, y2
		endif
		Variable roi_count
		//SIDXImageGetROICount sidxHandle, roi_count, status
		printf "%d ROIs set\r", roi_count
	endif
	//SIDXImageSetBinning sidxHandle, xbin, ybin, status
	//SIDXImageSetGain sidxHandle, 0, status
	if (isTriggered)
		// Setup for a TTL-triggered acquisition
		//SIDXImageSetTrigger sidxHandle, 1, status		// trigger required
	else
		// Set up for a free-running (non-triggered) aquisition
		//SIDXImageSetTrigger sidxHandle, 0, status		// no trigger required		
		//SIDXImageSetExposure sidxHandle, ccd_fullexp/1000, status		// set the exposure
	endif
	//	check and report temp before finishing
	CameraSetTemperature(targetTemperature)
	
	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraAcquisition(imageWaveName, nFrames, isTriggered)
	// Acquire nFrames, and store the resulting video in imageWaveName.
	// If isTriggered is true, each-frame must be TTL triggered.  If false, the 
	// acquisition is free-running.

	String imageWaveName
	Variable nFrames
	Variable isTriggered

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// instance vars
	NVAR sidxHandle

	//  Set-up for the acquisition
	Variable status
	//SIDXAcquisitionBegin sidxHandle, nFrames, status
	String message=""
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		printf "%s: %s", "SIDXAcquisitionBegin", message
		return 0
	endif	
	Variable iBuffer
	//SIDXAcquisitionAllocate sidxHandle, nFramesPerChunk, iBuffer, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXAcquisitionEnd sidxHandle, status
		printf "%s: %s", "SIDXAcquisitionAllocate", message
		return 0
	endif

	// Prep for the acquisition (this will also start the acquisition unless it's a triggered acquire)
	//SIDXAcquisitionStart sidxHandle, iBuffer, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXAcquisitionDeallocate sidxHandle, iBuffer, status
		//SIDXAcquisitionEnd sidxHandle, status
		printf "%s: %s", "SIDXAcquisitionStart", message
		return 0
	endif

	// If the acquisition is external trigger mode, start the data acq, which will provide the per-frame triggers
	if (isTriggered)
		//DoDataAcq()	// will have to sub in new method call
	endif

	// Spin until the acquisition is done
	Variable done=0
	do
		//SIDXAcquisitionIsDone sidxHandle, done, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionFinish sidxHandle, status
			//SIDXAcquisitionDeallocate sidxHandle, iBuffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXAcquisitionIsDone", message
			return 0
		endif
	while (!done)
	
	// Finalize the acquisition (Not sure what this does in SIDX, but apparently required)
	//SIDXAcquisitionFinish sidxHandle, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXAcquisitionDeallocate sidxHandle, iBuffer, status
		//SIDXAcquisitionEnd sidxHandle, status
		printf "%s: %s", "SIDXAcquisitionFinish", message
		return 0
	endif
	
	// Transfer images from acquisition buffer to IGOR wave
	// To put a stack of images into a 3D wave, call SIDXAcquisitionGetImagesStart and then 
	// SIDXAcquisitionGetImagesGet within the acquisition loop to build the 3D wave.
	// If there are multiple ROIs in each frame, only the first ROI will be saved in the 3D wave.
	//SIDXAcquisitionGetImagesStart sidxHandle, $imageWaveName, nFramesPerChunk, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXAcquisitionDeallocate sidxHandle, iBuffer, status
		//SIDXAcquisitionEnd sidxHandle, status
		printf "%s: %s", "SIDXAcquisitionGetImagesStart", message
		return 0
	endif
	Variable iFrame
	for (iFrame=0; iFrame<nFrames; iFrame+=1)
		// The second parameter is the frame index in the acquisition buffer (starting from zero). 
		// The fourth parameter is the frame index in the 3D wave.
		//SIDXAcquisitionGetImagesGet sidxHandle, iFrame, $imageWaveName, iFrame, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, iBuffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXAcquisitionGetImagesGet", message
			return 0
		endif
	endfor
	
	// To put images into individual wave, use SIDXAcquisitionGetImage
	//	SIDXAcquisitionGetImage sidxHandle, 0, $imageWaveName, status
	//	if (status != 0)
	//		SIDXGetStatusText sidxHandle, status, message
	//		SIDXAcquisitionDeallocate sidxHandle, iBuffer, status
	//		SIDXAcquisitionEnd sidx_handle, status
	//		printf "%s: %s", "SIDXAcquisitionGetImage", message
	//		return 0
	//	endif
	
	Variable iROI=0
	Variable nBytes, nXPixels, nYPixels	// Just to hold return values, not actually used
	SIDXAcquisitionGetSize sidxHandle, iROI, nBytes, nXPixels, nYPixels, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXAcquisitionDeallocate sidxHandle, iBuffer, status
		//SIDXAcquisitionEnd sidxHandle, status
		printf "%s: %s", "SIDXAcquisitionGetSize", message
		return 0
	endif
	
	// Check the CCD temperature
	Variable temperature
	Variable locked, hardware_provided		// Just to hold return values, not actually used
	//SIDXCameraGetTemperature sidxHandle, temperature, locked, hardware_provided, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXAcquisitionDeallocate sidxHandle, iBuffer, status
		//SIDXAcquisitionEnd sidxHandle, status
		printf "%s: %s", "SIDXCameraGetTemperature", message
		return 0
	endif
	printf "CCD temperature measured: %d, Temperature locked (1 means true): %d, Temperature locked info provided by hardware (1 means true): %d\r", temperature, locked, hardware_provided
	print "image stack done"

	print "image acquisition done"
	//SIDXAcquisitionDeallocate sidxHandle, iBuffer, status
	//SIDXAcquisitionEnd sidxHandle, status
	
	// Restore the original DF
	SetDataFolder savedDF
End







Function CameraFinalize()
	// Called to allow the SIDX library to do any required cleanup operations.
	// Generally called at the end of an imaging session.  This is the "partner" of 
	// CameraInitialize().

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// instance vars
	NVAR sidxHandle
	NVAR isSidxHandleValid
	
	Variable status
	String message
	//SIDXSettingsSave sidxHandle, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		printf "%s: %s", "SIDXSettingsSave", message
	endif
	//SIDXHardwareEnd sidxHandle, status
	//SIDXDriverEnd sidxHandle, status
	SIDXClose sidxHandle
	isSidxHandleValid=0
	
	// Restore the original DF
	SetDataFolder savedDF
End









Function CameraSetTemperature(targetTemperature)
	// I would have thought this was to set the setpoint of the CCD temperature controller, but it doesn't really seem like that...
	Variable targetTemperature

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// Declare instance variables
	NVAR sidxHandle
	NVAR isSidxHandleValid

	Variable status=0, temperature=0, locked=0, hardware_provided=0
	String message=""
	//SIDXCameraSetTempSetpoint sidxHandle, targetTemperature, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXHardwareEnd sidxHandle, status
		//SIDXDriverEnd sidxHandle, status
		SIDXClose sidxHandle
		printf "%s: %s", "SIDXCameraSetTempSetpoint", message
		return 0
	endif
	Variable setpoint=0, temperature_maximum=0, temperature_minimum=0, range_valid=0
	//SIDXCameraGetTempSetpoint sidxHandle, setpoint, temperature_minimum, temperature_maximum, range_valid, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXHardwareEnd sidxHandle, status
		//SIDXDriverEnd sidxHandle, status
		SIDXClose sidxHandle
		printf "%s: %s", "SIDXCameraGetTempSetpoint", message
		return 0
	endif
	printf "Temperature setpoint: %.1f, Maximum temperature: %.1f, Minimum temperature: %.1f\r", setpoint, temperature_maximum, temperature_minimum
	//SIDXCameraGetTemperature sidxHandle, temperature, locked, hardware_provided, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXHardwareEnd sidx_handle, status
		//SIDXDriverEnd sidx_handle, status
		SIDXClose sidxHandle
		printf "%s: %s", "SIDXCameraSetTemperature", message
		return 0
	endif
	if ((setpoint-temperature)>0.5)
		printf "warming (press space bar to stop) ..."
	else
		if (abs(setpoint-temperature)>0.5)
			printf "cooling (press space bar to stop) ..."
		endif
	endif
	Variable nItersSinceLastPeriodPrinted=0
	do
		//SIDXCameraGetTemperature sidxHandle, temperature, locked, hardware_provided, status
		//ccd_temp=temperature
		Variable difference=abs(temperature-setpoint)
		nItersSinceLastPeriodPrinted+=1
		if (nItersSinceLastPeriodPrinted>100)
			printf "."
			nItersSinceLastPeriodPrinted=0
		endif
		if (EscapeKeyWasPressed())
			break
		endif
	while (locked<1)
//	usually exits this loop off by a couple of degrees because camera continues to cool too far
//	could consider going back in again to adjust this, but it eventually does it on its own anyway
	printf "\r"
	//SIDXCameraGetTemperature sidxHandle, temperature, locked, hardware_provided, status
	printf "CCD temperature measured: %d, Temperature locked (1 means true): %d, Temperature locked info provided by hardware (1 means true): %d\r", temperature, locked, hardware_provided
	
	// Restore the data folder
	SetDataFolder savedDF	
End







Function CameraFocus()
//	This is an adaptation of CameraACQUISITION
//	which puts the acquisition withing a loop for focusing
//	exit the loop by pressing the space bar

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera
	
	// instance vars
	NVAR sidxHandle
	SVAR focus_name
	NVAR focus_num
	NVAR gray_low, gray_high

	String imageWaveName=sprintf2sv("%s%d", focus_name, focus_num)
	Variable frames_per_sequence=1
	Variable	frames=1
	Variable status
	//SIDXAcquisitionBegin sidxHandle, frames_per_sequence, status
	String message
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		printf "%s: %s", "SIDXAcquisitionBegin", message
		return 0
	endif
	Variable nBytes, buffer, done, roi_index
	Variable x_pixels, y_pixels, maximum_pixel_value, temperature
	//SIDXAcquisitionAllocate sidxHandle, 1, buffer, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXAcquisitionEnd sidxHandle, status
		printf "%s: %s", "SIDXAcquisitionAllocate", message
		return 0
	endif
	Variable locked, hardware_provided
	Variable iFrame=0
	do
		// Start a sequence of images. In the current case, there is 
		// only one frame in the sequence.
		//SIDXAcquisitionStart sidxHandle, buffer, status		
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXAcquisitionStart", message
			return 0
		endif
		do
			//SIDXAcquisitionIsDone sidxHandle, done, status		
			if (status != 0)
				SIDXGetStatusText sidxHandle, status, message
				//SIDXAcquisitionFinish sidxHandle, status
				//SIDXAcquisitionDeallocate sidxHandle, buffer, status
				//SIDXAcquisitionEnd sidxHandle, status
				printf "%s: %s", "SIDXAcquisitionIsDone", message
				return 0
			endif
		while (!done)		
		//SIDXAcquisitionFinish sidxHandle, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXAcquisitionFinish", message
			return 0
		endif
		//SIDXAcquisitionGetImage sidxHandle, 0, $imageWaveName, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXAcquisitionGetImage", message
			return 0
		endif
		SIDXAcquisitionGetSize sidxHandle, roi_index, nBytes, x_pixels, y_pixels, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXAcquisitionGetSize", message
			return 0
		endif
//		printf "ROI: %d, Bytes: %d, X pixels: %d, Y pixels: %d\r", roi_index, nBytes, x_pixels, y_pixels
		//SIDXCameraGetTemperature sidxHandle, temperature, locked, hardware_provided, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXCameraGetTemperature", message
			return 0
		endif
//		printf "CCD temperature measured: %d, Temperature locked (1 means true): %d, Temperature locked info provided by hardware (1 means true): %d\r", temperature, locked, hardware_provided
		if (iFrame==0)
			Image_Display(imageWaveName)
		else
			if (iFrame==1)
				ModifyImage $imageWaveName ctab= {gray_low,gray_high,Grays,0}
			endif
			ControlInfo auto_on_fly_check0
			if (V_Value>0)
				AutoGrayScaleButtonProc("autogray_button0")
			endif
		endif
		iFrame+=1
		printf "."
	while (!EscapeKeyWasPressed())
	printf "CCD temperature measured: %d, Temperature locked (1 means true): %d, Temperature locked info provided by hardware (1 means true): %d\r", temperature, locked, hardware_provided
	//SIDXAcquisitionDeallocate sidxHandle, buffer, status
	//SIDXAcquisitionEnd sidxHandle, status
//	The next line just puts the image into a single-plane "stack" for consistency with 
//	other acquisition modes and simplicity of the display and autoscale procedures
	Redimension /N=(512,512,1) $imageWaveName
	
	// Restore the original DF
	SetDataFolder savedDF
End








Function CameraSetIlluminationNow(isIlluminationOn)
	Variable isIlluminationOn
	// Set the illumination state to isIlluminatonOn
End
