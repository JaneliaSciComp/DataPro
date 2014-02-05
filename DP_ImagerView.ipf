//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function ImagerViewConstructor() : Panel
	// If the view already exists, just raise it
	if (PanelExists("ImagerView"))
		DoWindow /F ImagerView
		return 0
	endif

	// Change to the imaging data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// instance vars
	NVAR iROI

	// This is used in several places
	String absVarName
	
	Variable yOffsetRow
	Variable xOffset=1550
	Variable yOffset=54
	Variable panelWidth=330
	Variable panelHeight=562+21+25
	NewPanel /W=(xOffset,yOffset,xOffset+panelWidth,yOffset+panelHeight)  /N=ImagerView /K=1 as "Imager Controls"
	ModifyPanel /W=ImagerView fixedSize=1

	// Params common to all group boxes
	Variable groupBoxTitleHeight=6
	Variable groupBoxWidth=panelWidth-10
	Variable groupBoxXOffset=(panelWidth-groupBoxWidth)/2
	Variable groupBoxSpaceHeight=8
	
	
	//
	// Illumination Group
	//
	
	Variable groupBoxYOffset=3
	Variable groupBoxHeight=54+24
	GroupBox illuminationGroup,win=ImagerView,pos={groupBoxXOffset,groupBoxYOffset},size={groupBoxWidth,groupBoxHeight},title="Illumination"

	// TTL Output SetVariable		
	xOffset=30
	yOffset=groupBoxYOffset-3+29
	SetVariable ttlOutputChannelSV,win=ImagerView,pos={xOffset,yOffset},size={94,1},limits={0,3,1},title="TTL Output:"
	SetVariable ttlOutputChannelSV,win=ImagerView,proc=ICEpiTTLChannelSVTouched	
	
	// On/Off Button
	Variable width=140	// Size of the button
	Variable height=26
	xOffset=146
	yOffset=groupBoxYOffset-3+23
	Button EpiLightToggleButton,win=ImagerView,pos={xOffset,yOffset},size={width,height},proc=ICEpiLightToggleButtonPressed

	// On/Off ValDisplay
	xOffset=310
	yOffset=groupBoxYOffset-3+29
	ValDisplay EpiLightStatusVD, win=ImagerView, pos={xOffset,yOffset}, size={0,14}, bodyWidth=14, mode=1, limits={0,1,0.5}
	ValDisplay EpiLightStatusVD, win=ImagerView, barmisc={0,0}, highColor=(0,65535,0), lowColor=(0,0,0)
	//ValDisplay ld501_1 title="round LED",size={65,13},bodyWidth=10,mode=1;DelayUpdate
	//ValDisplay ld501_1 barmisc={0,0},limits={-50,100,0}

	// Controls for triggered mode
	yOffsetRow=groupBoxYOffset+54
	xOffset=16
	yOffset=yOffsetRow
	TitleBox epiTriggeredTB, win=ImagerView, pos={xOffset,yOffset+2}, frame=0, title="Triggered:"

	xOffset+=65
	yOffset=yOffsetRow
	SetVariable epiTriggeredDelaySV, win=ImagerView,pos={xOffset,yOffset}, size={90,15}, title="Delay:"
	SetVariable epiTriggeredDelaySV, win=ImagerView, limits={0,inf,10}, proc=ICEpiTriggeredDelaySVTouched
	TitleBox epiTriggeredDelayUnitsTB, win=ImagerView, pos={xOffset+92,yOffset+2}, frame=0, title="ms"

	xOffset+=122
	yOffset=yOffsetRow
	SetVariable epiTriggeredDurationSV, win=ImagerView, pos={xOffset,yOffset}, size={100,15}, title="Duration:"
	SetVariable epiTriggeredDurationSV, win=ImagerView, limits={0.001,inf,0.1}, proc=ICEpiTriggeredDurationSVTouched
	TitleBox epiTriggeredDurationUnitsTB, win=ImagerView, pos={xOffset+102,yOffset+2}, frame=0, title="ms"



	//
	// Temperature Group
	//
	groupBoxYOffset+=groupBoxHeight+groupBoxSpaceHeight
	groupBoxHeight=44
	GroupBox temperatureGroup,win=ImagerView,pos={groupBoxXOffset,groupBoxYOffset},size={groupBoxWidth,groupBoxHeight},title="CCD Temperature"
	
	height=14
	yOffset=groupBoxYOffset+groupBoxTitleHeight+(groupBoxHeight-height)/2
	SetVariable ccdTemperatureSetpointSV,win=ImagerView,pos={30,yOffset},size={96,height},proc=ICTempSetpointSVTwiddled,title="Setpoint:"
	SetVariable ccdTemperatureSetpointSV, win=ImagerView, limits={-50,20,5}, format="%0.1f", value= ccdTargetTemperature

	ValDisplay ccdTemperatureVD,win=ImagerView,pos={154,yOffset+1},size={76,height},title="Current:"
	ValDisplay ccdTemperatureVD,win=ImagerView,format="%0.1f",limits={0,0,0},barmisc={0,1000}

	Variable buttonWidth=70
	Variable buttonHeight=20
	Button updateTempButton,win=ImagerView,pos={240,yOffset-2},size={buttonWidth,buttonHeight},proc=ICUpdateTempButtonPressed,title="Update"


	//
	// Snapshots Group
	//
	groupBoxYOffset+=groupBoxHeight+groupBoxSpaceHeight
	groupBoxHeight=80
	GroupBox fullFrameGroup,win=ImagerView,pos={groupBoxXOffset,groupBoxYOffset},size={groupBoxWidth,groupBoxHeight},title="Snapshots"

	xOffset=16
	Variable buttonSpacerHeight=8
	Variable nButtons=2
	Variable buttonGroupHeight=nButtons*buttonHeight+(nButtons-1)*buttonSpacerHeight
	
	// Snapshot button
	buttonWidth=80
	Variable snapshotYOffset=groupBoxYOffset+groupBoxTitleHeight+(groupBoxHeight-buttonGroupHeight)/2
	yOffset=snapshotYOffset	
	Button snapshotButton,win=ImagerView,pos={xOffset,yOffset},size={buttonWidth,buttonHeight},proc=ICTakeSnapshotButtonPressed,title="Take"

	// Focus button
	Variable focusYOffset=snapshotYOffset+buttonHeight+buttonSpacerHeight
	yOffset=focusYOffset
	Button focusButton,win=ImagerView,pos={xOffset,yOffset},size={buttonWidth,buttonHeight},proc=ICFocusButtonPressed,title="Focus"

	// Snapshot name SV
	SetVariable snapshotNameSV, win=ImagerView, pos={106,snapshotYOffset+2}, size={80,14}, title="Name:"
	SetVariable snapshotNameSV, win=ImagerView, value=snapshotWaveBaseName
	
	// Snapshot exposure SV
	xOffset=200
	yOffset=snapshotYOffset+2
	width=100
	height=14
	SetVariable snapshotExposureWantedSV,win=ImagerView,pos={xOffset,yOffset},size={width,height},title="Exposure:"
	SetVariable snapshotExposureWantedSV,win=ImagerView,limits={0,inf,10}, proc= ICSnapshotExposureSVTouched
	TitleBox snapshotExposureWantedUnitsTB, win=ImagerView,pos={xOffset+width+2,yOffset+2},frame=0,title="ms"

	// Actual snapshot exposure title box parts
	yOffset=snapshotYOffset+22
	xOffset=200
	TitleBox actualSnapshotTB, win=ImagerView, pos={xOffset,yOffset}, frame=0, title="Actual:"
	xOffset=254
	TitleBox actualSnapshotExposureTB, win=ImagerView, pos={xOffset,yOffset}, frame=0
	xOffset=302
	TitleBox actualSnapshotUnitsTB, win=ImagerView, pos={xOffset,yOffset}, frame=0, title="ms"

	// "(hit ESC key to stop)" title box
	TitleBox focusingEscapeTB, win=ImagerView, pos={106,focusYOffset+3}, frame=0, title="(hit ESC to stop)",disable=1


	//
	// Video Group
	//
	groupBoxYOffset+=groupBoxHeight+groupBoxSpaceHeight
	groupBoxHeight=96+21
	GroupBox videoGroup,win=ImagerView,pos={groupBoxXOffset,groupBoxYOffset},size={groupBoxWidth,groupBoxHeight},title="Video"

	// Take video button
	Variable videoYOffset=groupBoxYOffset+groupBoxTitleHeight+15
	xOffset=16
	yOffset=videoYOffset
	width=80
	height=20
	Button takeVideoButton,win=ImagerView,pos={xOffset,yOffset},size={width,height},proc=ICAcquireVideoButtonPressed,title="Acquire"

	// "(hit ESC key to stop)" title box
	TitleBox videoEscapeTB, win=ImagerView, pos={xOffset+1,yOffset+24}, frame=0, title="(hit ESC to stop)"

	// Video name SV
	xOffset=106
	yOffset=videoYOffset+2
	width=80
	height=15
	SetVariable videoNameSV,win=ImagerView,pos={xOffset,yOffset},size={width,height},title="Name:"
	SetVariable videoNameSV,win=ImagerView,value= videoWaveBaseName

	// Video exposure SV
	xOffset=200
	yOffset=videoYOffset+2
	width=100
	height=14
	SetVariable videoExposureWantedSV, win=ImagerView, pos={xOffset,yOffset}, size={width,height}, title="Exposure:"
	SetVariable videoExposureWantedSV, win=ImagerView, limits={0,inf,10}, proc= ICVideoExposureSVTouched
	TitleBox videoExposureUnitsTitleBox,win=ImagerView,pos={xOffset+width+2,yOffset+2},frame=0,title="ms"

	// Bin Size Popup Menu
	xOffset=106
	yOffsetRow=videoYOffset+24
	yOffset=yOffsetRow
	PopupMenu binSizePM, win=ImagerView, pos={xOffset,yOffset}, size={1,22}, proc=ICBinSizePMTouched, title="Bin Size:"
	String binSizeListAsString=ImagerGetBinSizeListAsString()
	Variable binSizeIndex=ImagerGetBinSizeIndex()
	String binSizeListAsStringFU="\""+binSizeListAsString+"\""
	PopupMenu binSizePM, win=ImagerView, value=#binSizeListAsStringFU, mode=binSizeIndex+1

	// Actual exposure title box parts
	yOffset=yOffsetRow-2
	xOffset=200
	TitleBox actualTB, win=ImagerView, pos={xOffset,yOffset}, frame=0, title="Actual:"
	xOffset=254
	TitleBox actualVideoExposureTB, win=ImagerView, pos={xOffset,yOffset}, frame=0
	xOffset=302
	TitleBox actualUnitsTB, win=ImagerView, pos={xOffset,yOffset}, frame=0, title="ms"

	// Set y offset for this line
	yOffsetRow=videoYOffset+52
	
	// # frames SV
	xOffset=106
	yOffset=yOffsetRow
	width=86
	height=14
	SetVariable nFramesForVideoSV, win=ImagerView, pos={xOffset,yOffset}, size={width,height}, title="Frames:"
	SetVariable nFramesForVideoSV, win=ImagerView, limits={1,inf,1}, proc=ICNFramesForVideoSVTouched

	// Frame rate titlebox parts
