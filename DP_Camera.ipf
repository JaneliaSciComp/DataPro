//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

// The Camera "object" wraps all the SIDX functions, so the Imager doesn't have to deal with 
// them directly.

// Note that these functions were originally based on example code provided by Lin Ci Brown 
// of the Bruxton Corporation.






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
	Variable /G isFramebufferAllocated=0	// boolean
	Variable /G iBuffer	// some kind of buffer index

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
	// Set the CCD temp, wait for it to stabilize
	CameraSetTemperature(targetTemperature)
	
	// Restore the data folder
	SetDataFolder savedDF	
End






Function CameraAllocateFramebuffer(imageWaveName, nFrames)
	// Acquire nFrames, and store the resulting video in imageWaveName.
	// If isTriggered is true, each-frame must be TTL triggered.  If false, the 
	// acquisition is free-running.

	String imageWaveName
	Variable nFrames

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// instance vars
	NVAR sidxHandle
	NVAR isFramebufferAllocated
	NVAR iBuffer

	//  Set-up for the acquisition
	Variable status
	//SIDXAcquisitionBegin sidxHandle, nFrames, status
	String message=""
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		printf "%s: %s", "SIDXAcquisitionBegin", message
		return 0
	endif	
	//SIDXAcquisitionAllocate sidxHandle, nFrames, iBuffer, status
	if (status != 0)
		SIDXGetStatusText sidxHandle, status, message
		//SIDXAcquisitionEnd sidxHandle, status
		printf "%s: %s", "SIDXAcquisitionAllocate", message
		return 0
	endif
	
	// Remember that the framebuffer is allocated
	isFramebufferAllocated=1
	
	// Restore the original DF
	SetDataFolder savedDF
End





