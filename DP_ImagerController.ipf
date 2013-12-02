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


Function ImagerContSetupAndAcquireVideo(isTriggered)
	Variable isTriggered

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the instance vars
	//SVAR focusWaveBaseName
	//NVAR iFocusWave
	//NVAR iFullFrameWave
	NVAR isROI
	NVAR isBackgroundROIToo
	//SVAR videoWaveBaseName
	WAVE roisWave
	NVAR videoExposure
	NVAR ccdTargetTemperature	
	NVAR binWidth
	NVAR binHeight
	
	FancyCameraSetupAcquisition(isROI,isBackgroundROIToo,roisWave,isTriggered,videoExposure,ccdTargetTemperature,binWidth,binHeight)
	EpiLightSetIsOn(1)
	ImagerContAcquireVideo()
	EpiLightSetIsOn(0)
	// These next two lines may need to come back in some form, but I'm not really clear on what they do
	//Get_DFoverF_from_Stack(previouswave)
	//Append_DFoverF(previouswave)
	//printf "%s%d: Image with EPhys done\r", videoWaveBaseName, previouswave
	
	// Restore the data folder
	SetDataFolder savedDF	
End

Function ImagerContFocus()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the object vars
	SVAR fullFrameWaveBaseName
	//NVAR iFocusWave
	//NVAR iFullFrameWave
	WAVE roisWave
	NVAR snapshotExposure
	NVAR ccdTargetTemperature

	Variable isROI=0
	Variable isBackgroundROIToo=0
	Variable binWidth=1
	Variable binHeight=1

	ImagerViewSetIsProTipShowing(1)
	DoUpdate

	//Variable status, canceled
	//String message
	//Variable frames_per_sequence, frames
	//String wave_image
	Variable iFullFrameWave=SweeperGetNextSweepIndex()
	String wave_image=sprintf2sv("%s_%d", fullFrameWaveBaseName, iFullFrameWave)
	Variable frames_per_sequence=1
	Variable frames=1
	Variable isImagingTriggered=0			// set to one for triggered images
	FancyCameraSetupAcquisition(isROI,isBackgroundROIToo,roisWave,isImagingTriggered,snapshotExposure,ccdTargetTemperature,binWidth,binHeight)
	//printf "Focusing (press Esc key to stop) ..."
	EpiLightSetIsOn(1)
	Sleep /S 0.1
	//ImagerFocus()

	String imageWaveNameRel=sprintf2sv("%s_%d", fullFrameWaveBaseName, iFullFrameWave)
	String imageWaveNameAbs=sprintf1s("root:DP_Imager:%s",imageWaveNameRel)
	
	Variable	nFrames=1
	//Variable isTriggered=0		// Just want the camera to free-run
	
	ImagerViewSetIsProTipShowing(1)
	DoUpdate
	FancyCameraArm(nFrames)
	Variable iFrame=0
	do
		// Start a sequence of images. In the current case, there is 
		// only one frame in the sequence.
		//Wave imageWave=FancyCameraAcquire(nFrames, isTriggered)
		Wave imageWaveFree=FancyCameraAcquire(nFrames)
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
	ImagerViewSetIsProTipShowing(0)
	DoUpdate
	FancyCameraDisarm()	
		
	EpiLightSetIsOn(0)
	SweeperIncrementNextSweepIndex()
	SweeperViewSweeperChanged()
	//iFullFrameWave+=1
	//iFocusWave=iFullFrameWave
	//printf "%s: Focus Image done\r", wave_image

	// Call this to make sure the image gets auto-scaled properly if needed
	ImageBrowserModelSetVideo(imageWaveNameRel)
	ImageBrowserViewModelEtcChanged()	

	// Restore the data folder
	SetDataFolder savedDF
End

Function ImagerContAcquireFullFrameImage()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the object vars
	SVAR fullFrameWaveBaseName
	NVAR isTriggered
	//NVAR iFullFrameWave
	//SVAR allVideoWaveNames
	SVAR videoWaveBaseName
	WAVE roisWave
	NVAR snapshotExposure
	NVAR ccdTargetTemperature
	
	Variable binWidth=1
	Variable binHeight=1
	Variable status, canceled
	String message
	//String imageWaveName
	Variable frames
	Variable iFullFrameWave=SweeperGetNextSweepIndex()
	String imageWaveName=sprintf2sv("%s_%d", fullFrameWaveBaseName, iFullFrameWave)
	//Variable image_roi=0		// means there is no ROI
	Variable isROI=0
	Variable isBackgroundROIToo=0	// Irrelevant
	frames=1
	isTriggered=0		// set to one for triggered images
	binWidth=1; binHeight=1
	FancyCameraSetupAcquisition(isROI,isBackgroundROIToo,roisWave,isTriggered,snapshotExposure,ccdTargetTemperature,binWidth,binHeight) 
	EpiLightSetIsOn(1)
	//Sleep /S 0.1
	//Make /O /N=(512,512) $imageWaveName
	//Wave w=$imageWaveName
	//w=100+gnoise(10)
	Wave imageWave=FancyCameraArmAcquireDisarm(frames)
	if (WaveExists($imageWaveName))
		 KillWaves $imageWaveName
	endif
	MoveWave imageWave, root:DP_Imager:$imageWaveName 	// Cage the once-free wave
	EpiLightSetIsOn(0)
	ImageBrowserContSetVideo(imageWaveName) 
	//printf "%s%d: Full Image done\r", fullFrameWaveBaseName, iFullFrameWave
	String allVideoWaveNames=WaveList(fullFrameWaveBaseName+"*",";","")+WaveList(videoWaveBaseName+"*",";","")
	SweeperIncrementNextSweepIndex()
	SweeperViewSweeperChanged()
	//iFullFrameWave+=1
	//iFocusWave=iFullFrameWave

	// Restore the data folder
	SetDataFolder savedDF
