//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function DigitizerViewConstructor() : Panel
	// This is the constructor for the Digitizer view
	
	// If the view already exists, just raise it
	if (PanelExists("DigitizerView"))
		DoWindow /F DigitizerView
		return 0
	endif
	
	// Do the DF Dance
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer
	
	// Create the panel
	NewPanel /W=(1040,530,1040+478,530+224) /N=DigitizerView /K=1 as "Digitizer Controls"
	ModifyPanel /W=DigitizerView fixedSize=1
	
	//
	// ADC channel area
	// 
	
	// ADC gain setvars
	Variable xSize=70	// height of SV
	Variable ySize=15	// width of SV
	Variable yShift=24
	Variable xShiftPopup=55
	Variable xShiftSV=55
	Variable xShiftUnits=74
	Variable yShimPopup=3	
	Variable yOffset=6
	
	Variable xOffset=6
	GroupBox adcGroup,win=DigitizerView,pos={xOffset,yOffset},size={228,197+2*(8-1)},title="ADC Channels"
	xOffset+=10
	yOffset+=20

	TitleBox ADC0TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="ADC0:"
	PopupMenu ADCChannelModePopupMenu0,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu ADCChannelModePopupMenu0,win=DigitizerView, proc=DigitizerContADCModePopup
	SetVariable adcGain0SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={xSize,ySize},proc=DigitizerContADCGainSV,title="Gain:"
	SetVariable adcGain0SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox adcGain0UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0
	
	yOffset+=yShift
	TitleBox ADC1TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="ADC1:"
	PopupMenu ADCChannelModePopupMenu1,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu ADCChannelModePopupMenu1,win=DigitizerView, proc=DigitizerContADCModePopup
	SetVariable adcGain1SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={xSize,ySize},proc=DigitizerContADCGainSV,title="Gain:"
	SetVariable adcGain1SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox adcGain1UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0
	
	yOffset+=yShift
	TitleBox ADC2TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="ADC2:"
	PopupMenu ADCChannelModePopupMenu2,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu ADCChannelModePopupMenu2,win=DigitizerView, proc=DigitizerContADCModePopup
	SetVariable adcGain2SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={xSize,ySize},proc=DigitizerContADCGainSV,title="Gain:"
	SetVariable adcGain2SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox adcGain2UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0
	
	yOffset+=yShift
	TitleBox ADC3TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="ADC3:"
	PopupMenu ADCChannelModePopupMenu3,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu ADCChannelModePopupMenu3,win=DigitizerView, proc=DigitizerContADCModePopup
	SetVariable adcGain3SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={xSize,ySize},proc=DigitizerContADCGainSV,title="Gain:"
	SetVariable adcGain3SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox adcGain3UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0
	
	yOffset+=yShift
	TitleBox ADC4TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="ADC4:"
	PopupMenu ADCChannelModePopupMenu4,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu ADCChannelModePopupMenu4,win=DigitizerView, proc=DigitizerContADCModePopup
	SetVariable adcGain4SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={xSize,ySize},proc=DigitizerContADCGainSV,title="Gain:"
	SetVariable adcGain4SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox adcGain4UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0
	
	yOffset+=yShift
	TitleBox ADC5TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="ADC5:"
	PopupMenu ADCChannelModePopupMenu5,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu ADCChannelModePopupMenu5,win=DigitizerView, proc=DigitizerContADCModePopup
	SetVariable adcGain5SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={xSize,ySize},proc=DigitizerContADCGainSV,title="Gain:"
	SetVariable adcGain5SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox adcGain5UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0
	
	yOffset+=yShift
	TitleBox ADC6TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="ADC6:"
	PopupMenu ADCChannelModePopupMenu6,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu ADCChannelModePopupMenu6,win=DigitizerView, proc=DigitizerContADCModePopup
	SetVariable adcGain6SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={xSize,ySize},proc=DigitizerContADCGainSV,title="Gain:"
	SetVariable adcGain6SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox adcGain6UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0
	
	yOffset+=yShift
	TitleBox ADC7TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="ADC7:"
	PopupMenu ADCChannelModePopupMenu7,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu ADCChannelModePopupMenu7,win=DigitizerView, proc=DigitizerContADCModePopup
	SetVariable adcGain7SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={xSize,ySize},proc=DigitizerContADCGainSV,title="Gain:"
	SetVariable adcGain7SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox adcGain7UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0

	//
	// DAC channel area
	// 
	xOffset=245
	yOffset=6
	
	GroupBox dacGroup,win=DigitizerView,pos={xOffset,yOffset},size={228,110+2*(4-1)},title="DAC Channels"
	xOffset+=10
	yOffset+=20

	TitleBox DAC0TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="DAC0:"
	PopupMenu DACChannelModePopupMenu0,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu DACChannelModePopupMenu0,win=DigitizerView,proc=DigitizerContDACModePopup
	SetVariable dacGain0SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={70,15},proc=DigitizerContDACGainSV,title="Gain:"
	SetVariable dacGain0SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox dacGain0UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0

	yOffset+=yShift
	TitleBox DAC1TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="DAC1:"
	PopupMenu DACChannelModePopupMenu1,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu DACChannelModePopupMenu1,win=DigitizerView,proc=DigitizerContDACModePopup
	SetVariable dacGain1SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={70,15},proc=DigitizerContDACGainSV,title="Gain:"
	SetVariable dacGain1SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox dacGain1UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0

	yOffset+=yShift
	TitleBox DAC2TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="DAC2:"
	PopupMenu DACChannelModePopupMenu2,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu DACChannelModePopupMenu2,win=DigitizerView,proc=DigitizerContDACModePopup
	SetVariable dacGain2SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={70,15},proc=DigitizerContDACGainSV,title="Gain:"
	SetVariable dacGain2SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox dacGain2UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0

	yOffset+=yShift
	TitleBox DAC3TitleBox,win=DigitizerView,pos={xOffset,yOffset},size={45,15},frame=0,title="DAC3:"
	PopupMenu DACChannelModePopupMenu3,win=DigitizerView,pos={xOffset+xShiftPopup,yOffset-yShimPopup},bodyWidth=70
	PopupMenu DACChannelModePopupMenu3,win=DigitizerView,proc=DigitizerContDACModePopup
	SetVariable dacGain3SetVariable,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV,yOffset},size={70,15},proc=DigitizerContDACGainSV,title="Gain:"
	SetVariable dacGain3SetVariable,win=DigitizerView,format="%g",limits={0.0001,10000,0}
	TitleBox dacGain3UnitsTitleBox,win=DigitizerView,pos={xOffset+xShiftPopup+xShiftSV+xShiftUnits,yOffset},frame=0
	
	// Load, save buttons
	xOffset=300
	yOffset=144
	Button readgain_button,win=DigitizerView,pos={xOffset,yOffset},size={120,25},proc=DigitizerContLoadSettingsButton,title="Load settings from file"
	Button savegain_button,win=DigitizerView,pos={xOffset,yOffset+30},size={120,25},proc=DigitizerContSaveSettingsButton,title="Save settings to file"
	
	// Prompt self to update values based on the model
	DigitizerViewUpdate()
	
	// Restore the original data folder
	SetDataFolder savedDF