//	xOffset=204
//	yOffset=yOffsetRow-2
//	TitleBox frameRateTB, win=ImagerView, pos={xOffset,yOffset}, frame=0
	yOffset=yOffsetRow-13
	xOffset=200
	TitleBox rateTB, win=ImagerView, pos={xOffset,yOffset}, frame=0, title="Rate:"
	xOffset=254
	TitleBox frameRateTB, win=ImagerView, pos={xOffset,yOffset}, frame=0
	xOffset=302
	TitleBox rateUnitsTB, win=ImagerView, pos={xOffset,yOffset}, frame=0, title="Hz"

	// Set y offset for this line
	yOffsetRow=videoYOffset+52+22

	// Is triggered SV
	xOffset=18
	yOffset=yOffsetRow+1
	width=40
	CheckBox isTriggeredCB, win=ImagerView, pos={xOffset,yOffset}, size={width,height}, proc=ICTriggeredCBTwiddled, title="Triggered"

	// TTL output for trigger
	xOffset=106
	yOffset=yOffsetRow
	SetVariable triggerTTLChannelSV, win=ImagerView, pos={xOffset,yOffset}, size={90,1}, limits={0,3,1}, title="TTL Output:"
	SetVariable triggerTTLChannelSV, win=ImagerView, proc=ICTriggerTTLChannelSVTouched

	// Delay for trigger
	xOffset=215
	yOffset=yOffsetRow
	width=80
	height=14
	SetVariable triggerDelaySV, win=ImagerView, pos={xOffset,yOffset}, size={width,height}, title="Delay:"
	SetVariable triggerDelaySV, win=ImagerView, limits={0,inf,10}, proc=ICTriggerDelaySVTouched
	TitleBox triggerDelayUnitsTB, win=ImagerView, pos={xOffset+width+2,yOffset+2}, frame=0, title="ms"

