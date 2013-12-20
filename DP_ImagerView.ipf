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
	
	Variable xOffset=1550
	Variable yOffset=54
	Variable panelWidth=330
	Variable panelHeight=560
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
	Variable groupBoxHeight=54
	GroupBox illuminationGroup,win=ImagerView,pos={groupBoxXOffset,groupBoxYOffset},size={groupBoxWidth,groupBoxHeight},title="Illumination"

	// TTL Output SetVariable		
	xOffset=30
	yOffset=groupBoxYOffset+groupBoxTitleHeight+(groupBoxHeight-14)/2
	SetVariable ttlOutputChannelSV,win=ImagerView,pos={xOffset,yOffset},size={90,1},limits={0,3,1},title="TTL Output:"
	SetVariable ttlOutputChannelSV,win=ImagerView,proc=ICEpiTTLChannelSVTouched	
	
	// On/Off Button
	Variable width=140	// Size of the button
	Variable height=26
	xOffset=146
	yOffset=groupBoxYOffset+groupBoxTitleHeight+(groupBoxHeight-height)/2
	Button EpiLightToggleButton,win=ImagerView,pos={xOffset,yOffset},size={width,height},proc=ICEpiLightToggleButtonPressed

	// On/Off ValDisplay
	xOffset=310
	yOffset=groupBoxYOffset+groupBoxTitleHeight+(groupBoxHeight-14)/2
	ValDisplay EpiLightStatusVD, win=ImagerView, pos={xOffset,yOffset}, size={0,14}, bodyWidth=14, mode=1, limits={0,1,0.5}
	ValDisplay EpiLightStatusVD, win=ImagerView, barmisc={0,0}, highColor=(0,65535,0), lowColor=(0,0,0)

//ValDisplay ld501_1 title="round LED",size={65,13},bodyWidth=10,mode=1;DelayUpdate
//ValDisplay ld501_1 barmisc={0,0},limits={-50,100,0}

	//
	// Temperature Group
	//
	groupBoxYOffset+=groupBoxHeight+groupBoxSpaceHeight
	groupBoxHeight=44
	GroupBox temperatureGroup,win=ImagerView,pos={groupBoxXOffset,groupBoxYOffset},size={groupBoxWidth,groupBoxHeight},title="CCD Temperature"
	
	height=14
	yOffset=groupBoxYOffset+groupBoxTitleHeight+(groupBoxHeight-height)/2
	SetVariable ccdTemperatureSetpointSV,win=ImagerView,pos={50,yOffset},size={96,height},proc=ICTempSetpointSVTwiddled,title="Setpoint:"
	SetVariable ccdTemperatureSetpointSV, win=ImagerView, limits={-50,20,5}, format="%0.1f", value= ccdTargetTemperature

	ValDisplay ccdTemperatureVD,win=ImagerView,pos={184,yOffset+1},size={76,height},title="Current:"
	ValDisplay ccdTemperatureVD,win=ImagerView,format="%0.1f",limits={0,0,0},barmisc={0,1000}


	//
	// Snapshots Group
	//
	groupBoxYOffset+=groupBoxHeight+groupBoxSpaceHeight
	groupBoxHeight=80
	GroupBox fullFrameGroup,win=ImagerView,pos={groupBoxXOffset,groupBoxYOffset},size={groupBoxWidth,groupBoxHeight},title="Snapshots"

	xOffset=16
	Variable buttonWidth=80
	Variable buttonHeight=20
	Variable buttonSpacerHeight=8
	Variable nButtons=2
	Variable buttonGroupHeight=nButtons*buttonHeight+(nButtons-1)*buttonSpacerHeight
	
	// Snapshot button
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
	SetVariable snapshotExposureSV,win=ImagerView,pos={xOffset,yOffset},size={width,height},title="Exposure:"
	SetVariable snapshotExposureSV,win=ImagerView,limits={0,10000,100},value= snapshotExposure
	TitleBox snapshotExposureUnitsTitleBox,win=ImagerView,pos={xOffset+width+2,yOffset+2},frame=0,title="ms"

	// "(hit ESC key to stop)" title box
	TitleBox focusingEscapeTB, win=ImagerView, pos={106,focusYOffset+3}, frame=0, title="(hit ESC key to stop)",disable=1


	//
	// Video Group
	//
	groupBoxYOffset+=groupBoxHeight+groupBoxSpaceHeight
	groupBoxHeight=94
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
	SetVariable videoExposureSV, win=ImagerView, pos={xOffset,yOffset}, size={width,height}, title="Exposure:"
	SetVariable videoExposureSV, win=ImagerView, limits={0,10000,10}, value=videoExposure
	TitleBox videoExposureUnitsTitleBox,win=ImagerView,pos={xOffset+width+2,yOffset+2},frame=0,title="ms"

	// # frames SV	
	xOffset=106
	yOffset=videoYOffset+26
	width=100
	height=14
	SetVariable nFramesSV, win=ImagerView, pos={xOffset,yOffset}, size={width,height}, title="# Frames:"
	SetVariable nFramesSV, win=ImagerView, limits={1,10000,1}, value=nFramesForVideo

	// is triggered SV
	xOffset=240
	yOffset=yOffset+1
	width=40
	CheckBox isTriggeredCB, win=ImagerView, pos={xOffset,yOffset}, size={width,height}, proc=ICTriggeredCBTwiddled, title="Triggered"

	// bin width SV
	yOffset=276
	SetVariable binWidthSV,win=ImagerView,pos={55,yOffset},size={90,14},proc=ICBinOrROISVTwiddled,title="Bin Width:"
	SetVariable binWidthSV,win=ImagerView,format="%d"

	// bin height SV
	SetVariable binHeightSV,win=ImagerView,pos={174,yOffset},size={90,14},proc=ICBinOrROISVTwiddled,title="Bin Height:"
	SetVariable binHeightSV,win=ImagerView,format="%d"
	
	
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
	SetVariable iROITopSV,win=ImagerView,pos={xCenter-width/2,yCenter-dy-height},size={width,height},proc=ICBinOrROISVTwiddled,title="Top:"
	SetVariable iROITopSV,win=ImagerView,format="%0.1f"
	
	// Left
	width=72
	SetVariable iROILeftSV,win=ImagerView,pos={xCenter-dx-width,yCenter-height/2},size={width,height},proc=ICBinOrROISVTwiddled,title="Left:"
	SetVariable iROILeftSV,win=ImagerView,format="%0.1f"
	
	// Right
	width=78
	SetVariable iROIRightSV,win=ImagerView,pos={xCenter+dx,yCenter-height/2},size={width,height},proc=ICBinOrROISVTwiddled,title="Right:"
	SetVariable iROIRightSV,win=ImagerView,format="%0.1f"
	
	// Bottom
	width=86
	SetVariable iROIBottomSV,win=ImagerView,pos={xCenter-width/2,yCenter+dy},size={width,height},proc=ICBinOrROISVTwiddled,title="Bottom:"
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


