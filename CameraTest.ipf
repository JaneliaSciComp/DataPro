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
	Printf "sidxRoot: %d\r", sidxRoot
	// Close the SIDX root object
	SIDXRootClose sidxRoot, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootClose: %s\r", errorMessage
		return -1
	endif
	SIDXRootClose sidxRoot, sidxStatus 	// what happens if we close again?
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootClose: %s\r", errorMessage
		return -1
	endif
End



Function TestSerialNumberGet()
	// Create the SIDX root object, referenced by sidxRoot
	String errorMessage
	String license=""	// License file is stored in C:/Program Files/Bruxton/SIDX
	Variable sidxStatus
	Variable sidxRoot
	Variable serialNumber
	SIDXRootOpen sidxRoot, license, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootOpen: %s\r", errorMessage
		return -1
	endif
	Printf "sidxRoot: %d\r", sidxRoot

	// Get the serial number
	SIDXRootSoftwareGetSerial sidxRoot, serialNumber, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootSoftwareGetSerial: %s\r", errorMessage
		return -1
	endif
	Printf "serialNumber %d\r", serialNumber
	
//	// Get the serial number
//	SIDXRootSoftwareGetSerial sidxRoot, serialNumber, sidxStatus
//	if (sidxStatus!=0)
//		SIDXCameraGetLastError sidxRoot, errorMessage
//		Printf "Error in SIDXRootSoftwareGetSerial: %s\r", errorMessage
//		return -1
//	endif
//	Printf "serialNumber %d\r", serialNumber
//	
//	// Get the serial number
//	SIDXRootSoftwareGetSerial sidxRoot, serialNumber, sidxStatus
//	if (sidxStatus!=0)
//		SIDXCameraGetLastError sidxRoot, errorMessage
//		Printf "Error in SIDXRootSoftwareGetSerial: %s\r", errorMessage
//		return -1
//	endif
//	Printf "serialNumber %d\r", serialNumber
	
	// Close the SIDX root object
	SIDXRootClose sidxRoot, sidxStatus
	if (sidxStatus!=0)
		SIDXRootGetLastError sidxRoot, errorMessage
		Printf "Error in SIDXRootClose: %s\r", errorMessage
		return -1
	endif
End





Function SingleFrameTest()
	Variable sidxRoot
	Variable sidxCamera	
	Variable sidxAcquire
	String errorMessage
	String license=""		// License file is stored in C:/Program Files/Bruxton/SIDX
	Variable sidxStatus

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
	Variable exposureInSeconds=0.1
	SIDXCameraExposeSet sidxCamera, exposureInSeconds, sidxStatus	
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraExposeSet: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	
	// Set to acquire a single frame	
	Variable nFrames=1
	SIDXCameraAcquireImageSetLimit sidxCamera, nFrames, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraAcquireImageSetLimit: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	
	// Set buffer to hold a single frame
	SIDXCameraBufferCountSet sidxCamera, nFrames, sidxStatus	
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraAcquireImageSetLimit: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif

	// Get the current binning settings
	Variable binWidth, binHeight
	SIDXCameraBinningGet sidxCamera, binWidth, binHeight, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraBinningGet: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	Printf "binWidth: %d\r", binWidth
	Printf "binHeight: %d\r", binHeight

	// Get the current binning "type"
	// This tells you something about the possible binning settings
	// Apparently SIDX has many places where you can probe for what kind of a setting a particualr setting is.
	// So, for binning, some cameras might have a list of discrete possible settings, whereas some might let
	// you set it to an arbitrary integer (within limits)
	// 0==boolean
	// 1==integer
	// 2==list
	// 3==none
	// 4==real
	// 5==sequence
	// 6==string
	// For SIDXCameraBinningGetType, the value is always either none, or list
	// If none, that means the X and Y binning are independently settable, and one could call
	// SIDXCameraBinningXGetType/SIDXCameraBinningYGetType to get the setting type of each
	// If list, it means that the binning for X&Y must be set at the same time, and there's a discrete list
	// of possible values (e.g., powers of two)
	Variable binningType
	SIDXCameraBinningGetType sidxCamera, binningType, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraBinningGetType: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	Printf "binningType: %d\r", binningType

	// Get the number of binning modes
	Variable nBinningModes
	SIDXCameraBinningItemGetCount sidxCamera, nBinningModes, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraBinningItemGetCount: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	Printf "nBinningModes: %d\r", nBinningModes

	// List the binning modes
	Variable iBinningMode
	Variable binWidthThis
	Variable binHeightThis
	for (iBinningMode=0; iBinningMode<nBinningModes; iBinningMode+=1)
		SIDXCameraBinningItemGetEntry sidxCamera, iBinningMode, binWidthThis, binHeightThis, sidxStatus
		if (sidxStatus!=0)
			SIDXCameraGetLastError sidxCamera, errorMessage
			Printf "Error in SIDXCameraBinningGetEntry: %s\r", errorMessage
			CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
			return -1
		endif
		Printf "     iBinningMode: %d: binWidth: %d, binHeight: %d\r", iBinningMode,binWidthThis, binHeightThis
	endfor
	
	// Get the current binning mode
	Variable currentBinningModeIndex
	SIDXCameraBinningItemGet sidxCamera, currentBinningModeIndex, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraBinningItemGet: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	Printf "currentBinningModeIndex: %d\r", currentBinningModeIndex
	
	// Set the binning mode
 	Variable desiredBinningModeIndex=3	// 4x4 bins
	SIDXCameraBinningItemSet sidxCamera, desiredBinningModeIndex, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraBinningItemSet: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	
	// Check that it got set
	SIDXCameraBinningItemGet sidxCamera, currentBinningModeIndex, sidxStatus
	if (sidxStatus!=0)
		SIDXCameraGetLastError sidxCamera, errorMessage
		Printf "Error in SIDXCameraBinningItemGet: %s\r", errorMessage
		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
		return -1
	endif
	Printf "currentBinningModeIndex (after setting to %d): %d\r", currentBinningModeIndex, desiredBinningModeIndex
	
	
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
	SIDXAcquireRead sidxAcquire, nFrames, frames, sidxStatus
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




