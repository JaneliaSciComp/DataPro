//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function RootTest()
	// Create the SIDX root object, referenced by sidxRoot
	String errorMessage
	String license=""	// License file is stored in C:/Program Files/Bruxton/SIDX
	Variable sidxStatus
	Variable sidxRoot
	SIDXRootOpen sidxRoot, license, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootOpen: %s\r", errorMessage
		return -1
	endif
	// Close the SIDX root object
	SIDXRootClose sidxRoot, errorMessage
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootClose: %s\r", errorMessage
		return -1
	endif
End



// Construct the object
Function CameraTest()
	// Save the current DF
	String savedDFLocal=GetDataFolder(1)

	// if the DF already exists, switch to it
	if (!DataFolderExists("root:DP_CameraTest"))
		// Create a new DF
		NewDataFolder /O /S root:DP_CameraTest
		String /G savedDF=""
		Variable /G isSidxRootValid=0		// boolean
		Variable /G sidxRoot
		Variable /G isSidxCameraValid=0	// boolean
		Variable /G sidxCamera	
		Variable /G isSidxAcquireValid=0	// boolean
		Variable /G sidxAcquire
		Make /N=(512,512,1) frames			
	else
		SetDataFolder root:DP_CameraTest
	endif

	// Store the old DF
	savedDF=savedDFLocal

	// Create the SIDX root object, referenced by sidxRoot
	String errorMessage
	String license=""		// License file is stored in C:/Program Files/Bruxton/SIDX
	Variable sidxStatus
	SIDXRootOpen sidxRoot, license, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootOpen: %s\r" errorMessage
		CameraTestCleanUp()
		return -1		
	endif
	isSidxRootValid=1
		
	// Scan for cameras	
	Variable nCameras
	Printf "Scanning for cameras..."
	SIDXRootCameraScan sidxRoot, sidxStatus
	Printf "done.\r"
	if (sidxStatus != 0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootCameraScan: %s\r" errorMessage
		CameraTestCleanUp()
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
		CameraTestCleanUp()
		return -1		
	endif
	Printf "# of cameras: %d\r", nCameras
	
	// If no cameras, abort
	if (nCameras==0)
		Printf "No cameras found.  Aborting.\r"
		CameraTestCleanUp()
		return -1	
	endif
	
	// Get the name of the first camera
	String cameraName
	SIDXRootCameraScanGetName sidxRoot, 0, cameraName, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		printf "Error in SIDXRootCameraScanGetName: %s\r" errorMessage
		CameraTestCleanUp()
		return -1	
	endif
	printf "cameraName: %s\r", cameraName

	// Create the SIDX camera object
	SIDXRootCameraOpenName sidxRoot, cameraName, sidxCamera, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		printf "Error in SIDXRootCameraOpenName: %s\r" errorMessage
		CameraTestCleanUp()
		return -1			
	endif
	isSidxCameraValid=1

	// Set to no trigger
	Variable triggerMode=0	// don't wait for trigger
	SIDXCameraTriggerModeSet sidxCamera, triggerMode, sidxStatus
	if (sidxStatus!=0)
		isSidxAcquireValid=0
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraTriggerModeSet: %s\r", errorMessage
		CameraTestCleanUp()
		return -1
	endif
	
	// Set exposure duration
	Variable exposureInSeconds=0.1
	SIDXCameraExposeSet sidxCamera, exposureInSeconds, sidxStatus	
	if (sidxStatus!=0)
		isSidxAcquireValid=0
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraExposeSet: %s\r", errorMessage
		CameraTestCleanUp()
		return -1
	endif
	
	// Set to acquire a single frame	
	Variable nFrames=1
	SIDXCameraAcquireImageSetLimit sidxCamera, nFrames, sidxStatus
	if (sidxStatus!=0)
		isSidxAcquireValid=0
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraAcquireImageSetLimit: %s\r", errorMessage
		CameraTestCleanUp()
		return -1
	endif
	
	// Set buffer to hold a single frame
	SIDXCameraBufferCountSet sidxCamera, nFrames, sidxStatus	
	if (sidxStatus!=0)
		isSidxAcquireValid=0
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraAcquireImageSetLimit: %s\r", errorMessage
		CameraTestCleanUp()
		return -1
	endif
	
	// Create the SIDX Acquire object
	SIDXCameraAcquireOpen sidxCamera, sidxAcquire, sidxStatus
	if (sidxStatus!=0)
		isSidxAcquireValid=0
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraAcquireOpen: %s\r", errorMessage
		CameraTestCleanUp()
		return -1
	endif
	isSidxAcquireValid=1

	// Start the acquisition
	SIDXAcquireStart sidxAcquire, sidxStatus
	if (sidxStatus!=0)
		SIDXAcquireGetLastError sidxAcquire, errorMessage
		Printf "Error in SIDXAcquireStart: %s\r",errorMessage
		CameraTestCleanUp()
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
			CameraTestCleanUp()
			return -1
		endif
	while (isAcquiring)

	// Stop the acquire
	SIDXAcquireStop sidxAcquire, sidxStatus
	if (sidxStatus!=0)
		SIDXAcquireGetLastError sidxAcquire, errorMessage
		Printf "Error in SIDXAcquireStop: %s\r", errorMessage
		CameraTestCleanUp()
		return -1
	endif

	// Read the frames
	// It seems I need to pre-allocate frames here...
	// OK, done allocating frames
	SIDXAcquireRead sidxAcquire, nFrames, frames, sidxStatus
	if (sidxStatus!=0)
		SIDXAcquireGetLastError sidxAcquire, errorMessage
		Printf "Error in SIDXAcquireRead: %s\r", errorMessage
		CameraTestCleanUp()
		return -1
	endif

	// Show the image
	NewImage frames

	// Close the acquire object
	SIDXAcquireClose sidxAcquire, sidxStatus
	if (sidxStatus!=0)
		SIDXAcquireGetLastError sidxAcquire, errorMessage
		Printf "Error in SIDXAcquireClose: %s\r", errorMessage
		CameraTestCleanUp()
		return -1
	endif
	
	// Close the SIDX Camera object
	SIDXCameraClose sidxCamera, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraClose: %s\r", errorMessage
		CameraTestCleanUp()
		return -1
	endif
	
//	// Close the SIDX root object --- Currently this throws an error
//	SIDXRootClose sidxRoot, errorMessage
//	if (sidxStatus!=0)
//		SIDXCameraGetLastError sidxRoot, errorMessage
//		Printf "Error in SIDXRootClose: %s\r", errorMessage
//		CameraTestCleanUp()
//		return -1
//	endif
	
	// Restore the original data folder
	SetDataFolder savedDF
End




Function CameraTestCleanUp()
	SVAR savedDF
	NVAR isSidxRootValid		// boolean
	NVAR sidxRoot
	NVAR isSidxCameraValid		// boolean
	NVAR sidxCamera	
	NVAR isSidxAcquireValid		// boolean
	NVAR sidxAcquire

	Variable sidxStatus
	String errorMessage

	if (isSidxAcquireValid)
		SIDXAcquireClose sidxAcquire, sidxStatus
		if (sidxStatus == 0)
			isSidxAcquireValid=0
		else
			SIDXAcquireGetLastError sidxAcquire, errorMessage
			Printf "Error in SIDXAcquireClose: %s\r" errorMessage
		endif
	endif

	if (isSidxCameraValid)
		SIDXCameraClose sidxCamera, sidxStatus
		if (sidxStatus == 0)
			isSidxCameraValid=0
		else
			SIDXCameraGetLastError sidxCamera, errorMessage
			Printf "Error in SIDXCameraClose: %s\r" errorMessage
		endif
	endif

	if (isSidxRootValid)
		//SIDXRootClose sidxRoot, sidxStatus
		sidxStatus=0
		if (sidxStatus == 0)
			isSidxRootValid=0
		else
			SIDXRootGetLastError sidxRoot, errorMessage
			Printf "Error in SIDXRootClose: %s\r" errorMessage
		endif
	endif
	
	// Restore the original data folder
	SetDataFolder savedDF
End
