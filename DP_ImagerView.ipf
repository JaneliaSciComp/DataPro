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
	Variable panelHeight=410-26
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
	
	Variable width=140
	Variable height=26
	xOffset=(panelWidth-width)/2
	yOffset=groupBoxYOffset+groupBoxTitleHeight+(groupBoxHeight-height)/2
	Button EpiLightToggleButton,win=ImagerView,pos={xOffset,yOffset},size={width,height},proc=ICEpiLightToggleButtonPressed


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
	groupBoxHeight=174
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
	
	// ROI Index
	xOffset=20
	yOffset=yOffset+30
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
	TitleBox CalculationTB, win=ImagerView, pos={xOffset,yOffset}, frame=0, title="Calculation:"
	PopupMenu CalculationPM, win=ImagerView, pos={xOffset+labelWidth,yOffset+yShimPopup}, bodyWidth=62
	PopupMenu CalculationPM, win=ImagerView, proc=ICCalculationPMTouched

	// The four ROI borders
	Variable xCenter=panelWidth/2
	Variable yCenter=yOffset+44
	Variable dx=56	// horzontal distance from center to closest edge of right/left SV
	Variable dy=4	// vertical distance from center to closest edge of top/bottom SV
	
	// Top
	width=72
	SetVariable iROITopSV,win=ImagerView,pos={xCenter-width/2,yCenter-dy-height},size={width,height},proc=ICBinOrROISVTwiddled,title="Top:"
	SetVariable iROITopSV,win=ImagerView,format="%0.1f"
	
	width=72
	SetVariable iROILeftSV,win=ImagerView,pos={xCenter-dx-width,yCenter-height/2},size={width,height},proc=ICBinOrROISVTwiddled,title="Left:"
	SetVariable iROILeftSV,win=ImagerView,format="%0.1f"
	
	width=78
	SetVariable iROIRightSV,win=ImagerView,pos={xCenter+dx,yCenter-height/2},size={width,height},proc=ICBinOrROISVTwiddled,title="Right:"
	SetVariable iROIRightSV,win=ImagerView,format="%0.1f"
	
	width=86
	SetVariable iROIBottomSV,win=ImagerView,pos={xCenter-width/2,yCenter+dy},size={width,height},proc=ICBinOrROISVTwiddled,title="Bottom:"
	SetVariable iROIBottomSV,win=ImagerView,format="%0.1f"

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
	String titleStr = stringFif(EpiLightGetIsOn(),"Turn Epiillumination Off","Turn Epiillumination On")
	Button EpiLightToggleButton, win=ImagerView, title=titleStr

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
	else
		SetVariable iROISV, win=ImagerView, format="%d", limits={1,nROIs,1}, value= _NUM:(iROI+1), disable=0
		Button deleteROIButton, win=ImagerView, disable=0
		SetVariable iROILeftSV,win=ImagerView,limits={0,ccdWidth,1},value= _NUM:iROILeft, disable=0
		SetVariable iROIRightSV,win=ImagerView,limits={0,ccdWidth,1},value= _NUM:iROIRight, disable=0
		SetVariable iROITopSV,win=ImagerView,limits={0,ccdHeight,1},value= _NUM:iROITop, disable=0
		SetVariable iROIBottomSV,win=ImagerView,limits={0,ccdHeight,1},value= _NUM:iROIBottom, disable=0
	endif
	
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