End

Function DigitizerViewUpdate()
	// If the window doesn't exist, nothing to do
	if (!PanelExists("DigitizerView"))
		return 0		// Have to return something
	endif

	// Change to the Digitizer data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	// Declare the DF vars we need
	WAVE adcMode
	WAVE dacMode
	NVAR nADCChannels
	NVAR nDACChannels
	NVAR nTTLChannels

	// Sync all the ADC-related controls
	String listOfChannelModes=DigitizerModelGetChanModeList()
	String listOfChannelModesFU="\""+listOfChannelModes+"\""	
	String controlName
	Variable i
	for (i=0; i<nADCChannels; i+=1)
		// Channel type (current, voltage, etc.)
		controlName=sprintf1v("ADCChannelModePopupMenu%d", i)
		PopupMenu $controlName,win=DigitizerView,value=#listOfChannelModesFU
		PopupMenu $controlName,win=DigitizerView,mode=adcMode[i]+1
		// Channel gain
		DigitizerViewADCModeChanged(i)
	endfor

	// Sync all the DAC-related controls
	for (i=0;i<nDACChannels;i+=1)
		// Channel type (current, voltage, etc.)
		controlName=sprintf1v("DACChannelModePopupMenu%d", i)
		PopupMenu $controlName,win=DigitizerView,value=#listOfChannelModesFU
		PopupMenu $controlName,win=DigitizerView,mode=dacMode[i]+1
		// Channel gain
		DigitizerViewDACModeChanged(i)
	endfor
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function DigitizerViewADCModeChanged(i)
	Variable i 	// ADC channel index

	// If the window doesn't exist, nothing to do
	if (!PanelExists("DigitizerView"))
		return 0		// Have to return something
	endif

	Variable adcGain=DigitizerModelGetADCGain(i)
	String adcModeName=DigitizerModelGetADCModeName(i)

	String popupMenuName=sprintf1v("ADCChannelModePopupMenu%d",i)
	PopupMenu $popupMenuName,win=DigitizerView,popmatch=adcModeName

	String setVariableName=sprintf1v("adcGain%dSetVariable",i)
	SetVariable $setVariableName,win=DigitizerView,value=_NUM:adcGain

	String titleBoxName=sprintf1v("adcGain%dUnitsTitleBox",i)
	TitleBox $titleBoxName,win=DigitizerView,title=DigitizerModelADCGainUnits(i)
End

Function DigitizerViewDACModeChanged(i)
	Variable i 	// DAC channel index

	// If the window doesn't exist, nothing to do
	if (!PanelExists("DigitizerView"))
		return 0		// Have to return something
	endif

	Variable dacGain=DigitizerModelGetDACGain(i)		// (native units)/V
	String dacModeName=DigitizerModelGetDACModeName(i)

	String popupMenuName=sprintf1v("DACChannelModePopupMenu%d",i)
	PopupMenu $popupMenuName,win=DigitizerView,popmatch=dacModeName

	String setVariableName=sprintf1v("dacGain%dSetVariable",i)
	SetVariable $setVariableName,win=DigitizerView,value=_NUM:dacGain

	String titleBoxName=sprintf1v("dacGain%dUnitsTitleBox",i)
	TitleBox $titleBoxName,win=DigitizerView,title=DigitizerModelDACGainUnits(i)
End