//	// bin width SV
//	yOffset=276
//	SetVariable binWidthSV,win=ImagerView,pos={55,yOffset},size={90,14},proc=ICBinSVTwiddled,title="Bin Width:"
//	SetVariable binWidthSV,win=ImagerView,format="%d"
//
//	// bin height SV
//	SetVariable binHeightSV,win=ImagerView,pos={174,yOffset},size={90,14},proc=ICBinSVTwiddled,title="Bin Height:"
//	SetVariable binHeightSV,win=ImagerView,format="%d"
	
	
	//
	// ROI Group
	//
	groupBoxYOffset+=groupBoxHeight+groupBoxSpaceHeight
	groupBoxHeight=250
	GroupBox roisGroup,win=ImagerView,pos={groupBoxXOffset,groupBoxYOffset},size={groupBoxWidth,groupBoxHeight},title="Regions of Interest"
	
	// ROI Index
	Variable roisYOffset=groupBoxYOffset+groupBoxTitleHeight+15
	xOffset=20
	yOffset=roisYOffset
	width=66
	height=16
	SetVariable iROISV,win=ImagerView,pos={xOffset,yOffset},size={width,height},proc=ICCurrentROIIndexSVTwiddled,title="ROI:"

	// Delete current ROI button
	xOffset+=(width+10)
	width=60
	height=18
	Button deleteROIButton,win=ImagerView,pos={xOffset,yOffset-1},size={width,height},proc=ICDeleteROIButtonPressed,title="Delete"

	// What is calculated for each ROI popup and label
	xOffset+=(width+40)
	Variable labelWidth=70
	Variable yShimPopup=-4
	TitleBox CalculationTB, win=ImagerView, pos={xOffset,yOffset+2}, frame=0, title="Calculation:"
	PopupMenu CalculationPM, win=ImagerView, pos={xOffset+labelWidth,yOffset+2+yShimPopup}, bodyWidth=62
	PopupMenu CalculationPM, win=ImagerView, proc=ICCalculationPMTouched

	// Baseline frames for DF/F
	width=122
	height=0		// ignored
	SetVariable nBaselineFramesSV, win=ImagerView, pos={xOffset,yOffset+23}, size={width,height}, title="Baseline Frames:"
	SetVariable nBaselineFramesSV, win=ImagerView, limits={1,inf,1}, proc=ICNBaselineFramesSVTouched

	// Background checkbox
	width=84
	height=14
	xOffset=54
	CheckBox backgroundCB, win=ImagerView, pos={xOffset,yOffset+22},size={width,height},title="Background?"
	CheckBox backgroundCB, win=ImagerView, proc=ICBackgroundCBTouched
	
	// The four ROI borders
	Variable xCenter=panelWidth/2
	Variable yCenter=yOffset+70
	Variable dx=56	// horzontal distance from center to closest edge of right/left SV
	Variable dy=4	// vertical distance from center to closest edge of top/bottom SV
	
	// Top
	width=72
	SetVariable iROITopSV,win=ImagerView,pos={xCenter-width/2,yCenter-dy-height},size={width,height},proc=ICROISVTwiddled,title="Top:"
	SetVariable iROITopSV,win=ImagerView,format="%0.1f"
	
	// Left
	width=72
	SetVariable iROILeftSV,win=ImagerView,pos={xCenter-dx-width,yCenter-height/2},size={width,height},proc=ICROISVTwiddled,title="Left:"
	SetVariable iROILeftSV,win=ImagerView,format="%0.1f"
	
	// Right
	width=78
	SetVariable iROIRightSV,win=ImagerView,pos={xCenter+dx,yCenter-height/2},size={width,height},proc=ICROISVTwiddled,title="Right:"
	SetVariable iROIRightSV,win=ImagerView,format="%0.1f"
	
	// Bottom
	width=86
	SetVariable iROIBottomSV,win=ImagerView,pos={xCenter-width/2,yCenter+dy},size={width,height},proc=ICROISVTwiddled,title="Bottom:"
	SetVariable iROIBottomSV,win=ImagerView,format="%0.1f"

	// Arrow buttons to move the current ROI
	xCenter=panelWidth/2
	yCenter+=94
	width=20
	height=20
	Variable spacerWidth=2
	Variable spacerHeight=2

	//xOffset=xCenter-width/2-spacerWidth-width-spacerWidth-width-spacerWidth-30
	//yOffset=yCenter-height/2-spacerHeight-height-spacerHeight-height-spacerHeight
	//TitleBox moveROITB, win=ImagerView, pos={xOffset,yOffset}, frame=0, title="Move ROI:"
	
	Button nudgeUpButton, win=ImagerView, pos={xCenter-width/2,yCenter-height/2-spacerHeight-height}, size={width,height}, title="\\W606", proc=ICNudgeUpButtonPressed
	Button moveUpButton, win=ImagerView, pos={xCenter-width/2,yCenter-height/2-spacerHeight-height-spacerHeight-height-spacerHeight}, size={width,height}, title="\\W617", proc=ICMoveUpButtonPressed

	Button nudgeDownButton, win=ImagerView, pos={xCenter-width/2,yCenter+height/2+spacerHeight}, size={width,height}, title="\\W622", proc=ICNudgeDownButtonPressed
	Button moveDownButton, win=ImagerView, pos={xCenter-width/2,yCenter+height/2+spacerHeight+height+spacerHeight}, size={width,height}, title="\\W623", proc=ICMoveDownButtonPressed

	Button nudgeLeftButton, win=ImagerView, pos={xCenter-width/2-spacerWidth-width,yCenter-height/2}, size={width,height}, title="\\W645", proc=ICNudgeLeftButtonPressed
	Button moveLeftButton, win=ImagerView, pos={xCenter-width/2-spacerWidth-width-spacerWidth-width-spacerWidth,yCenter-height/2}, size={width,height}, title="\\W646", proc=ICMoveLeftButtonPressed

	Button nudgeRightButton, win=ImagerView, pos={xCenter+width/2+spacerWidth,yCenter-height/2}, size={width,height}, title="\\W648", proc=ICNudgeRightButtonPressed
	Button moveRightButton, win=ImagerView, pos={xCenter+width/2+spacerWidth+width+spacerWidth,yCenter-height/2}, size={width,height}, title="\\W649", proc=ICMoveRightButtonPressed

	// Move all checkbox
	xOffset=xCenter+width/2+spacerWidth+width	// these are the wdith/height of the D-pad buttons
	yOffset=yCenter+height/2+spacerHeight+height
	CheckBox moveAllCB, win=ImagerView, pos={xOffset,yOffset}, title="Move All"
	CheckBox moveAllCB, win=ImagerView, proc=ICMoveAllCBTouched
	