End

Function ImagerContAcquireVideo()
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// instance vars
	SVAR videoWaveBaseName
	NVAR nFramesForVideo
	
	Variable status, exposure, canceled
	String message
	String imageWaveName, datawavename
	Variable frames_per_sequence, frames
	Variable iSweep=SweeperGetNextSweepIndex()
	sprintf imageWaveName, "%s_%d", videoWaveBaseName, iSweep
	frames_per_sequence=nFramesForVideo
	frames=nFramesForVideo
	EpiLightSetIsOn(1)
	Sleep /S 0.1
	Wave imageWave=FancyCameraArmAcquireDisarm(frames)	// trigger mode is now set during camera setup
	MoveWave imageWave, $imageWaveName 	// Cage the once-free wave
	EpiLightSetIsOn(0)
	ImageBrowserContSetVideo(imageWaveName)
	//	might want to add code to make an empty data wave if the image stack is taken on its own
	
	// Restore the original DF
	SetDataFolder savedDF
End

//------------------------------------- START OF BUTTON AND SETVAR PROCEDURES  ----------------------------------------------//

Function AppendDFFButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	//String command
	NVAR previouswave
	Get_DFoverF_from_Stack(previouswave)
	Append_DFoverF(previouswave)
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function ResetAvgButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	NVAR nFramesInAverage
	WAVE dff_avg
	
	dff_avg=0
	nFramesInAverage=0
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function SetCCDTempVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	FancyCameraSetTemperature(varNum)
	
	// Restore the original DF
	SetDataFolder savedDF
End

//Function ImagerContTakeVideoButtPressed(ctrlName) : ButtonControl
//	String ctrlName
//
//	// Switch to the imaging data folder
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:DP_Imager
//
//	Variable isTriggered=0
//	ImagerContSetupAndAcquireVideo(isTriggered)
//	
//	// Restore the original DF
//	SetDataFolder savedDF
//End

Function FullButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	ImagerContAcquireFullFrameImage()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function FocusButtonProc(ctrlName) : ButtonControl
	String ctrlName

	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	ImagerContFocus()
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function ICTakeVideoButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	Variable isTriggered=0
	ImagerContSetupAndAcquireVideo(isTriggered)
End