Function CameraAcquire(imageWaveName, nFrames, isTriggered)
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
	NVAR isFramebufferAllocated

	// Check that the framebuffer is allocated
	if (!isFrameBufferAllocated)
		return 0		// Have to return something
	endif

	// Prep for the acquisition (this will also start the acquisition unless it's a triggered acquire)
	Variable statusCode
	//SIDXAcquisitionStart sidxHandle, iBuffer, statusCode
	if (statusCode != 0)
		String message
		SIDXGetStatusText sidxHandle, statusCode, message
		//SIDXAcquisitionDeallocate sidxHandle, iBuffer, statusCode
		//SIDXAcquisitionEnd sidxHandle, statusCode
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
		//SIDXAcquisitionIsDone sidxHandle, done, statusCode
		if (statusCode != 0)
			SIDXGetStatusText sidxHandle, statusCode, message
			//SIDXAcquisitionFinish sidxHandle, statusCode
			//SIDXAcquisitionDeallocate sidxHandle, iBuffer, statusCode
			//SIDXAcquisitionEnd sidxHandle, statusCode
			printf "%s: %s", "SIDXAcquisitionIsDone", message
			return 0
		endif
	while (!done)
	
	// Finalize the acquisition (Not sure what this does in SIDX, but apparently required)
	//SIDXAcquisitionFinish sidxHandle, statusCode
	if (statusCode != 0)
		SIDXGetStatusText sidxHandle, statusCode, message
		//SIDXAcquisitionDeallocate sidxHandle, iBuffer, statusCode
		//SIDXAcquisitionEnd sidxHandle, statusCode
		printf "%s: %s", "SIDXAcquisitionFinish", message
		return 0
	endif
	
	// Transfer images from acquisition buffer to IGOR wave
	// To put a stack of images into a 3D wave, call SIDXAcquisitionGetImagesStart and then 
	// SIDXAcquisitionGetImagesGet within the acquisition loop to build the 3D wave.
	// If there are multiple ROIs in each frame, only the first ROI will be saved in the 3D wave.
	//SIDXAcquisitionGetImagesStart sidxHandle, $imageWaveName, nFramesPerChunk, statusCode
	if (statusCode != 0)
		SIDXGetStatusText sidxHandle, statusCode, message
		//SIDXAcquisitionDeallocate sidxHandle, iBuffer, statusCode
		//SIDXAcquisitionEnd sidxHandle, statusCode
		printf "%s: %s", "SIDXAcquisitionGetImagesStart", message
		return 0
	endif
	Variable iFrame
	for (iFrame=0; iFrame<nFrames; iFrame+=1)
		// The second parameter is the frame index in the acquisition buffer (starting from zero). 
		// The fourth parameter is the frame index in the 3D wave.
		//SIDXAcquisitionGetImagesGet sidxHandle, iFrame, $imageWaveName, iFrame, statusCode
		if (statusCode != 0)
			SIDXGetStatusText sidxHandle, statusCode, message
			//SIDXAcquisitionDeallocate sidxHandle, iBuffer, statusCode
			//SIDXAcquisitionEnd sidxHandle, statusCode
			printf "%s: %s", "SIDXAcquisitionGetImagesGet", message
			return 0
		endif
	endfor
	
	// To put images into individual wave, use SIDXAcquisitionGetImage
	//	SIDXAcquisitionGetImage sidxHandle, 0, $imageWaveName, statusCode
	//	if (statusCode != 0)
	//		SIDXGetStatusText sidxHandle, statusCode, message
	//		SIDXAcquisitionDeallocate sidxHandle, iBuffer, statusCode
	//		SIDXAcquisitionEnd sidx_handle, statusCode
	//		printf "%s: %s", "SIDXAcquisitionGetImage", message
	//		return 0
	//	endif
	
	Variable iROI=0
	Variable nBytes, nXPixels, nYPixels	// Just to hold return values, not actually used
	SIDXAcquisitionGetSize sidxHandle, iROI, nBytes, nXPixels, nYPixels, statusCode
	if (statusCode != 0)
		SIDXGetStatusText sidxHandle, statusCode, message
		//SIDXAcquisitionDeallocate sidxHandle, iBuffer, statusCode
		//SIDXAcquisitionEnd sidxHandle, statusCode
		printf "%s: %s", "SIDXAcquisitionGetSize", message
		return 0
	endif
	
	// Check the CCD temperature
	Variable temperature
	Variable locked, hardware_provided		// Just to hold return values, not actually used
	//SIDXCameraGetTemperature sidxHandle, temperature, locked, hardware_provided, statusCode
	if (statusCode != 0)
		SIDXGetStatusText sidxHandle, statusCode, message
		//SIDXAcquisitionDeallocate sidxHandle, iBuffer, statusCode
		//SIDXAcquisitionEnd sidxHandle, statusCode
		printf "%s: %s", "SIDXCameraGetTemperature", message
		return 0
	endif
	printf "CCD temperature measured: %d, Temperature locked (1 means true): %d, Temperature locked info provided by hardware (1 means true): %d\r", temperature, locked, hardware_provided
	print "image stack done"

	print "image acquisition done"

	// Restore the original DF
	SetDataFolder savedDF
End








Function CameraDeallocateFramebuffer()
	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Camera

	// instance vars
	NVAR sidxHandle
	NVAR isFramebufferAllocated
	NVAR iBuffer

	if (isFramebufferAllocated)
		// Deallocate the framebuffer
 		//SIDXAcquisitionDeallocate sidxHandle, iBuffer, status
		//SIDXAcquisitionEnd sidxHandle, status
	
		// Note that the framebuffer is no longer allocated
		isFramebufferAllocated=0
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End





Function CameraAllocateAndAcquire(imageWaveName, nFrames, isTriggered)
	// Acquire nFrames, and store the resulting video in imageWaveName.
	// If isTriggered is true, each-frame must be TTL triggered.  If false, the 
	// acquisition is free-running.  This also handles the allocation and de-allocation
	// of the on-camera framebuffer.

	String imageWaveName
	Variable nFrames
	Variable isTriggered

	CameraAllocateFramebuffer(imageWaveName, nFrames)
	CameraAcquire(imageWaveName, nFrames, isTriggered)
	CameraDeallocateFramebuffer()
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



