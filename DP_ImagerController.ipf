//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

static constant moveSize=5	// pixels in the full-CCD frame
static constant nudgeSize=1	// pixels in the full-CCD frame

Function ImagerContConstructor()
	ImagerConstructor()
	ImagerSetIsAcquiringVideo(0)	
		// If something got borked during acquire, and the user had to delete the old window and get a new one, 
		// this makes sure the view doesn't look like video is being acquired
	ImagerViewConstructor()
	
	// Update the CCD temp to get a value up there
	//ICUpdateTemp()
End


//Function ImagerContDestructor()
//	CtrlNamedBackground ICUpdateTempInBackgroundTask, stop
//End


//
//  Front-line functions for handling user actions
//

Function ICTempSetpointSVTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	//FancyCameraSetTempAndWait(varNum)
	FancyCameraSetTargetTemp(varNum)
	ImagerViewSomethingChanged()
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
	SweeperViewSweeperChanged()
	TestPulserViewSweeperChanged()
	OutputViewerContSweprWavsChngd()
End



Function ICEpiTTLChannelSVTouched(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	EpiLightSetTTLOutputIndex(varNum)
	//SweeperEpiLightTTLOutputChanged()
	SamplerEpiLightTTLOutputChanged()
	ImagerViewEpiLightChanged()	
	SweeperViewEpiLightChanged()
	TestPulserViewSomethingChanged()
End



Function ICEpiLightToggleButtonPressed(ctrlName) : ButtonControl
	String ctrlName
	
	//EpiLightSetIsOn(!EpiLightGetIsOn())
	EpiLightToggle()
	//SweeperEpiLightOnChanged()
	ImagerViewEpiLightChanged()
	//OutputViewerContSweprWavsChngd()
End



Function ICEpiTriggeredDelaySVTouched(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	EpiLightSetTriggeredDelay(varNum)
	ImagerViewEpiLightChanged()
	OutputViewerViewUpdate()
End
	


Function ICEpiTriggeredDurationSVTouched(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	EpiLightSetTriggeredDuration(varNum)
	ImagerViewEpiLightChanged()
	OutputViewerViewUpdate()
End



Function ICROISVTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
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
	endif
	ImagerViewModelChanged()
	ImageBrowserModelImagerChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICBinSizePMTouched(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	
	ImagerSetBinSizeIndex(popNum-1)
	ImagerViewModelChanged()
	SweeperViewImagerChanged()
End



Function ICCurrentROIIndexSVTwiddled(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct
	
	// If control is being killed, do nothing
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	

	// Do stuff
	Variable iROINew=svStruct.dval
	ImagerSetCurrentROIIndex(iROINew)
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



Function ICCalculationPMTouched(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	Variable iChannel
	
	ImagerSetCalculationIndex(popNum-1)
	ImagerViewModelChanged()
End



Function ICBackgroundCBTouched(ctrlName,isChecked) : CheckBoxControl
	String ctrlName
	Variable isChecked
	ImagerSetCurrentROIIsBackground(isChecked)
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICNudgeUpButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	ImagerTranslateCurrentROIOrAll(0,-nudgeSize)
	ImageBrowserModelImagerChanged()
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICMoveUpButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	ImagerTranslateCurrentROIOrAll(0,-moveSize)
	ImageBrowserModelImagerChanged()
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICNudgeDownButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	ImagerTranslateCurrentROIOrAll(0,+nudgeSize)
	ImageBrowserModelImagerChanged()
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICMoveDownButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	ImagerTranslateCurrentROIOrAll(0,+moveSize)
	ImageBrowserModelImagerChanged()
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICNudgeLeftButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	ImagerTranslateCurrentROIOrAll(-nudgeSize,0)
	ImageBrowserModelImagerChanged()
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICMoveLeftButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	ImagerTranslateCurrentROIOrAll(-moveSize,0)
	ImageBrowserModelImagerChanged()
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICNudgeRightButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	ImagerTranslateCurrentROIOrAll(+nudgeSize,0)
	ImageBrowserModelImagerChanged()
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICMoveRightButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	ImagerTranslateCurrentROIOrAll(+moveSize,0)
	ImageBrowserModelImagerChanged()
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End



Function ICMoveAllCBTouched(ctrlName,isChecked) : CheckBoxControl
	String ctrlName
	Variable isChecked

	ImagerSetMoveAllROIs(isChecked)
	ImagerViewModelChanged()
End

Function ICUpdateTempButtonPressed(ctrlName) : ButtonControl
	String ctrlName
	ImagerViewUpdateCCDTemp()	
End

Function ICVideoExposureSVTouched(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

	ImagerSetVideoExposureWanted(varNum)
	ImagerViewModelChanged()
	SweeperViewImagerChanged()
End

Function ICUpdateVideoExpButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	ImagerUpdateVideoParams()
	ImagerViewModelChanged()
	SweeperViewImagerChanged()
End

Function ICSnapshotExposureSVTouched(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

	ImagerSetSnapshotExposureWanted(varNum)
	ImagerViewModelChanged()
End

Function ICUpdateSnapExpButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	ImagerUpdateSnapshotParams()
	ImagerViewModelChanged()
End

Function ICNFramesForVideoSVTouched(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

	ImagerSetNFramesForVideo(varNum)
	ImagerViewModelChanged()
	SweeperViewImagerChanged()
End

Function ICNBaselineFramesSVTouched(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

	ImagerSetNBaselineFrames(varNum)
	ImagerViewModelChanged()
End

Function ICTriggerTTLChannelSVTouched(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

	ImagerSetTriggerTTLOutputIndex(varNum)
	ImagerViewModelChanged()
	SweeperViewSweeperChanged()
	TestPulserViewSweeperChanged()
End

Function ICTriggerDelaySVTouched(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

	ImagerSetTriggerDelay(varNum)
	ImagerViewModelChanged()
	OutputViewerViewUpdate()
	SweeperViewImagerChanged()	
End

Function ICExposureADCSVTouched(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

	ImagerSetExposureADCIndex(varNum)
	ImagerViewModelChanged()
	SweeperViewSweeperChanged()
	TestPulserViewSweeperChanged()
End

Function ICDisarmCameraButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	FancyCameraDisarm()
	ImagerSetIsAcquiringVideo(0)
	EpiLightTurnOff()
	ImagerViewSomethingChanged()
End

Function ICResetCameraButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	ImagerDisableCameraReset()
	ImagerViewModelChanged()
	DoUpdate
	FancyCameraReset()
	ImagerEnableCameraReset()
	ImagerViewSomethingChanged()
End



//
// The routines that do substantial stuff are below
//

//Function ICUpdateTemp()
//	ImagerUpdateCCDTemperature()	
//	ImagerViewCCDTempChanged()
//End



Function ImagerContAcquireVideo()
	Variable iSweep=SweeperGetNextSweepIndex()
	Variable wasVideoAcqStarted=ImagerContAcquireVideoStart()
	if (wasVideoAcqStarted)
		ImagerContAcquireFramesLoop(iSweep)
		ImagerContExtractROIs(iSweep)
	else
		Abort FancyCameraGetErrorMessage()
	endif
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
	//NVAR ccdTargetTemperature	
	//NVAR binSizeIndex
	//WAVE binSizeList
	SVAR videoWaveBaseName
	NVAR nFramesForVideo
	NVAR isTriggered
	
	// Unpack the bin width, bin height
	Variable binSize=ImagerGetBinSize()
	//Variable binHeight=ImagerGetBinHeight()
	
	// Do stuff
	//Variable iSweep=SweeperGetNextSweepIndex()
	FancyCameraSetupVideoAcq(binSize,roisWave,isTriggered,videoExposure)
	Variable wasVideoAcqStarted
	Variable isCameraArmed=FancyCameraArm(nFramesForVideo)
	if (isCameraArmed)
		ImagerSetIsAcquiringVideo(1)
		if (isTriggered)
			EpiLightTurnAgnostic()
		else
			EpiLightTurnOn()
		endif
		//SweeperEpiLightOnChanged()
		ImagerViewSomethingChanged()
		DoUpdate	
		wasVideoAcqStarted=FancyCameraStartAcquire()
		if (!wasVideoAcqStarted)
			// Do this if the acquire failed to start
			//EpiLightResetToPermanent()
			EpiLightTurnOff()
			//SweeperEpiLightOnChanged()		
			ImagerSetIsAcquiringVideo(0)
			ImagerViewSomethingChanged()
		endif
	else
		wasVideoAcqStarted=0
	endif
	
	// Restore the data folder
	SetDataFolder savedDF	
	
	// Return the sweep index
	return wasVideoAcqStarted
End



Function ImagerContAcquireFramesLoop(iSweep)
	Variable iSweep

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the instance vars
	WAVE roisWave
	WAVE isBackgroundROI
	NVAR videoExposure
	//NVAR ccdTargetTemperature	
	//NVAR binSize
	//NVAR binHeight
	SVAR videoWaveBaseName
	NVAR nFramesForVideo
	NVAR isTriggered
	
	// Get the video wave
	String imageWaveName=sprintf2sv("%s_%d", videoWaveBaseName, iSweep)
	Make /O /W /U /N=(0,0,0) $imageWaveName	// 16-bit unsigned wave to hold result
	WAVE imageWave=$imageWaveName
	Variable gotFrames=FancyCameraLoopForFramesBang(imageWave,nFramesForVideo)
	
	// Get the error message now
	String errorMessage
	if (!gotFrames)	
		errorMessage=FancyCameraGetErrorMessage()
	endif

	// Let the camera relax
	FancyCameraDisarm()
	
	// Turn off illumination
	//EpiLightResetToPermanent()
	if (!isTriggered)
		EpiLightTurnOff()
	endif
	//SweeperEpiLightOnChanged()

	// If there was a problem getting frames, delete the wave and abort
	if (!gotFrames)	
		ImagerSetIsAcquiringVideo(0)
		// See changes immediately
		ImagerViewModelChanged()	
		DoUpdate
		KillWaves /Z $imageWaveName
		if (IsEmptyString(errorMessage))
			errorMessage="Unable to acquire frames"
		endif
		Abort errorMessage
	endif
		
	// Tell the image browser controller to show the newly-acquired video
	ImageBrowserContSetVideo(imageWaveName)
		
	// Tell that model that we're done acquiring video, and update the view to reflect
	ImagerSetIsAcquiringVideo(0)
	ImagerViewModelChanged()
	
	// Make everything update itself
	//DoUpdate	
	
	// Restore the data folder
	SetDataFolder savedDF	
End







Function ImagerContExtractROIs(iSweep)
	Variable iSweep

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the instance vars
	WAVE roisWave
	WAVE isBackgroundROI
	NVAR videoExposure
	//NVAR ccdTargetTemperature	
	//NVAR binSize
	//NVAR binHeight
	SVAR videoWaveBaseName
	NVAR nFramesForVideo
	NVAR isTriggered
	
	// Get the video wave
	String imageWaveName=sprintf2sv("%s_%d", videoWaveBaseName, iSweep)
//	Make /O /W /U /N=(0,0,0) $imageWaveName	// 16-bit unsigned wave to hold result
//	WAVE imageWave=$imageWaveName
//	Variable gotFrames=FancyCameraLoopForFramesBang(imageWave,nFramesForVideo)
	
//	// Get the error message now
//	String errorMessage
//	if (!gotFrames)	
//		errorMessage=FancyCameraGetErrorMessage()
//	endif

//	// Let the camera relax
//	FancyCameraDisarm()
//	
//	// Turn off illumination
//	//EpiLightResetToPermanent()
//	EpiLightTurnOff()
//	//SweeperEpiLightOnChanged()
//
//	// If there was a problem getting frames, delete the wave and abort
//	if (!gotFrames)	
//		ImagerSetIsAcquiringVideo(0)
//		// See changes immediately
//		ImagerViewModelChanged()	
//		DoUpdate
//		KillWaves /Z $imageWaveName
//		if (IsEmptyString(errorMessage))
//			errorMessage="Unable to acquire frames"
//		endif
//		Abort errorMessage
//	endif
	
	// Copy the free wave to a caged wave in the DP_Imager DF
	//String imageWaveName=sprintf2sv("%s_%d", videoWaveBaseName, iSweep)
	//MoveWave imageWaveFree, $imageWaveName 	// Cage the once-free wave
	
	// If is triggered, use the exposure signal to get more accurate frame offset and interval
	if (isTriggered)
		// Determine the time of each from from the exposure signal
		String exposureWaveNameAbs=sprintf1v("root:exposure_%d",iSweep)
		WAVE exposureWave=$exposureWaveNameAbs
		WAVE offsetEtc=offsetAndIntervalFromExposure(exposureWave,nFramesForVideo)
		if ( numpnts(offsetEtc)<4 )
			// This signals a problem with the exposure signal
			DoAlert /T="Warning" 0, "There is a problem with the exposure signal.  Unable to guarantee frame times are properly synchronized with other data."
		else
			// The exposure signal appears to be good
			Variable frameOffset=offsetEtc[0]
			Variable frameInterval=offsetEtc[1]
			Variable frameIntervalMin=offsetEtc[2]
			Variable frameIntervalMax=offsetEtc[3]
			Variable variability=(frameIntervalMax-frameIntervalMin)/frameInterval
			if (variability>0.01)
				DoAlert /T="Warning" 0, sprintf1v("The frame intervals are highly variable ((max-min)/mean = %0.2f%%)",100*variability)
			endif
			SetScale /P z, frameOffset, frameInterval, "ms", $imageWaveName
		endif
	endif
	
	// Calculate ROI signals, store in root DF
	String calculationName=ImagerGetCalculationName()
	Variable nBaselineFrames=ImagerGetNBaselineFrames()
	AddROIWavesToRoot($imageWaveName,roisWave,iSweep,calculationName,nBaselineFrames,isBackgroundROI)
	
//	// Tell the image browser controller to show the newly-acquired video
//	ImageBrowserContSetVideo(imageWaveName)
	
	// If video acquisition is free-running, notify the Sweeper that free-running video was just acquired.
	// This updates the next sweep index.  We don't need to do this for triggered video b/c the call to
	// SweeperControllerAcquireTrial()
	if (!isTriggered)
		SweeperFreeRunVideoJustAcqd(iSweep)
	endif
	SweeperViewSweeperChanged()
	
	// Update the sweep number and signals in the DP Browsers
	BCSetCurSweepIndexForAll(iSweep)
	
//	// Tell that model that we're done acquiring video, and update the view to reflect
//	ImagerSetIsAcquiringVideo(0)
//	ImagerViewModelChanged()
//	
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
	//NVAR ccdTargetTemperature

	// Do stuff
	//Variable isBinnedAndROIed=0
	//Variable binSize=1
	//Variable binHeight=1

	ImagerSetIsFocusing(1)
	ImagerViewModelChanged()
	DoUpdate

	//Variable isImagingTriggered=0			// set to one for triggered images
	//FancyCameraSetupAcquisition(isBinnedAndROIed,roisWave,isImagingTriggered,snapshotExposure,ccdTargetTemperature,binSize,binHeight)
	FancyCameraSetupSnapshotAcq(snapshotExposure)

	Variable iFullFrameWave=SweeperGetNextSweepIndex()
	String imageWaveNameRel=sprintf2sv("%s_%d", snapshotWaveBaseName, iFullFrameWave)
	String imageWaveNameAbs=sprintf1s("root:DP_Imager:%s",imageWaveNameRel)	
	Make /O /W /U /N=(0,0,0) $imageWaveNameAbs
	WAVE imageWaveCaged= $imageWaveNameAbs
	Variable	nFrames=1	
	Variable isCameraArmed=FancyCameraArm(nFrames)
	if (isCameraArmed)
		//EpiLightSetIsOnTemporary(1)
		EpiLightTurnOn()
		//SweeperEpiLightOnChanged()
		ImagerViewSomethingChanged()
		DoUpdate	
		Variable iFrame=0
		do
			// Start a sequence of images. In the current case, there is 
			// only one frame in the sequence.
			//Wave imageWaveFree=FancyCameraAcquire(nFrames)
			Variable wasAcqStarted=FancyCameraStartAcquire()
			if (wasAcqStarted)
				FancyCameraLoopForFramesBang(imageWaveCaged,nFrames)
				ImageBrowserContSetVideo(imageWaveNameRel)
				if (iFrame==0)
					ImageBrowserContSetVideo(imageWaveNameRel)
				else
					ImageBrowserContNewFocusFrame()
				endif
				iFrame+=1
				//printf "."
				DoUpdate
			else
				// if acquire failed to start
				//EpiLightResetToPermanent()
				EpiLightTurnOff()
				//SweeperEpiLightOnChanged()
				ImagerSetIsFocusing(0)
				ImagerViewSomethingChanged()
				SetDataFolder savedDF
				Abort FancyCameraGetErrorMessage()				
			endif			
		while (!EscapeKeyWasPressed())	
		//EpiLightResetToPermanent()
		EpiLightTurnOff()
		//SweeperEpiLightOnChanged()
		ImagerSetIsFocusing(0)
		ImagerViewSomethingChanged()
		DoUpdate
		FancyCameraDisarm()	
			
		SweeperFreeRunVideoJustAcqd(iFullFrameWave)
		SweeperViewSweeperChanged()
	
		// Update the sweep number and signals in the DP Browsers
		BCSetCurSweepIndexForAll(iFullFrameWave)

		// Call this to make sure the image gets auto-scaled properly if needed
		ImageBrowserModelSetVideo(imageWaveNameRel)
		ImageBrowserViewModelEtcChanged()	
	else
		// If unable to arm camera
		ImagerSetIsFocusing(0)
		ImagerViewModelChanged()
		SetDataFolder savedDF
		Abort FancyCameraGetErrorMessage()
	endif		

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
	//NVAR ccdTargetTemperature
	
	// Do stuff
	FancyCameraSetupSnapshotAcq(snapshotExposure)
	Variable nFrames=1
	Variable isCameraArmed=FancyCameraArm(nFrames)	// this takes a while the first time you do it, so...
	if (isCameraArmed)	
		//EpiLightSetIsOnTemporary(1)	// Don't turn on the light until after the camera has armed successfully
		EpiLightTurnOn()	// Don't mess with the light until after the camera has armed successfully
		ImagerViewSomethingChanged()
		DoUpdate
		//SweeperEpiLightOnChanged()
		//FancyCameraStartAcquire()
		Variable wereFramesAcquired=0
		Variable wasAcqStarted=FancyCameraStartAcquire()
		if (wasAcqStarted)
			Variable iFullFrameWave=SweeperGetNextSweepIndex()
			String imageWaveName=sprintf2sv("%s_%d", snapshotWaveBaseName, iFullFrameWave)
			String imageWaveNameAbs="root:DP_Imager:"+imageWaveName
			Make /O $imageWaveNameAbs
			WAVE imageWave=$imageWaveNameAbs
			wereFramesAcquired=FancyCameraLoopForFramesBang(imageWave,nFrames)
		endif
		FancyCameraDisarm()
		//EpiLightResetToPermanent()
		EpiLightTurnOff()
		ImagerViewSomethingChanged()
		//SweeperEpiLightOnChanged()
		if (wasAcqStarted&&wereFramesAcquired)
			ImageBrowserContSetVideo(imageWaveName) 
			String allVideoWaveNames=WaveList(snapshotWaveBaseName+"*",";","")+WaveList(videoWaveBaseName+"*",";","")
			SweeperFreeRunVideoJustAcqd(iFullFrameWave)
			SweeperViewSweeperChanged()
			// Update the sweep number and signals in the DP Browsers
			BCSetCurSweepIndexForAll(iFullFrameWave)
		else
			// acquire failed to start, or had a problem during, so delete just-created wave
			KillWaves /Z $imageWaveName
			String errorMessage=FancyCameraGetErrorMessage()
			Abort stringFif(IsEmptyString(errorMessage),"Some sort of camera error occured.",errorMessage)		
		endif
	else
		// camera failed to arm
		//EpiLightResetToPermanent()
		EpiLightTurnOff()
		ImagerViewSomethingChanged()
		//SweeperEpiLightOnChanged()
		Abort FancyCameraGetErrorMessage()
	endif			

	// Restore the data folder
	SetDataFolder savedDF
End