//	// Binned width, height
//	yOffset=yCenter+32
//	dx=10	// horzontal distance from center to closest edge of right/left VD
//	width=136
//	ValDisplay binnedFrameWidthVD,win=ImagerView,pos={xCenter-dx-width,yOffset},size={width,height},title="Width / Bin Width:",format="%4.2f"
//	ValDisplay binnedFrameWidthVD,win=ImagerView,limits={0,0,0},barmisc={0,1000}
//	
//	//absVarName=AbsoluteVarName("root:DP_Imager","binnedFrameHeight")
//	ValDisplay binnedFrameHeightVD,win=ImagerView,pos={xCenter+dx,yOffset},size={width,height},title="Height / Bin Height:",format="%4.2f"
//	ValDisplay binnedFrameHeightVD,win=ImagerView,limits={0,0,0},barmisc={0,1000}

	// Sync the view to the model
	ImagerViewUpdate()
	
	// Restore the original DF
	SetDataFolder savedDF
End



Function ImagerViewCameraChanged()
	// Notify the ImagerView that the Camera (model) has changed.
	// Currently, this calls the (private) ImagerViewUpdate method.
	ImagerViewUpdate()
End


Function ImagerViewModelChanged()
	// Notify the ImagerView that the Imager (model) has changed.
	// Currently, this calls the (private) ImagerViewUpdate method.
	ImagerViewUpdate()