Function ImagerContIsTriggeredCB(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	ImagerSetIsTriggered(checked)
	ImagerViewModelChanged()
End


//--------------------------------------- END OF BUTTON AND SETVAR PROCEDURES---------------------------------------//




//______________________DataPro Imaging PROCEDURES__________________________//


Function ImagerContEpiLightToggle(ctrlName) : ButtonControl
	String ctrlName
	
	EpiLightSetIsOn(~EpiLightGetIsOn())
	ImagerViewEpiLightChanged()
End

//Function FluOFFButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//	EpiLightSetIsOn(0)
//End

Function ImagingCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	NVAR imaging=imaging
	Execute "VDTGetPortList"
	SVAR port=S_VDT
	if (checked>0)
		imaging=1
		SetVDTPort("COM1")
	else
		imaging=0
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End






//Function ImagerFocus()
//	// Do a live view of the CCD, to enable focusing, etc.
//
//	// Change to the imaging data folder
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:DP_Imager
//	
//	// instance vars
//	SVAR fullFrameWaveBaseName
//	NVAR iFocusWave
//	//NVAR blackCount, whiteCount
//
//	String imageWaveNameRel=sprintf2sv("%s%d", fullFrameWaveBaseName, iFocusWave)
//	String imageWaveNameAbs=sprintf1s("root:DP_Imager:%s",imageWaveNameRel)
//	
//	Variable	nFrames=1
//	//Variable isTriggered=0		// Just want the camera to free-run
//	
//	ImagerViewSetIsProTipShowing(1)
//	DoUpdate
//	FancyCameraArm(nFrames)
//	Variable iFrame=0
//	do
//		// Start a sequence of images. In the current case, there is 
//		// only one frame in the sequence.
//		//Wave imageWave=FancyCameraAcquire(nFrames, isTriggered)
//		Wave imageWaveFree=FancyCameraAcquire(nFrames)
//		if (iFrame==0)
//			MoveWave imageWaveFree, $imageWaveNameAbs 	// Cage the once-free wave
//			Wave imageWaveCaged= $imageWaveNameAbs
//			ImageBrowserContSetVideo(imageWaveNameRel)
//			DoUpdate
//		else
//			// replace the wave data with the new data
//			imageWaveCaged=imageWaveFree[p][q]
//			DoUpdate
//		endif
////		if (iFrame==0)
////			ImageBrowserContSetVideo(imageWaveName)
////		else
////			if (iFrame==1)
////				ModifyImage $imageWaveName ctab= {blackCount,whiteCount,Grays,0}
////			endif
////			ControlInfo autoscaleToDataCB
////			if (V_Value>0)
////				AutoGrayScaleButtonProc("scaleButton")
////			endif
////		endif
//		iFrame+=1
//		printf "."
//		DoUpdate
//	while (!EscapeKeyWasPressed())	
//	ImagerViewSetIsProTipShowing(0)
//	DoUpdate
//	FancyCameraDisarm()	
//	
//	// Restore the original DF
//	SetDataFolder savedDF
//End






Function Get_DFoverF_from_Stack(iVideoWave)
	Variable iVideoWave
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// instance vars
	SVAR videoWaveBaseName
	NVAR videoExposure
	
	Variable numBase=16		// number of frames to use for calculation of baseline fluorescence?
	String videoWaveName=sprintf2sv("%s_%d",videoWaveBaseName, iVideoWave)
	String dffVideoWaveName=sprintf1v("dff_%d", iVideoWave)
	//sprintf stackWaveName, "%s%d", videoWaveBaseName, iVideoWave
	//sprintf dffVideoWaveName, "dff_%d", iVideoWave
	//print stackWaveName, dffVideoWaveName
	DeletePoints /M=2 0,1, $videoWaveName		// kill the first plane of $videoWaveName
//	Duplicate /O $stack $newimage
	Make /O /N=(numpnts($videoWaveName)) $dffVideoWaveName
	Wave dffVideoWave=$dffVideoWaveName
	Wave stackWave=$videoWaveName
	Variable fSummed=0
	Variable i=0
	for (i=0; i<numBase; i+=1)
		fSummed+=stackWave[i]
		i+=1
	endfor
	Variable fBaseline=fSummed/numBase
	dffVideoWave=100*(fBaseline-stackWave)/fBaseline		// inverted, presumably makes sense for original fluorophore
	SetScale /P x 0,videoExposure,"ms", dffVideoWave
	
	// Restore the original DF
	SetDataFolder savedDF
End







Function Append_DFoverF(iVideoWave)
	Variable iVideoWave
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// instance vars
	NVAR nFramesInAverage
	WAVE dff_avg
	
//	String stack
	String newImageWaveName=sprintf1v("dff_%d", iVideoWave)
//	sprintf stack, "stack_%d", iVideoWave
	//sprintf newImageWaveName, "dff_%d", iVideoWave
	//PauseUpdate
	AppendToGraph $newImageWaveName
	DoWindow /F ImagerView
	ControlInfo showimageavg_check0
	if (V_value>0)
		if (nFramesInAverage==0)
			Duplicate /O $newImageWaveName dff_avg
			nFramesInAverage+=1
		else
			dff_avg*=nFramesInAverage
			WAVE newImageWave=$newImageWaveName
			dff_avg+=newImageWave
			nFramesInAverage+=1
			dff_avg/=nFramesInAverage
			AppendToGraph dff_avg
		endif
	endif
	ModifyGraph rgb($newImageWaveName)=(0,0,0)
	ModifyGraph lsize($newImageWaveName)=1.5
	ModifyGraph mode($newImageWaveName)=6
	ModifyGraph marker($newImageWaveName)=19
//	print nFramesInAverage
	if (nFramesInAverage>1)
		ModifyGraph lsize(dff_avg)=1.5,rgb(dff_avg)=(0,52224,0)
		ModifyGraph offset(dff_avg)={50,0}
	endif
	Variable leftmin, leftmax
	leftmin=0
	leftmax=0
	// Commented this out because I'm not sure what thiswave is supposed to refer to.
	// I'll fix this once I understand the code better. --ALT
	//Wavestats /Q $thiswave
	//leftmin=V_min
	//leftmax=V_max
	Wavestats /Q $newImageWaveName
	if (V_min<leftmin)
		leftmin=V_min
	endif
	if (V_max>leftmax)
		leftmax=V_max
	endif
	Setaxis left, leftmin, leftmax
	
	// Restore the original DF
	SetDataFolder savedDF
End






Function SetROIProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// instance vars
	NVAR iROI
	WAVE roisWave

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
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function ImagerContiROISVTwiddled(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct
	
	// If control is being killed, do nothing
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	

	// Need a better name for the thing set
	Variable iROIPlusOne=svStruct.dval
	
	// Switch to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager
	
	// decare instance vars
	NVAR iROI
	
	// do stuff
	iROI=iROIPlusOne-1
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
	
	// Restore the original DF
	SetDataFolder savedDF
End



