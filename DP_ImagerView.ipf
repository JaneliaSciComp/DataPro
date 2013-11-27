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
	Variable panelWidth=310
	Variable panelHeight=472
	NewPanel /W=(xOffset,yOffset,xOffset+panelWidth,yOffset+panelHeight)  /N=ImagerView /K=1 as "Imager Controls"
	ModifyPanel /W=ImagerView fixedSize=1

	Button EpiLightToggleButton,win=ImagerView,pos={10,20},size={130,20},proc=ImagerContEpiLightToggle
	//Button flu_off,win=ImagerView,pos={10,10},size={130,40},proc=FluOFFButtonProc,title="Epi Light Off"
	//CheckBox imaging_check0,win=ImagerView,pos={14,244},size={114,14},proc=ImagingCheckProc,title="trigger filter wheel"
	//CheckBox imaging_check0,win=ImagerView,value= 1
	//Button button0,win=ImagerView,pos={215,283},size={80,20},proc=AppendDFFButtonProc,title="Append DF/F"
	Button button1,win=ImagerView,pos={9,190},size={130,20},proc=EphysImageButtonProc,title="Triggered Video"
	SetVariable setimagename0,win=ImagerView,pos={141,223},size={80,15},title="Name:"
	SetVariable setimagename0,win=ImagerView,value= videoWaveBaseName
	//CheckBox bkgndcheck0,win=ImagerView,pos={14,265},size={71,14},title="Bkgnd Sub.",value= 1
	SetVariable numimages_setvar0,win=ImagerView,pos={11,223},size={100,15},title="# Frames:"
	SetVariable numimages_setvar0,win=ImagerView,limits={1,10000,1},value= nFramesForVideo
	SetVariable ccdtemp_setvar0,win=ImagerView,pos={13,311},size={140,15},proc=SetCCDTempVarProc,title="CCD Temp Setpoint:"
	SetVariable ccdtemp_setvar0,win=ImagerView,limits={-50,20,5},value= ccdTargetTemperature
	//CheckBox showimageavg_check0,win=ImagerView,pos={14,286},size={84,14},title="Show Average"
	//CheckBox showimageavg_check0,win=ImagerView,value= 0
	//Button resetavg_button2,win=ImagerView,pos={212,253},size={80,20},proc=ResetAvgButtonProc,title="Reset Avg"
	
	Button focus,win=ImagerView,pos={10,70},size={130,20},proc=FocusButtonProc,title="Focus"
	TitleBox proTipTitleBox,win=ImagerView,pos={26,94},frame=0,title="(hit ESC key to stop)",disable=1
	
	Button full_frame,win=ImagerView,pos={10,130},size={130,20},proc=FullButtonProc,title="Snapshot"
	//SetVariable fluo_on_set,win=ImagerView,pos={178,40},size={120,15},title="ON   position"
	//SetVariable fluo_on_set,win=ImagerView,limits={0,9,1},value= wheelPositionForEpiLightOn
	//SetVariable fluo_off_set,win=ImagerView,pos={177,10},size={120,15},title="OFF position"
	//SetVariable fluo_off_set,win=ImagerView,limits={0,9,1},value= wheelPositionForEpiLightOff
	//SetVariable focusnum_set,win=ImagerView,pos={229,98},size={70,15},title="no."
	//SetVariable focusnum_set,win=ImagerView,limits={0,1000,1},value= iFocusWave
	SetVariable fulltime_set,win=ImagerView,pos={152,130},size={100,15},title="Exposure:"
	SetVariable fulltime_set,win=ImagerView,limits={0,10000,100},value= exposure
	SetVariable imagetime_setvar0,win=ImagerView,pos={149,193},size={100,15},title="Exposure:"
	SetVariable imagetime_setvar0,win=ImagerView,limits={0,10000,10},value= videoExposure
	SetVariable setfullname0,win=ImagerView,pos={137,158},size={80,15},title="Name:"
	SetVariable setfullname0,win=ImagerView,value= fullFrameWaveBaseName
	//SetVariable setfocusname0,win=ImagerView,pos={139,99},size={80,15},title="name"
	//SetVariable setfocusname0,win=ImagerView,value= focusWaveBaseName
	
	absVarName=AbsoluteVarName("root:DP_Imager","ccdTemperature")
	ValDisplay tempdisp0,win=ImagerView,pos={194,311},size={100,14},title="CCD Temp:"
	ValDisplay tempdisp0,win=ImagerView,format="%3.1f",limits={0,0,0},barmisc={0,1000}
	ValDisplay tempdisp0,win=ImagerView,value= #absVarName
	
	SetVariable focustime_set,win=ImagerView,pos={151,70},size={100,15},title="Exposure:"
	SetVariable focustime_set,win=ImagerView,limits={0,10000,100},value= focusingExposure
	//SetVariable fullnum_set,win=ImagerView,pos={230,159},size={70,15},title="Next:"
	//SetVariable fullnum_set,win=ImagerView,limits={0,1000,1},value= iFullFrameWave
	//SetVariable imageseqnum_set,win=ImagerView,pos={227,223},size={70,15},title="Next:"
	//SetVariable imageseqnum_set,win=ImagerView,limits={0,10000,1},value= iVideoWave
	
	SetVariable binWidthSV,win=ImagerView,pos={55,338},size={90,15},proc=SetROIProc,title="Bin Width:"
	SetVariable binWidthSV,win=ImagerView,format="%d"
	SetVariable binHeightSV,win=ImagerView,pos={174,338},size={90,15},proc=SetROIProc,title="Bin Height:"
	SetVariable binHeightSV,win=ImagerView,format="%d"

	// ROI Index
	yOffset=341+25+4
	Variable width=66
	Variable height=16
	SetVariable roinum_set,win=ImagerView,pos={(panelWidth-width)/2,yOffset},size={width,height},proc=ImagerContiROISVTwiddled,title="ROI:"

	// The four ROI borders
	Variable xCenter=panelWidth/2
	Variable yCenter=(370+395)/2+25+8
	Variable dx=56	// horzontal distance from center to closest edge of right/left SV
	Variable dy=4	// vertical distance from center to closest edge of top/bottom SV
	
	// Top
	width=70
	SetVariable iROITopSV,win=ImagerView,pos={xCenter-width/2,yCenter-dy-height},size={width,height},proc=SetROIProc,title="Top:"
	SetVariable iROITopSV,win=ImagerView,format="%d"
	
	width=72
	SetVariable iROILeftSV,win=ImagerView,pos={xCenter-dx-width,yCenter-height/2},size={width,height},proc=SetROIProc,title="Left:"
	SetVariable iROILeftSV,win=ImagerView,format="%d"
	
	width=76
	SetVariable iROIRightSV,win=ImagerView,pos={xCenter+dx,yCenter-height/2},size={width,height},proc=SetROIProc,title="Right:"
	SetVariable iROIRightSV,win=ImagerView,format="%d"
	
	width=86
	SetVariable iROIBottomSV,win=ImagerView,pos={xCenter-width/2,yCenter+dy},size={width,height},proc=SetROIProc,title="Bottom:"
	SetVariable iROIBottomSV,win=ImagerView,format="%d"

	// Binned width, height
	yOffset=450
	dx=10	// horzontal distance from center to closest edge of right/left VD
	width=136
	ValDisplay binnedFrameWidthVD,win=ImagerView,pos={xCenter-dx-width,yOffset},size={width,height},title="Width / Bin Width:",format="%4.2f"
	ValDisplay binnedFrameWidthVD,win=ImagerView,limits={0,0,0},barmisc={0,1000}
	
	//absVarName=AbsoluteVarName("root:DP_Imager","binnedFrameHeight")
	ValDisplay binnedFrameHeightVD,win=ImagerView,pos={xCenter+dx,yOffset},size={width,height},title="Height / Bin Height:",format="%4.2f"
	ValDisplay binnedFrameHeightVD,win=ImagerView,limits={0,0,0},barmisc={0,1000}
	
	Button getstac_button,win=ImagerView,pos={125,253},size={80,20},proc=StackButtonProc,title="Take Video"
	//CheckBox show_roi_check0,win=ImagerView,pos={109,286},size={94,14},title="Show ROI Image"
	//CheckBox show_roi_check0,win=ImagerView,value= 0
	
	// Sync the view to the model
	ImagerViewUpdate()
	
	// Restore the original DF
	SetDataFolder savedDF
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
	String titleStr = stringFif(EpiLightGetIsOn(),"Turn Epi Light Off","Turn Epi Light On")
	Button EpiLightToggleButton, win=ImagerView, title=titleStr

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
	Variable roiWidthInBins=(iROIRight-iROILeft)/binWidth
	Variable roiHeightInBins=(iROIBottom-iROITop)/binHeight

	// Update stuff
	SetVariable binWidthSV,win=ImagerView,limits={1,ccdWidth,1},value= _NUM:binWidth
	SetVariable binHeightSV,win=ImagerView,limits={1,ccdHeight,1},value= _NUM:binHeight
	if (nROIs==0)
		SetVariable roinum_set, win=ImagerView, value= _STR:"(none)"
		SetVariable iROILeftSV,win=ImagerView,value= _STR:"NA"
		SetVariable iROIRightSV,win=ImagerView,value= _STR:"NA"
		SetVariable iROITopSV,win=ImagerView,value= _STR:"NA"
		SetVariable iROIBottomSV,win=ImagerView,value= _STR:"NA"
	else
		SetVariable roinum_set, win=ImagerView, format="%d", limits={1,nROIs,1}, value= _NUM:(iROI+1)
		SetVariable iROILeftSV,win=ImagerView,limits={0,ccdWidth-1,1},value= _NUM:iROILeft
		SetVariable iROIRightSV,win=ImagerView,limits={0,ccdWidth-1,1},value= _NUM:iROIRight
		SetVariable iROITopSV,win=ImagerView,limits={0,ccdHeight-1,1},value= _NUM:iROITop
		SetVariable iROIBottomSV,win=ImagerView,limits={0,ccdHeight-1,1},value= _NUM:iROIBottom
	endif
	
	ValDisplay binnedFrameWidthVD, win=ImagerView, value= _NUM:roiWidthInBins
	WhiteOutIffNan("binnedFrameWidthVD","ImagerView",roiWidthInBins)
	
	ValDisplay binnedFrameHeightVD, win=ImagerView, value= _NUM:roiHeightInBins
	WhiteOutIffNan("binnedFrameHeightVD","ImagerView",roiHeightInBins)
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function ImagerViewSetIsProTipShowing(isProTipShowing)
	Variable isProTipShowing

	TitleBox proTipTitleBox,win=ImagerView,disable=(!isProTipShowing)
End