End


Function ImagerViewEpiLightChanged()
	ImagerViewUpdate()
End


Function ImagerViewSomethingChanged()
	ImagerViewUpdate()
End

Function ImagerViewCCDTempChanged()
	ImagerViewUpdateCCDTemp()
End



//
// Private methods
//

Function ImagerViewUpdate()
	// This is intended to be a private method in ImagerView.

	// If the window doesn't exist, nothing to do
	if (!PanelExists("ImagerView"))
		return 0		// Have to return something
	endif

	// Change to the Imager data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Imager

	// Declare the DF vars we need
	NVAR iROI
	WAVE roisWave

	// Update the Epi light toggle button
	Variable isLightOn=EpiLightGetIsOn()
	Variable isLightOff=EpiLightGetIsOff()
	Variable isLightAgnostic=EpiLightGetIsAgnostic()
	SetVariable ttlOutputChannelSV, win=ImagerView, value= _NUM:EpiLightGetTTLOutputIndex()
	SetVariable ttlOutputChannelSV, win=ImagerView, disable= fromEnable(isLightOff)
	String titleStr = stringFif(isLightAgnostic, "(Light Control Ceded)", stringFif(isLightOn, "Turn Epiillumination Off", "Turn Epiillumination On") )
	Button EpiLightToggleButton, win=ImagerView, title=titleStr, disable= (isLightAgnostic? 2 : 0)
	ValDisplay EpiLightStatusVD, win=ImagerView, value= _NUM:isLightOn, disable= (isLightAgnostic ? 1 : 0)

	// Update epi-light delay and duration	
	SetVariable epiTriggeredDelaySV, win=ImagerView, value=_NUM:EpiLightGetTriggeredDelay()
	SetVariable epiTriggeredDurationSV, win=ImagerView, value=_NUM:EpiLightGetTriggeredDuration()
	
	// Update the enablement of the "Focus" button
	Variable isFocusing=ImagerGetIsFocusing()
	Button focusButton,win=ImagerView,disable=(isFocusing?2:0)

	// Update the desired video exposure duration SV
	Variable snapshotExposureWanted=ImagerGetSnapshotExposureWanted()		// ms
	SetVariable snapshotExposureWantedSV, win=ImagerView, value=_NUM:snapshotExposureWanted

	// Update the snapshot exposure duration TB
	Variable snapshotExposure=ImagerGetSnapshotExposure()	// ms
	TitleBox actualSnapshotExposureTB, win=ImagerView, title=sprintf1v("%0.3f",snapshotExposure)
	
	// Update the "(hit ESC to Cancel)" message for focusing
	TitleBox focusingEscapeTB,win=ImagerView,disable=(!isFocusing)

	// Update the enablement of the "Take Video" button
	Variable isAcquiringVideo=ImagerGetIsAcquiringVideo()
	Button takeVideoButton,win=ImagerView,disable=(ImagerGetIsTriggered()&&!isAcquiringVideo?2:0)

	// Update the desired video exposure duration SV
	Variable videoExposureWanted=ImagerGetVideoExposureWanted()		// ms
	SetVariable videoExposureWantedSV, win=ImagerView, value=_NUM:videoExposureWanted

	// Update the frame rate TB
	Variable frameRate=ImagerGetFrameRate()		// Hz
	//TitleBox frameRateTB, win=ImagerView, title=sprintf1v("Frame Rate: %0.3f Hz",frameRate)
	TitleBox frameRateTB, win=ImagerView, title=sprintf1v("%0.3f",frameRate)

	// Update the actual video exposure duration TB
	Variable videoExposure=ImagerGetVideoExposure()	// ms
	TitleBox actualVideoExposureTB, win=ImagerView, title=sprintf1v("%0.3f",videoExposure)

	//Update the number of frames for video
	SetVariable nFramesForVideoSV, win=ImagerView, value=_NUM:ImagerGetNFramesForVideo()

	// Update the "(hit ESC to Cancel)" message for video
	TitleBox videoEscapeTB,win=ImagerView,disable=(!isAcquiringVideo)

	// Update the isTriggered checkbox and friends
	Variable isTriggered=ImagerGetIsTriggered()
	Variable triggerTTLOutputIndex=ImagerGetTriggerTTLOutputIndex()
	CheckBox isTriggeredCB, win=ImagerView, value=isTriggered, disable=fromEnable(!SweeperGetTTLOutputChannelOn(triggerTTLOutputIndex)||isTriggered)
	SetVariable triggerTTLChannelSV, win=ImagerView, value=_NUM:triggerTTLOutputIndex, disable=fromEnable(isTriggered)
	SetVariable triggerDelaySV, win=ImagerView, value=_NUM:ImagerGetTriggerDelay(), disable=fromEnable(isTriggered)
	TitleBox triggerDelayUnitsTB, win=ImagerView, disable=fromEnable(isTriggered)

	// Update the CCD temperature
	Variable ccdTemperature=ImagerGetCCDTemperature()
	ValDisplay ccdTemperatureVD, win=ImagerView, value= _NUM:ccdTemperature
	WhiteOutIffNan("ccdTemperatureVD","ImagerView",ccdTemperature)

	// Update the calculation popup
	String calculationList=ImagerGetCalculationList()
	String calculationListFU="\""+calculationList+"\""	
	PopupMenu CalculationPM, win=ImagerView, value=#calculationListFU
	PopupMenu CalculationPM, win=ImagerView, mode=ImagerGetCalculationIndex()+1

	// Calculate things we need
	Variable ccdWidth=CameraCCDWidthGet()
	Variable ccdHeight=CameraCCDHeightGet()
	Variable iROILeft=ImagerGetIROILeft(iROI)
	Variable iROIRight=ImagerGetIROIRight(iROI)
	Variable iROITop=ImagerGetIROITop(iROI)
	Variable iROIBottom=ImagerGetIROIBottom(iROI)
	Variable binSize=ImagerGetBinSize()
	//Variable binHeight=ImagerGetBinHeight()
	Variable nROIs=ImagerGetNROIs()
	//Variable roiWidthInBins=(iROIRight-iROILeft)/binSize
	//Variable roiHeightInBins=(iROIBottom-iROITop)/binHeight

	// Update stuff
	PopupMenu binSizePM, win=ImagerView, mode=ImagerGetBinSizeIndex()+1
	SetVariable nBaselineFramesSV, win=ImagerView, value=_NUM:ImagerGetNBaselineFrames()
	Variable isDFF=AreStringsEqual(ImagerGetCalculationName(),"DF/F")
	SetVariable nBaselineFramesSV, win=ImagerView, disable=fromEnable(isDFF)

	//SetVariable binWidthSV,win=ImagerView,limits={1,ccdWidth,1},value= _NUM:binWidth
	//SetVariable binHeightSV,win=ImagerView,limits={1,ccdHeight,1},value= _NUM:binHeight
	if (nROIs==0)
		SetVariable iROISV, win=ImagerView, value= _STR:"(none)", disable=2
		Button deleteROIButton, win=ImagerView, disable=2
		SetVariable iROILeftSV,win=ImagerView,value= _STR:"", disable=2
		SetVariable iROIRightSV,win=ImagerView,value= _STR:"", disable=2
		SetVariable iROITopSV,win=ImagerView,value= _STR:"", disable=2
		SetVariable iROIBottomSV,win=ImagerView,value= _STR:"", disable=2
		CheckBox backgroundCB, win=ImagerView, value=0, disable=2
	else
		SetVariable iROISV, win=ImagerView, format="%d", limits={0,nROIs-1,1}, value= _NUM:(iROI), disable=0
		Button deleteROIButton, win=ImagerView, disable=0
		SetVariable iROILeftSV,win=ImagerView,limits={0,ccdWidth,1},value= _NUM:iROILeft, disable=0
		SetVariable iROIRightSV,win=ImagerView,limits={0,ccdWidth,1},value= _NUM:iROIRight, disable=0
		SetVariable iROITopSV,win=ImagerView,limits={0,ccdHeight,1},value= _NUM:iROITop, disable=0
		SetVariable iROIBottomSV,win=ImagerView,limits={0,ccdHeight,1},value= _NUM:iROIBottom, disable=0
		CheckBox backgroundCB, win=ImagerView, value=ImagerGetCurrentROIIsBackground(), disable=0
	endif
	Button nudgeUpButton, win=ImagerView, disable=( (nROIs==0) ? 2 : 0 )
	Button moveUpButton, win=ImagerView, disable=( (nROIs==0) ? 2 : 0 )
	Button nudgeDownButton, win=ImagerView, disable=( (nROIs==0) ? 2 : 0 )
	Button moveDownButton, win=ImagerView, disable=( (nROIs==0) ? 2 : 0 )
	Button nudgeLeftButton, win=ImagerView, disable=( (nROIs==0) ? 2 : 0 )
	Button moveLeftButton, win=ImagerView, disable=( (nROIs==0) ? 2 : 0 )
	Button nudgeRightButton, win=ImagerView, disable=( (nROIs==0) ? 2 : 0 )
	Button moveRightButton, win=ImagerView, disable=( (nROIs==0) ? 2 : 0 )
	CheckBox moveAllCB, win=ImagerView, disable=( (nROIs==0) ? 2 : 0 )
	
//	ValDisplay binnedFrameWidthVD, win=ImagerView, value= _NUM:roiWidthInBins
//	WhiteOutIffNan("binnedFrameWidthVD","ImagerView",roiWidthInBins)
//	
//	ValDisplay binnedFrameHeightVD, win=ImagerView, value= _NUM:roiHeightInBins
//	WhiteOutIffNan("binnedFrameHeightVD","ImagerView",roiHeightInBins)
	
	// Restore the original DF
	SetDataFolder savedDF
End


Function ImagerViewSetIsProTipShowing(isProTipShowing)
	Variable isProTipShowing

	TitleBox focusingEscapeTB,win=ImagerView,disable=(!isProTipShowing)
End

Function ImagerViewUpdateCCDTemp()
	// If the window doesn't exist, nothing to do
	if (!PanelExists("ImagerView"))
		return 0		// Have to return something
	endif

	// Update the CCD temperature
	Variable ccdTemperature=ImagerGetCCDTemperature()
	ValDisplay ccdTemperatureVD, win=ImagerView, value= _NUM:ccdTemperature
	WhiteOutIffNan("ccdTemperatureVD","ImagerView",ccdTemperature)
End
