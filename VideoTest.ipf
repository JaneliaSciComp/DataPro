Function VideoTest()
	Variable sidxRoot
	Variable sidxCamera	
	Variable sidxAcquire
	String errorMessage
	String license=""		// License file is stored in C:/Program Files/Bruxton/SIDX
	Variable sidxStatus

	// video parameters
	Variable numberOfFrames=4	// Acquire fails if 3<=numberOfFrames<=4 (??)
	Variable exposure=0.1	// s

	// Create the SIDX root object
	SIDXRootOpen sidxRoot, license, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootOpen: %s\r" errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1		
	endif
		
	// Scan for cameras	
	Variable nCameras
	Printf "Scanning for cameras..."
	SIDXRootCameraScan sidxRoot, sidxStatus
	Printf "done.\r"
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootCameraScan: %s\r" errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	
	// Print scan report
	String report
	SIDXRootCameraScanGetReport sidxRoot, report, sidxStatus
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootCameraScanGetReport: %s\r" errorMessage
	endif
	Print report

	// Get the number of cameras
	SIDXRootCameraScanGetCount sidxRoot, nCameras, sidxStatus
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootCameraScanGetCount: %s\r" errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1		
	endif
	Printf "# of cameras: %d\r", nCameras
	
	// If no cameras, abort
	if (nCameras==0)
		Printf "No cameras found.  Aborting.\r"
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1	
	endif
	
	// Get the name of the first camera
	String cameraName
	SIDXRootCameraScanGetName sidxRoot, 0, cameraName, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		printf "Error in SIDXRootCameraScanGetName: %s\r" errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1	
	endif
	printf "cameraName: %s\r", cameraName

	// Create the SIDX camera object
	SIDXRootCameraOpenName sidxRoot, cameraName, sidxCamera, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		printf "Error in SIDXRootCameraOpenName: %s\r" errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1			
	endif

	// Set the binning mode
 	Variable desiredBinningModeIndex=2	// 4x4 bins
	SIDXCameraBinningItemSet sidxCamera, desiredBinningModeIndex, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraBinningItemSet: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	
	// Check that it got set
	Variable currentBinningModeIndex
	SIDXCameraBinningItemGet sidxCamera, currentBinningModeIndex, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraBinningItemGet: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	Printf "currentBinningModeIndex (after setting to %d): %d\r", currentBinningModeIndex, desiredBinningModeIndex
	
	// Set to no trigger
	Variable triggerMode=0	// don't wait for trigger
	SIDXCameraTriggerModeSet sidxCamera, triggerMode, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraTriggerModeSet: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	
	// Set exposure duration
	SIDXCameraExposeSet sidxCamera, exposure, sidxStatus	
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraExposeSet: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	
	// Set to acquire specified number of frames
	SIDXCameraAcquireImageSetLimit sidxCamera, numberOfFrames, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraAcquireImageSetLimit: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	
	// Set buffer to hold the desired number of frames
	Variable bufferDepth = max(numberOfFrames,50)
	Printf "bufferDepth: %d\r", bufferDepth
	SIDXCameraBufferCountSet sidxCamera, bufferDepth, sidxStatus	
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraAcquireImageSetLimit: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif

	// Make a wave to store frame	
	Make /O frames

	// Create the SIDX Acquire object
	SIDXCameraAcquireOpen sidxCamera, sidxAcquire, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraAcquireOpen: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif

	// Start the acquisition
	SIDXAcquireStart sidxAcquire, sidxStatus
	if (sidxStatus!=0)
		SIDXAcquireGetLastError sidxAcquire, errorMessage
		Printf "Error in SIDXAcquireStart: %s\r",errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif

	// Keep getting the status until done
	Variable isAcquiring=1
	do
		Sleep /S 0.1		// Sleep 0.1 seconds
		SIDXAcquireGetStatus sidxAcquire, isAcquiring, sidxStatus
		if (sidxStatus!=0)
			SIDXAcquireGetLastError sidxAcquire, errorMessage
			Printf "Error in SIDXAcquireGetStatus: %s\r" errorMessage
			CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
			return -1
		endif
	while (isAcquiring)

	// Stop the acquire
	SIDXAcquireStop sidxAcquire, sidxStatus
	if (sidxStatus!=0)
		SIDXAcquireGetLastError sidxAcquire, errorMessage
		Printf "Error in SIDXAcquireStop: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif

	// Read the frames
	// It seems I need to pre-allocate frames here...
	// OK, done allocating frames
	SIDXAcquireRead sidxAcquire, numberOfFrames, frames, sidxStatus
	if (sidxStatus!=0)
		SIDXAcquireGetLastError sidxAcquire, errorMessage
		Printf "Error in SIDXAcquireRead: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif

	// Show the image
	NewImage frames

	// Clean up
	SIDXAcquireClose sidxAcquire, sidxStatus
	SIDXCameraClose sidxCamera, sidxStatus
	SIDXRootClose sidxRoot, sidxStatus
End

Function CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
	Variable sidxRoot
	Variable sidxCamera	
	Variable sidxAcquire

	Variable sidxStatus

	SIDXAcquireClose sidxAcquire, sidxStatus
	SIDXCameraClose sidxCamera, sidxStatus
	SIDXRootClose sidxRoot, sidxStatus
End

