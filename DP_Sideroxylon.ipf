//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

// The Sideroxylon "object" wraps all the SIDX functions, so the Imager doesn't have to deal with 
// them directly.  Sideroxylon is a genus of trees commonly known as "bully trees".  I chose the 
// name only because it has the letters S, I, D, and X, in that order.

// Note that these functions were originally based on example code provided by Lin Ci Brown 
// of the Bruston Corporation.





// Construct the object
Function SetupSideroxylonGlobals()
	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_Sideroxylon"))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)

	// IMAGING GLOBALS
	NewDataFolder /O/S root:DP_Sideroxylon
	
	// SIDX stuff
	Variable /G isSidxHandleValid=0	// boolean
	Variable /G sidxHandle

	// Restore the data folder
	SetDataFolder savedDF	
End







Function SideroxylonAcquisition(wave_image, frames_per_sequence, frames, image_trig)
//	Prompt frames_per_sequence, "Number of frames per sequence:" // The number of frames to acquire after a call to SIDXAcquisitionStart
//	Prompt frames, "Number of frames to acquire:"
//	Prompt wave_image, "Wave name for saving the acquired image:"

	String wave_image
	Variable frames_per_sequence, frames, image_trig

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sideroxylon

	// instance vars
	NVAR sidxHandle
	//NVAR image_trig

	Variable status, canceled
	//Silent 1
	//  Perform acquisition
	//SIDXAcquisitionBegin sidxHandle, frames_per_sequence, status
	String message=""
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		printf "%s: %s", "SIDXAcquisitionBegin", message
		return 0
	endif
	Variable bytes, buffer, index, done, roi_index
	Variable x_pixels, y_pixels, maximum_pixel_value, temperature
	//SIDXAcquisitionAllocate sidxHandle, frames_per_sequence, buffer, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXAcquisitionEnd sidxHandle, status
		printf "%s: %s", "SIDXAcquisitionAllocate", message
		return 0
	endif
	Variable locked, hardware_provided, scan
	roi_index = 0
	do
		// Start a sequence of images.
		//SIDXAcquisitionStart sidxHandle, buffer, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXAcquisitionStart", message
			return 0
		endif
		// If the acquisition is external trigger mode, start the trigger here
		// Nelson added the next line to do this
		if (image_trig)
			//DoDataAcq()	// this doesn't exist anymore
		endif
		// Acquire a sequence of frames
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
		// Transfer images from acquisition buffer to IGOR wave
		// To put a stack of images into a 3D wave, call SIDXAcquisitionGetImagesStart and then 
		// SIDXAcquisitionGetImagesGet within the acquisition loop to build the 3D wave.
		// If there are multiple ROIs in each frame, only the first ROI will be saved in the 3D wave.
		//SIDXAcquisitionGetImagesStart sidxHandle, $wave_image, frames_per_sequence, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXAcquisitionGetImagesStart", message
			return 0
		endif
		scan = 0	
		do
			// The second parameter is the frame index in the acquisition buffer (starting from zero). 
			// The fourth parameter is the frame index in the 3D wave.
			//SIDXAcquisitionGetImagesGet sidxHandle, scan, $wave_image, scan, status
			if (status != 0)
				SIDXGetStatusText sidxHandle, status, message
				//SIDXAcquisitionDeallocate sidxHandle, buffer, status
				//SIDXAcquisitionEnd sidxHandle, status
				printf "%s: %s", "SIDXAcquisitionGetImagesGet", message
				return 0
			endif
			scan = scan + 1
		while (scan < frames_per_sequence)
		
		// To put images into individual wave, use SIDXAcquisitionGetImage
		//	SIDXAcquisitionGetImage sidxHandle, 0, $wave_image, status
		//	if (status != 0)
		//		SIDXGetStatusText sidxHandle, status, message
		//		SIDXAcquisitionDeallocate sidxHandle, buffer, status
		//		SIDXAcquisitionEnd sidx_handle, status
		//		printf "%s: %s", "SIDXAcquisitionGetImage", message
		//		return 0
		//	endif
		
		SIDXAcquisitionGetSize sidxHandle, roi_index, bytes, x_pixels, y_pixels, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXAcquisitionGetSize", message
			return 0
		endif
		//SIDXCameraGetTemperature sidxHandle, temperature, locked, hardware_provided, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXCameraGetTemperature", message
			return 0
		endif
		printf "CCD temperature measured: %d, Temperature locked (1 means true): %d, Temperature locked info provided by hardware (1 means true): %d\r", temperature, locked, hardware_provided
		index = index + frames_per_sequence
		print "image stack done"
	while (index < frames)
	print "image acquisition done"
	//SIDXAcquisitionDeallocate sidxHandle, buffer, status
	//SIDXAcquisitionEnd sidxHandle, status
	
	// Restore the original DF
	SetDataFolder savedDF
End







Function SideroxylonEnd()
//	This macro will shutdown the communication with the
//	controller and release memory. It should be called at
//	the end of the experiment. If you want to restart a new
//	experiment after you call this macro, you should call
//	macro SIDXSetup again to start over.
	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sideroxylon

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







Function SideroxylonBegin()
//	This macro will setup the hardware configurations
//	without going through the menus.
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sideroxylon

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