Function ImagerViewUpdate()
	// This is intended to be a private method in ImagerView.
	// Currently it updates only one SetVariable, but that should change
	// in the future

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
	SetVariable ttlOutputChannelSV, win=ImagerView, value= _NUM:EpiLightGetTTLOutputIndex()
	Variable isLightOn=EpiLightGetIsOn()
	String titleStr = stringFif(isLightOn,"Turn Epiillumination Off","Turn Epiillumination On")
	Button EpiLightToggleButton, win=ImagerView, title=titleStr
	ValDisplay EpiLightStatusVD, win=ImagerView, value= _NUM:isLightOn
	
	// Update the enablement of the "Focus" button
	Variable isFocusing=ImagerGetIsFocusing()
	Button focusButton,win=ImagerView,disable=(isFocusing?2:0)

	// Update the "(hit ESC to Cancel)" message for focusing
	TitleBox focusingEscapeTB,win=ImagerView,disable=(!isFocusing)

	// Update the enablement of the "Take Video" button
	Variable isAcquiringVideo=ImagerGetIsAcquiringVideo()
	Button takeVideoButton,win=ImagerView,disable=(ImagerGetIsTriggered()&&!isAcquiringVideo?2:0)

	// Update the "(hit ESC to Cancel)" message for video
	TitleBox videoEscapeTB,win=ImagerView,disable=(!isAcquiringVideo)

	// Update the isTriggered checkbox
	CheckBox isTriggeredCB, win=ImagerView, value=ImagerGetIsTriggered()

	// Update the CCD temperature
	Variable ccdTemperature=FancyCameraGetTemperature()
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
	Variable binWidth=ImagerGetBinWidth()
	Variable binHeight=ImagerGetBinHeight()
	Variable nROIs=ImagerGetNROIs()
	//Variable roiWidthInBins=(iROIRight-iROILeft)/binWidth
	//Variable roiHeightInBins=(iROIBottom-iROITop)/binHeight

	// Update stuff
	SetVariable binWidthSV,win=ImagerView,limits={1,ccdWidth,1},value= _NUM:binWidth
	SetVariable binHeightSV,win=ImagerView,limits={1,ccdHeight,1},value= _NUM:binHeight
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
