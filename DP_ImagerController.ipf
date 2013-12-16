//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access



Function ImagerContConstructor()
	ImagerConstructor()
	ImagerViewConstructor()
End


//
//  Front-line functions for handling user actions
//

Function ICTempSetpointSVTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	FancyCameraSetTempAndWait(varNum)
End



Function ICTakeSnapshotButtonPressed(ctrlName) : ButtonControl
	String ctrlName
	ImagerContAcquireSnapshot()
End



Function ICFocusButtonPressed(ctrlName) : ButtonControl
	String ctrlName
	ImagerContFocus()
End



Function ICAcquireVideoButtonPressed(ctrlName) : ButtonControl
	String ctrlName
	ImagerContAcquireVideo()
End



Function ICTriggeredCBTwiddled(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	ImagerSetIsTriggered(checked)
	ImagerViewModelChanged()
End



Function ICEpiLightToggleButtonPressed(ctrlName) : ButtonControl
	String ctrlName
	
	EpiLightSetIsOn(~EpiLightGetIsOn())
	ImagerViewEpiLightChanged()
End



Function ICBinOrROISVTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	Variable iROI=ImagerGetCurrentROIIndex()
	if ( AreStringsEqual(ctrlName,"iROILeftSV") )
		ImagerSetIROILeft(iROI,varNum)
	elseif ( AreStringsEqual(ctrlName,"iROIRightSV") )
		ImagerSetIROIRight(iROI,varNum)
	elseif ( AreStringsEqual(ctrlName,"iROITopSV") )
		ImagerSetIROITop(iROI,varNum)
	elseif ( AreStringsEqual(ctrlName,"iROIBottomSV") )
		ImagerSetIROIBottom(iROI,varNum)
	elseif ( AreStringsEqual(ctrlName,"binWidthSV") )
		ImagerSetBinWidth(varNum)
	elseif ( AreStringsEqual(ctrlName,"binHeightSV") )
		ImagerSetBinHeight(varNum)
	endif
	ImagerViewModelChanged()
	ImageBrowserModelImagerChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICCurrentROIIndexSVTwiddled(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct
	
	// If control is being killed, do nothing
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	

	// Do stuff
	Variable iROIPlusOne=svStruct.dval
	ImagerSetCurrentROIIndex(iROIPlusOne-1)
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICDeleteROIButtonPressed(ctrlName) : ButtonControl
	String ctrlName
	ImagerDeleteCurrentROI()
	ImageBrowserModelImagerChanged()
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End


//
// The routines that do substantial stuff are below
//


Function ImagerContAcquireVideo()
	Variable iSweep=ImagerContAcquireVideoStart()
	ImagerContAcquireFinish(iSweep)
	// Make everything update itself
	DoUpdate		
End



Function ImagerContAcquireVideoStart()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the instance vars
	WAVE roisWave
	NVAR videoExposure
	NVAR ccdTargetTemperature	
	NVAR binWidth
	NVAR binHeight
	SVAR videoWaveBaseName
	NVAR nFramesForVideo
	NVAR isTriggered
	
	// Do stuff
	Variable iSweep=SweeperGetNextSweepIndex()
	ImagerSetIsAcquiringVideo(1)
	ImagerViewModelChanged()
	DoUpdate	
	FancyCameraSetupVideoAcq(binWidth,binHeight,roisWave,isTriggered,videoExposure,ccdTargetTemperature)
	EpiLightSetIsOn(1)
	
	//Wave imageWave=FancyCameraArmAcquireDisarm(nFramesForVideo)		// This will call SweeperControllerAcquireTrial() if in triggered mode
	FancyCameraArm(nFramesForVideo)
	//Wave imageWave=FancyCameraAcquire(nFrames)		// This will call SweeperControllerAcquireTrial() if in triggered mode
	FancyCameraStartAcquire()
//	Wave imageWave=FancyCameraWaitForFrames(nFramesForVideo)
//	FancyCameraDisarm()
//	
//	EpiLightSetIsOn(0)
//	String imageWaveName=sprintf2sv("%s_%d", videoWaveBaseName, iSweep)
//	MoveWave imageWave, $imageWaveName 	// Cage the once-free wave
//	
//	// Calculate ROI signals, store in root DF
//	AddROIWavesToRoot(imageWave,roisWave,iSweep)
//	
//	// Tell the image browser controller to show the newly-acquired video
//	ImageBrowserContSetVideo(imageWaveName)
//	
//	// If video acquisition is free-running, notify the Sweeper that free-running video was just acquired.
//	// This updates the next sweep index.  We don't need to do this for triggered video b/c the call to
//	// SweeperControllerAcquireTrial()
//	if (!isTriggered)
//		SweeperFreeRunVideoJustAcqd(iSweep)
//	endif
//	SweeperViewSweeperChanged()
//	
//	// Update the sweep number and signals in the DP Browsers
//	Wave browserNumbers=GetAllBrowserNumbers()  // returns a free wave	
//	Variable nBrowsers=numpnts(browserNumbers)
//	Variable i
//	for (i=0; i<nBrowsers; i+=1)
//		BrowserContSetCurSweepIndex(browserNumbers[i],iSweep)
//	endfor
//	
//	// Tell that model that we're done acquiring video, and update the view to reflect
//	ImagerSetIsAcquiringVideo(0)
//	ImagerViewModelChanged()
//	
//	// Make everything update itself
//	DoUpdate	
	
	// Restore the data folder
	SetDataFolder savedDF	
	
	// Return the sweep index
	return iSweep
End



Function ImagerContAcquireFinish(iSweep)
	Variable iSweep

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the instance vars
	WAVE roisWave
	NVAR videoExposure
	NVAR ccdTargetTemperature	
	NVAR binWidth
	NVAR binHeight
	SVAR videoWaveBaseName
	NVAR nFramesForVideo
	NVAR isTriggered
	
//	// Do stuff
//	Variable iSweep=SweeperGetNextSweepIndex()
//	ImagerSetIsAcquiringVideo(1)
//	ImagerViewModelChanged()
//	DoUpdate	
//	FancyCameraSetupVideoAcq(binWidth,binHeight,roisWave,isTriggered,videoExposure,ccdTargetTemperature)
//	EpiLightSetIsOn(1)
//	
//	//Wave imageWave=FancyCameraArmAcquireDisarm(nFramesForVideo)		// This will call SweeperControllerAcquireTrial() if in triggered mode
//	FancyCameraArm(nFramesForVideo)
//	//Wave imageWave=FancyCameraAcquire(nFrames)		// This will call SweeperControllerAcquireTrial() if in triggered mode
//	FancyCameraStartAcquire()
	Wave imageWave=FancyCameraWaitForFrames(nFramesForVideo)
	FancyCameraDisarm()
	
	EpiLightSetIsOn(0)
	String imageWaveName=sprintf2sv("%s_%d", videoWaveBaseName, iSweep)
	MoveWave imageWave, $imageWaveName 	// Cage the once-free wave
	
	// Calculate ROI signals, store in root DF
	AddROIWavesToRoot(imageWave,roisWave,iSweep)
	
	// Tell the image browser controller to show the newly-acquired video
	ImageBrowserContSetVideo(imageWaveName)
	
	// If video acquisition is free-running, notify the Sweeper that free-running video was just acquired.
	// This updates the next sweep index.  We don't need to do this for triggered video b/c the call to
	// SweeperControllerAcquireTrial()
	if (!isTriggered)
		SweeperFreeRunVideoJustAcqd(iSweep)
	endif
	SweeperViewSweeperChanged()
	
	// Update the sweep number and signals in the DP Browsers
	Wave browserNumbers=GetAllBrowserNumbers()  // returns a free wave	
	Variable nBrowsers=numpnts(browserNumbers)
	Variable i
	for (i=0; i<nBrowsers; i+=1)
		BrowserContSetCurSweepIndex(browserNumbers[i],iSweep)
	endfor
	
	// Tell that model that we're done acquiring video, and update the view to reflect
	ImagerSetIsAcquiringVideo(0)
	ImagerViewModelChanged()
	
	// Make everything update itself
	//DoUpdate	
	
	// Restore the data folder
	SetDataFolder savedDF	
End







Function ImagerContFocus()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the object vars
	SVAR snapshotWaveBaseName
	//NVAR iFocusWave
	//NVAR iFullFrameWave
	WAVE roisWave
	NVAR snapshotExposure
	NVAR ccdTargetTemperature

	// Do stuff
	//Variable isBinnedAndROIed=0
	//Variable binWidth=1
	//Variable binHeight=1

	ImagerSetIsFocusing(1)
	ImagerViewModelChanged()
	DoUpdate

	//Variable isImagingTriggered=0			// set to one for triggered images
	//FancyCameraSetupAcquisition(isBinnedAndROIed,roisWave,isImagingTriggered,snapshotExposure,ccdTargetTemperature,binWidth,binHeight)
	FancyCameraSetupSnapshotAcq(snapshotExposure,ccdTargetTemperature)

	Variable iFullFrameWave=SweeperGetNextSweepIndex()
	String imageWaveNameRel=sprintf2sv("%s_%d", snapshotWaveBaseName, iFullFrameWave)
	String imageWaveNameAbs=sprintf1s("root:DP_Imager:%s",imageWaveNameRel)	
	EpiLightSetIsOn(1)
	Variable	nFrames=1	
	FancyCameraArm(nFrames)
	Variable iFrame=0
	do
		// Start a sequence of images. In the current case, there is 
		// only one frame in the sequence.
		//Wave imageWaveFree=FancyCameraAcquire(nFrames)
		FancyCameraStartAcquire()
		Wave imageWaveFree=FancyCameraWaitForFrames(nFrames)
		if (iFrame==0)
			MoveWave imageWaveFree, $imageWaveNameAbs 	// Cage the once-free wave
			Wave imageWaveCaged= $imageWaveNameAbs
			ImageBrowserContSetVideo(imageWaveNameRel)
			DoUpdate
		else
			// replace the wave data with the new data
			imageWaveCaged=imageWaveFree[p][q]
			DoUpdate
		endif
		iFrame+=1
		printf "."
		DoUpdate
	while (!EscapeKeyWasPressed())	
	EpiLightSetIsOn(0)
	ImagerSetIsFocusing(0)
	ImagerViewModelChanged()
	DoUpdate
	FancyCameraDisarm()	
		
	SweeperFreeRunVideoJustAcqd(iFullFrameWave)
	SweeperViewSweeperChanged()

	// Call this to make sure the image gets auto-scaled properly if needed
	ImageBrowserModelSetVideo(imageWaveNameRel)
	ImageBrowserViewModelEtcChanged()	

	// Restore the data folder
	SetDataFolder savedDF
End



Function ImagerContAcquireSnapshot()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the object vars
	SVAR snapshotWaveBaseName
	SVAR videoWaveBaseName
	WAVE roisWave
	NVAR snapshotExposure
	NVAR ccdTargetTemperature
	
	// Do stuff
	FancyCameraSetupSnapshotAcq(snapshotExposure,ccdTargetTemperature)
	EpiLightSetIsOn(1)
	Variable nFrames=1
	//Wave imageWave=FancyCameraArmAcquireDisarm(nFrames)
	FancyCameraArm(nFrames)
	FancyCameraStartAcquire()
	Wave imageWave=FancyCameraWaitForFrames(nFrames)
	FancyCameraDisarm()
	
	EpiLightSetIsOn(0)
	Variable iFullFrameWave=SweeperGetNextSweepIndex()
	String imageWaveName=sprintf2sv("%s_%d", snapshotWaveBaseName, iFullFrameWave)
	if (WaveExists($imageWaveName))
		 KillWaves $imageWaveName
	endif
	MoveWave imageWave, root:DP_Imager:$imageWaveName 	// Cage the once-free wave
	ImageBrowserContSetVideo(imageWaveName) 
	String allVideoWaveNames=WaveList(snapshotWaveBaseName+"*",";","")+WaveList(videoWaveBaseName+"*",";","")
	SweeperFreeRunVideoJustAcqd(iFullFrameWave)
	SweeperViewSweeperChanged()

	// Restore the data folder
	SetDataFolder savedDF
End