Function SideroxylonSetup(image_roi,roiwave,image_trig,ccd_fullexp)
//	This macro allows you to setup the imaging and acquisition
//	parameters without going through a series of menus.
	Variable image_roi
	Wave roiwave
	Variable image_trig
	Variable ccd_fullexp
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sideroxylon

	// Declare instance variables
	NVAR sidxHandle
	//NVAR isSidxHandleValid
	//NVAR image_roi
	//WAVE roiwave
	//NVAR image_trig
	//NVAR ccd_fullexp
	
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
	if (image_trig>0)
		//SIDXImageSetTrigger sidxHandle, 1, status		// trigger required
	else
		//SIDXImageSetTrigger sidxHandle, 0, status		// no trigger required
		sprintf image_set, "SIDXImageSetExposure sidxHandle, %f, status", ccd_fullexp/1000
		Print image_set
		//Execute image_set 
	endif
	//	check and report temp before finishing
	ccdTempSet()
	
	// Restore the data folder
	SetDataFolder savedDF	
End






Function ccdTempSet()
	// I would have thought this was to set the setpoint of the CCD temperature controller, but it doesn't really seem like that...

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sideroxylon

	// Declare instance variables
	NVAR sidxHandle
	NVAR isSidxHandleValid

	Variable status=0, temperature=0, locked=0, hardware_provided=0
	String message=""
	if (!isSidxHandleValid)
		SideroxylonBegin()
	endif
	//SIDXCameraSetTempSetpoint sidxHandle, ccd_tempset, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXHardwareEnd sidxHandle, status
		//SIDXDriverEnd sidxHandle, status
		SIDXClose sidxHandle
		printf "%s: %s", "SIDXCameraSetTempSetpoint", message
		return 0
	endif
	Variable setpoint=0, temperature_maximum=0, temperature_minimum=0, range_valid=0, difference=0, counter=0
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
	counter=0
	do
		//SIDXCameraGetTemperature sidxHandle, temperature, locked, hardware_provided, status
		//ccd_temp=temperature
		difference=abs(temperature-setpoint)
		counter+=1
		if (counter>100)
			printf "."
			counter=0
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







Function SideroxylonFocus()
//	This is an adaptation of SideroxylonACQUISITION
//	which puts the acquisition withing a loop for focusing
//	exit the loop by pressing the space bar

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sideroxylon
	
	// instance vars
	NVAR sidxHandle
	SVAR focus_name
	NVAR focus_num
	NVAR gray_low, gray_high

	Variable frames_per_sequence, frames
	Variable status, canceled
	Silent 1
	String wave_image
	sprintf wave_image, "%s%d", focus_name, focus_num
	frames_per_sequence=1
	frames=1
	//SIDXAcquisitionBegin sidxHandle, frames_per_sequence, status
	String message
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		printf "%s: %s", "SIDXAcquisitionBegin", message
		return 0
	endif
	Variable bytes, buffer, index, done, roi_index
	Variable x_pixels, y_pixels, maximum_pixel_value, temperature
	//SIDXAcquisitionAllocate sidxHandle, 1, buffer, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXAcquisitionEnd sidxHandle, status
		printf "%s: %s", "SIDXAcquisitionAllocate", message
		return 0
	endif
	Variable locked, hardware_provided
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
		//SIDXAcquisitionGetImage sidxHandle, 0, $wave_image, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXAcquisitionGetImage", message
			return 0
		endif
		SIDXAcquisitionGetSize sidxHandle, roi_index, bytes, x_pixels, y_pixels, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXAcquisitionGetSize", message
			return 0
		endif
//		printf "ROI: %d, Bytes: %d, X pixels: %d, Y pixels: %d\r", roi_index, bytes, x_pixels, y_pixels
		//SIDXCameraGetTemperature sidxHandle, temperature, locked, hardware_provided, status
		if (status != 0)
			SIDXGetStatusText sidxHandle, status, message
			//SIDXAcquisitionDeallocate sidxHandle, buffer, status
			//SIDXAcquisitionEnd sidxHandle, status
			printf "%s: %s", "SIDXCameraGetTemperature", message
			return 0
		endif
//		printf "CCD temperature measured: %d, Temperature locked (1 means true): %d, Temperature locked info provided by hardware (1 means true): %d\r", temperature, locked, hardware_provided
		if (index<1)
			Image_Display(wave_image)
		endif
		if (index>0)
			if (index<2)
				ModifyImage $wave_image ctab= {gray_low,gray_high,Grays,0}
			endif
			ControlInfo auto_on_fly_check0
			if (V_Value>0)
				AutoGrayScaleButtonProc("autogray_button0")
			endif
		endif
		printf "."
	while (!EscapeKeyWasPressed())
	printf "CCD temperature measured: %d, Temperature locked (1 means true): %d, Temperature locked info provided by hardware (1 means true): %d\r", temperature, locked, hardware_provided
	//SIDXAcquisitionDeallocate sidxHandle, buffer, status
	//SIDXAcquisitionEnd sidxHandle, status
//	The next line just puts the image into a single-plane "stack" for consistency with 
//	other acquisition modes and simplicity of the display and autoscale procedures
	Redimension /N=(512,512,1) $wave_image
	
	// Restore the original DF
	SetDataFolder savedDF
End