Function VideoTest()
	Variable sidxRoot
	Variable sidxCamera	
	Variable sidxAcquire
	String errorMessage
	String license=""		// License file is stored in C:/Program Files/Bruxton/SIDX
	Variable sidxStatus

	// video parameters
	Variable numberOfFrames=5	// Acquire fails if 3<=numberOfFrames<=4 (??)
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

//	// Clear the ROI (which shouldn't be set)
//	SIDXCameraROIClear sidxCamera, sidxStatus
//	if (sidxStatus!=0)
//		SIDXCameraGetLastError sidxCamera, errorMessage
//		Printf "Error in SIDXCameraROIClear: %s\r", errorMessage
//		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
//		return -1
//	endif

//	// Get the current binning settings
//	Variable binWidth, binHeight
//	SIDXCameraBinningGet sidxCamera, binWidth, binHeight, sidxStatus
//	if (sidxStatus!=0)
//		SIDXCameraGetLastError sidxCamera, errorMessage
//		Printf "Error in SIDXCameraBinningGet: %s\r", errorMessage
//		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
//		return -1
//	endif
//	Printf "binWidth: %d\r", binWidth
//	Printf "binHeight: %d\r", binHeight
//
//	// Get the current binning "type"
//	// This tells you something about the possible binning settings
//	// Apparently SIDX has many places where you can probe for what kind of a setting a particualr setting is.
//	// So, for binning, some cameras might have a list of discrete possible settings, whereas some might let
//	// you set it to an arbitrary integer (within limits)
//	// 0==boolean
//	// 1==integer
//	// 2==list
//	// 3==none
//	// 4==real
//	// 5==sequence
//	// 6==string
//	// For SIDXCameraBinningGetType, the value is always either none, or list
//	// If none, that means the X and Y binning are independently settable, and one could call
//	// SIDXCameraBinningXGetType/SIDXCameraBinningYGetType to get the setting type of each
//	// If list, it means that the binning for X&Y must be set at the same time, and there's a discrete list
//	// of possible values (e.g., powers of two)
//	Variable binningType
//	SIDXCameraBinningGetType sidxCamera, binningType, sidxStatus
//	if (sidxStatus!=0)
//		SIDXCameraGetLastError sidxCamera, errorMessage
//		Printf "Error in SIDXCameraBinningGetType: %s\r", errorMessage
//		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
//		return -1
//	endif
//	Printf "binningType: %d\r", binningType
//
//	// Get the number of binning modes
//	Variable nBinningModes
//	SIDXCameraBinningItemGetCount sidxCamera, nBinningModes, sidxStatus
//	if (sidxStatus!=0)
//		SIDXCameraGetLastError sidxCamera, errorMessage
//		Printf "Error in SIDXCameraBinningItemGetCount: %s\r", errorMessage
//		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
//		return -1
//	endif
//	Printf "nBinningModes: %d\r", nBinningModes
//
//	// List the binning modes
//	Variable iBinningMode
//	Variable binWidthThis
//	Variable binHeightThis
//	for (iBinningMode=0; iBinningMode<nBinningModes; iBinningMode+=1)
//		SIDXCameraBinningItemGetEntry sidxCamera, iBinningMode, binWidthThis, binHeightThis, sidxStatus
//		if (sidxStatus!=0)
//			SIDXCameraGetLastError sidxCamera, errorMessage
//			Printf "Error in SIDXCameraBinningGetEntry: %s\r", errorMessage
//			CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
//			return -1
//		endif
//		Printf "     iBinningMode: %d: binWidth: %d, binHeight: %d\r", iBinningMode,binWidthThis, binHeightThis
//	endfor
//	
//	// Get the current binning mode
	Variable currentBinningModeIndex
//	SIDXCameraBinningItemGet sidxCamera, currentBinningModeIndex, sidxStatus
//	if (sidxStatus!=0)
//		SIDXCameraGetLastError sidxCamera, errorMessage
//		Printf "Error in SIDXCameraBinningItemGet: %s\r", errorMessage
//		CameraCleanUp(sidxRoot,sidxCamera,sidxAcquire)
//		return -1
//	endif
//	Printf "currentBinningModeIndex: %d\r", currentBinningModeIndex
	
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

