#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//
// Controller methods
//

Function SwitcherContConstructor()
	SwitcherModelConstructor()
	SwitcherViewConstructor()
End

//Function SwitcherContDigitizerEtcChngd()
//	// Called when the digitizer or the sweeper are changed.
//	//SwitcherModelDigitizerEtcChngd()
//	SwitcherViewUpdate()
//End

Function SwitcherContRadioButton(controlName,checked) : CheckBoxControl
	String controlName
	Variable checked
	// Figure out CC vs VC, and the amplifier number, from the button control name
	String regExp="^amp(.)(.*)CB$"
	String amplifierIndexAsString, modeStringRaw
	SplitString /E=(regExp) controlName, amplifierIndexAsString, modeStringRaw
	Variable amplifierIndex=str2num(amplifierIndexAsString)

	// Determine the mode string from the "raw" mode string	
	String modeString
	if ( AreStringsEqual(modeStringRaw,"CurrentClamp") )
		modeString="Current Clamp"
	elseif ( AreStringsEqual(modeStringRaw,"VoltageClamp") )
		modeString="Voltage Clamp"
	else
		modeString=modeStringRaw
	endif
	
	// Update the switcher itself
	//SwitcherModelSetMode(amplifierIndex,modeString)

	// Notify the other objects that need to change
	SwitcherContSetDigitzrEtcToMode(amplifierIndex,modeString)

	// Notify ourselves that the other object have changed (which will update the view)
	SwitcherViewUpdate()	
	ASwitcherViewUpdate()
End

Function SwitcherContTestPulseButton(controlName) : ButtonControl
	String controlName
	
	// Figure out the amplifier number from the button control name
	String regExp="^amp(.)TestPulseButton$"
	String amplifierIndexAsString
	SplitString /E=(regExp) controlName, amplifierIndexAsString
	Variable amplifierIndex=str2num(amplifierIndexAsString)
	Variable dacIndex=SwitcherModelGetOutputDACIndex(amplifierIndex)
	Variable adcIndex=SwitcherModelGetADCIndex(amplifierIndex)
	TestPulserContConstructor()		// Make sure the test pulser exists
	TestPulserContSetDACIndex(dacIndex)
	TestPulserContSetADCIndex(adcIndex)
	TestPulserContStart()
End

Function SwitcherContSetVariable(controlName,newValue,varStr,varName) : SetVariableControl
	String controlName
	Variable newValue	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

	// Figure out which setvariable, and the amplifier number, from the button control name,
	// And update the model.
	String regExp="^amp(.)(.*)SV$"
	String amplifierIndexAsString, variableNameRaw
	SplitString /E=(regExp) controlName, amplifierIndexAsString, variableNameRaw
	Variable amplifierIndex=str2num(amplifierIndexAsString)
	if ( AreStringsEqual(variableNameRaw,"VoltageADC") )
		SwitcherModelSetVoltageADCIndex(amplifierIndex,newValue)
	endif
	if ( AreStringsEqual(variableNameRaw,"CurrentADC") )
		SwitcherModelSetCurrentADCIndex(amplifierIndex,newValue)
	endif
	if ( AreStringsEqual(variableNameRaw,"OutputDAC") )
		SwitcherModelSetOutputDACIndex(amplifierIndex,newValue)
	endif

	// Update the view
	SwitcherViewUpdate()
End

Function SwitcherContSetDigitzrEtcToMode(amplifierIndex,modeName)
	// Set the digitizer and sweeper to be consistent with the given modeName.
	// This is a private method.
	Variable amplifierIndex
	String modeName

	// Set the DAC channel appropriately
	Variable dacIndex=SwitcherModelGetOutputDACIndex(amplifierIndex)
	// Determine the ADC channel used for recording voltage for this amp
	Variable adcIndexCurrent=SwitcherModelGetCurrentADCIndex(amplifierIndex)
	// Determine the ADC channel used for recording current for this amp
	Variable adcIndexVoltage=SwitcherModelGetVoltageADCIndex(amplifierIndex)
	//String modeName=SwitcherModelGetMode(amplifierIndex)
	if ( AreStringsEqual(modeName,"Current Clamp") )
		SweeperContSetDACChannelOn(dacIndex,1)
		DigitizerContSetDACModeName(dacIndex,"Current")
		SweeperContSetADCChannelOn(adcIndexVoltage,1)	// Turn channels on before off, b/c can't turn all channels off
		DigitizerContSetADCModeName(adcIndexVoltage,"Voltage")
		SweeperContSetADCChannelOn(adcIndexCurrent,0)
	elseif ( AreStringsEqual(modeName,"Voltage Clamp") )
		SweeperContSetDACChannelOn(dacIndex,1)
		DigitizerContSetDACModeName(dacIndex,"Voltage")
		SweeperContSetADCChannelOn(adcIndexCurrent,1)
		DigitizerContSetADCModeName(adcIndexCurrent,"Current")
		SweeperContSetADCChannelOn(adcIndexVoltage,0)
	elseif ( AreStringsEqual(modeName,"Unused") )
		SweeperContSetDACChannelOn(dacIndex,0)
		SweeperContSetADCChannelOn(adcIndexCurrent,0)
		SweeperContSetADCChannelOn(adcIndexVoltage,0)
	endif
End



//
// View methods
//

Function SwitcherViewConstructor() : Graph
	// If the panel already exists, just bring it forward
	if (PanelExists("SwitcherView"))
		DoWindow /F SwitcherView
		return 0
	endif

	// Draw the panel
	SwitcherViewLayout()
	
	// Sync the panel to the model
	SwitcherViewUpdate()
End

Function SwitcherViewLayout()
	// Draws the Switcher panel
	
	// Make the GroupBoxes, one per amplifier
	// (the first iteration actually makes the panel, too)
	Variable nAmplifiers=SwitcherModelGetNumAmplifiers()
	Variable amplifierIndex
	for (amplifierIndex=1; amplifierIndex<=nAmplifiers; amplifierIndex+=1)
		SwitcherViewLayoutGroup(amplifierIndex)
	endfor
End


Function SwitcherViewLayoutGroup(amplifierIndex)
	Variable amplifierIndex	// Amplifier index

	// Pads are named after the thing _inside_ the padding
	// The size of a "cluster" includes the size of the padding around the cluster.
	// The button "cluster" contains only the one button

	// Parameters controlling the placement of the panel 
	Variable panelXOffset=720
	Variable panelYOffset=54

	// Set the parameters that determine the layout of each group box
	Variable nAmplifiers=SwitcherModelGetNumAmplifiers()
	Variable nSetVariables=3
	Variable tbWidth=70		// tb==titlebox
	Variable tbHeight=16
	Variable tbShimHeight=1
	Variable svWidth=30
	Variable svHeight=16
	Variable svRowHeight=max(tbHeight,svHeight)
	Variable interSVRowHeight=5
	Variable svRowClusterTopPadHeight=10
	Variable svRowClusterPadWidth=20
	Variable svRowWidth=tbWidth+svWidth
	Variable svRowClusterHeight=nSetVariables*svRowHeight+(nSetVariables-1)*interSVRowHeight+svRowClusterTopPadHeight
	Variable svRowClusterWidth=svRowWidth+2*svRowClusterPadWidth

	Variable svRowClusterButtonSpaceHeight=20

	Variable buttonWidth=90
	Variable buttonHeight=25
	Variable buttonPadWidth=10
	Variable buttonBottomPadHeight=15
	Variable buttonClusterWidth=buttonWidth+2*buttonPadWidth
	Variable buttonClusterHeight=buttonHeight+buttonBottomPadHeight

	// The "left column" consists of the svCluster and the buttonCluster, one on top of the other
	Variable leftColumnWidth=max(svRowClusterWidth,buttonClusterWidth)
	Variable leftColumnHeight=svRowClusterHeight+svRowClusterButtonSpaceHeight+buttonClusterHeight

	Variable nRadioButtons=3
	Variable rbHeight=14
	Variable rbWidth=90
	Variable interRBHeight=7
	Variable rbClusterRightPadWidth=25
	Variable rbClusterPadHeight=0	
	Variable rbClusterWidth=rbWidth+rbClusterRightPadWidth
	Variable rbClusterHeight=nRadioButtons*rbHeight+(nRadioButtons-1)*interRBHeight+2*rbClusterPadHeight

	Variable interColumnSpaceWidth=10

	Variable groupWidth=leftColumnWidth+interColumnSpaceWidth+rbClusterWidth
	Variable groupInnerHeight=max(leftColumnHeight,rbClusterHeight)
	Variable groupTitleHeight=14	// Approximate height of text for each groupbox
	Variable groupOuterHeight=groupInnerHeight+groupTitleHeight
	
	Variable interGroupSpaceHeight=8
	Variable groupClusterPadWidth=8
	Variable groupClusterPadHeight=8
	Variable panelWidth=groupWidth+2*groupClusterPadWidth
	Variable panelHeight=nAmplifiers*groupOuterHeight+(nAmplifiers-1)*interGroupSpaceHeight+2*groupClusterPadHeight
	
	Variable groupXOffset=groupClusterPadWidth
	Variable groupYOffset=groupClusterPadHeight+(amplifierIndex-1)*(groupOuterHeight+interGroupSpaceHeight)
	Variable xOffset=groupXOffset
	Variable yOffset=groupYOffset

	Variable nADCChannels=DigitizerModelGetNumADCChans()
	Variable nDACChannels=DigitizerModelGetNumDACChans()

	// If this the first time through, actually make the panel
	if (amplifierIndex==1)
		NewPanel /W=(panelXOffset,panelYOffset,panelXOffset+panelWidth,panelYOffset+panelHeight) /K=1 /N=SwitcherView as "Switcher"
		ModifyPanel /W=SwitcherView fixedSize=1
	endif

	String controlName=sprintf1v("amp%dGroup",amplifierIndex)	
	GroupBox $controlName,win=SwitcherView,pos={xOffset,yOffset},size={groupWidth,groupOuterHeight},title=sprintf1v("Amplifier %d",amplifierIndex)

	xOffset=groupXOffset+(leftColumnWidth-svRowWidth)/2
	yOffset=groupYOffset+groupTitleHeight+svRowClusterTopPadHeight
	controlName=sprintf1v("amp%dVoltageADCTB",amplifierIndex)	
	TitleBox $controlName, win=SwitcherView, pos={xOffset,yOffset+tbShimHeight}, size={tbWidth,tbHeight}, frame=0, title="Voltage ADC:"
	controlName=sprintf1v("amp%dVoltageADCSV",amplifierIndex)
	SetVariable $controlName, win=SwitcherView, pos={xOffset+tbWidth,yOffset}, size={svWidth,svHeight}, limits={0,nADCChannels-1,1}, proc=SwitcherContSetVariable, title=""

	yOffset+=svRowHeight+interSVRowHeight
	controlName=sprintf1v("amp%dCurrentADCTB",amplifierIndex)
	TitleBox $controlName, win=SwitcherView, pos={xOffset,yOffset+tbShimHeight}, size={tbWidth,tbHeight}, frame=0, title="Current ADC:"
	controlName=sprintf1v("amp%dCurrentADCSV",amplifierIndex)
	SetVariable $controlName, win=SwitcherView, pos={xOffset+tbWidth,yOffset}, size={svWidth,svHeight}, limits={0,nADCChannels-1,1}, proc=SwitcherContSetVariable, title=""

	yOffset+=svRowHeight+interSVRowHeight
	controlName=sprintf1v("amp%dOutputDACTB",amplifierIndex)
	TitleBox $controlName, win=SwitcherView, pos={xOffset,yOffset+tbShimHeight}, size={tbWidth,tbHeight}, frame=0, title="Output DAC:"
	controlName=sprintf1v("amp%dOutputDACSV",amplifierIndex)
	SetVariable $controlName, win=SwitcherView, pos={xOffset+tbWidth,yOffset}, size={svWidth,svHeight}, limits={0,nDACChannels-1,1}, proc=SwitcherContSetVariable, title=""
	
	xOffset=groupXOffset+(leftColumnWidth-buttonWidth)/2
	yOffset=groupYOffset+groupTitleHeight+svRowClusterHeight+svRowClusterButtonSpaceHeight
	controlName=sprintf1v("amp%dTestPulseButton",amplifierIndex)
	Button $controlName, win=SwitcherView,pos={xOffset,yOffset},size={buttonWidth,buttonHeight},proc=SwitcherContTestPulseButton,title="Test Pulse"
	
	xOffset=groupXOffset+leftColumnWidth+interColumnSpaceWidth
	yOffset=	groupYOffset+groupTitleHeight+(groupInnerHeight-rbClusterHeight)/2
	controlName=sprintf1v("amp%dCurrentClampCB",amplifierIndex)
	CheckBox $controlName, win=SwitcherView, pos={xOffset,yOffset}, size={rbWidth,rbHeight},mode=1, proc=SwitcherContRadioButton, title="Current Clamp"
	yOffset+=rbHeight+interRBHeight
	controlName=sprintf1v("amp%dVoltageClampCB",amplifierIndex)
	CheckBox $controlName, win=SwitcherView, pos={xOffset,yOffset}, size={rbWidth,rbHeight}, mode=1, proc=SwitcherContRadioButton, title="Voltage Clamp"
	yOffset+=rbHeight+interRBHeight
	controlName=sprintf1v("amp%dUnusedCB",amplifierIndex)
	CheckBox $controlName, win=SwitcherView, pos={xOffset,yOffset}, size={rbWidth,rbHeight}, mode=1, proc=SwitcherContRadioButton, title="Unused"
End

Function SwitcherViewUpdate()
	if ( !SwitcherModelExists() )
		return 0		// Have to return something
	endif
	if (!PanelExists("SwitcherView"))
		return 0		// Have to return something
	endif	
	Variable nAmplifiers=SwitcherModelGetNumAmplifiers()
	Variable amplifierIndex
	for (amplifierIndex=1; amplifierIndex<=nAmplifiers; amplifierIndex+=1)
		SwitcherViewUpdateGroup(amplifierIndex)
	endfor
End

Function SwitcherViewUpdateGroup(amplifierIndex)
	Variable amplifierIndex	// Amplifier index (1st element is element 1)

	if ( !SwitcherModelExists() )
		return 0		// Have to return something
	endif
	if (!PanelExists("SwitcherView"))
		return 0		// Have to return something
	endif	

	String savedDF=GetDataFolder(1)
	SetDataFolder root:Switcher

	WAVE voltageADCIndex
	WAVE currentADCIndex
	WAVE outputDACIndex
	//WAVE /T amplifierMode
	
	String amplifierMode=SwitcherModelGetMode(amplifierIndex)
	Variable j=amplifierIndex-1		// Amplifier index (1st element is element 0)
	String controlName=sprintf1v("amp%dVoltageADCSV",amplifierIndex)
	SetVariable $controlName, win=SwitcherView, value= _NUM:voltageADCIndex[j]
	controlName=sprintf1v("amp%dCurrentADCSV",amplifierIndex)
	SetVariable $controlName, win=SwitcherView, value= _NUM:currentADCIndex[j]
	controlName=sprintf1v("amp%dOutputDACSV",amplifierIndex)
	SetVariable $controlName, win=SwitcherView, value= _NUM:outputDACIndex[j]
	controlName=sprintf1v("amp%dCurrentClampCB",amplifierIndex)
	CheckBox $controlName, win=SwitcherView, value= (AreStringsEqual(amplifierMode,"Current Clamp"))
	controlName=sprintf1v("amp%dVoltageClampCB",amplifierIndex)
	CheckBox $controlName, win=SwitcherView, value= (AreStringsEqual(amplifierMode,"Voltage Clamp")) 
	controlName=sprintf1v("amp%dUnusedCB",amplifierIndex)
	CheckBox $controlName, win=SwitcherView, value= (AreStringsEqual(amplifierMode,"Unused"))
	// Gray the test pulse if the mode is not ("Current Clamp" or "Voltage Clamp")
	Variable buttonEnabled= ( AreStringsEqual(amplifierMode,"Current Clamp") || AreStringsEqual(amplifierMode,"Voltage Clamp") )
	controlName=sprintf1v("amp%dTestPulseButton",amplifierIndex)
	Button $controlName, win=SwitcherView, disable=2*(1-buttonEnabled)

	SetDataFolder savedDF		
End



//
// Model methods
//

Function SwitcherModelConstructor()
	// Construct the model

	// if the DF already exists, nothing to do
	if (SwitcherModelExists())
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /S root:Switcher
	
	// Create the instance variables
	Variable /G nAmplifiers=4
	Make /N=(nAmplifiers) voltageADCIndex={0,2,4,6}
	Make /N=(nAmplifiers) currentADCIndex={1,3,5,7}
	Make /N=(nAmplifiers) outputDACIndex={0,1,2,3}
	//Make /T /N=(nAmplifiers) amplifierMode
	
	//SwitcherModelDigitizerEtcChngd()		// Set the amplifier mode based on the current state of the digitizer and sweeper

	// Restore the original data folder
	SetDataFolder savedDF
End

//Function SwitcherModelDigitizerEtcChngd()
//	// Updates the switcher mode to be consistent with the digitizer and sweeper state.
//	Variable nAmplifiers=SwitcherModelGetNumAmplifiers()
//	Variable amplifierIndex
//	for (amplifierIndex=1; amplifierIndex<=nAmplifiers; amplifierIndex+=1)
//		SwitcherModelSyncModeToOthers(amplifierIndex)
//	endfor
//End

//Function SwitcherModelSyncModeToOthers(amplifierIndex)
//	// Updates the switcher mode for the given amplifier to be consistent with the digitizer and sweeper state.
//	Variable amplifierIndex
//	
//	String amplifierMode=SwitcherModelGetMode(amplifierIndex)
//	
//	// Set the mode
//	SwitcherModelSetMode(amplifierIndex,amplifierMode)
//End

Function SwitcherModelGetNumAmplifiers()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:Switcher

	NVAR nAmplifiers
	Variable result=nAmplifiers
		
	SetDataFolder savedDF		
	
	return result
End

Function SwitcherModelGetOutputDACIndex(amplifierIndex)
	Variable amplifierIndex
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:Switcher

	WAVE outputDACIndex
	Variable result=outputDACIndex[amplifierIndex-1]
		
	SetDataFolder savedDF			

	return result
End

Function SwitcherModelGetCurrentADCIndex(amplifierIndex)
	Variable amplifierIndex
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:Switcher

	WAVE currentADCIndex
	Variable result=currentADCIndex[amplifierIndex-1]
		
	SetDataFolder savedDF			
	
	return result
End

Function SwitcherModelGetVoltageADCIndex(amplifierIndex)
	Variable amplifierIndex
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:Switcher

	WAVE voltageADCIndex
	Variable result=voltageADCIndex[amplifierIndex-1]
		
	SetDataFolder savedDF			
	
	return result
End

Function SwitcherModelGetADCIndex(amplifierIndex)
	Variable amplifierIndex
	
	String modeString=SwitcherModelGetMode(amplifierIndex)
	Variable result
	if ( AreStringsEqual(modeString,"Voltage Clamp") )
		// If voltage clamp specified, return the current ADC
		result=SwitcherModelGetCurrentADCIndex(amplifierIndex)
	else
		// If any other state, return the voltage ADC
		// There is no right answer if the mode is "Unused" or "Other", so why not?
		result=SwitcherModelGetVoltageADCIndex(amplifierIndex)
	endif
	
	return result
End

//Function SwitcherModelSetMode(amplifierIndex,modeString)
//	Variable amplifierIndex
//	String modeString
//	
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:Switcher
//
//	WAVE /T amplifierMode
//	amplifierMode[amplifierIndex-1]=modeString
//		
//	SetDataFolder savedDF		
//End

//Function /S SwitcherModelGetMode(amplifierIndex)
//	Variable amplifierIndex
//
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:Switcher
//
//	WAVE /T amplifierMode
//	
//	Variable j=amplifierIndex-1		// Amplifier index (1st element is element 0)
//	String result=amplifierMode[j]
//	
//	SetDataFolder savedDF		
//
//	return result
//End

Function SwitcherModelSetOutputDACIndex(amplifierIndex,newValue)
	Variable amplifierIndex
	Variable newValue
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:Switcher

	WAVE outputDACIndex
	outputDACIndex[amplifierIndex-1]=newValue
		
	SetDataFolder savedDF			
End

Function SwitcherModelSetCurrentADCIndex(amplifierIndex,newValue)
	Variable amplifierIndex
	Variable newValue
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:Switcher

	WAVE currentADCIndex
	currentADCIndex[amplifierIndex-1]=newValue
		
	SetDataFolder savedDF			
End

Function SwitcherModelSetVoltageADCIndex(amplifierIndex,newValue)
	Variable amplifierIndex
	Variable newValue
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:Switcher

	WAVE voltageADCIndex
	voltageADCIndex[amplifierIndex-1]=newValue
		
	SetDataFolder savedDF			
End

Function /S SwitcherModelGetMode(amplifierIndex)
	// Queries the digitizer and sweeper to determine the current switcher mode for the
	// give amplifier
	Variable amplifierIndex
	
	Variable dacIndex=SwitcherModelGetOutputDACIndex(amplifierIndex)
	Variable adcIndexCurrent=SwitcherModelGetCurrentADCIndex(amplifierIndex)
	Variable adcIndexVoltage=SwitcherModelGetVoltageADCIndex(amplifierIndex)

	// Probe the digitizer, sweeper, figure out what the amplifier mode is
	String amplifierMode="Other"		// default to this
	if ( SweeperGetDACOn(dacIndex) )
		// The DAC channel is on
		String dacModeName=DigitizerModelGetDACModeName(dacIndex)
		if ( AreStringsEqual(dacModeName,"Current") ) 
			if ( SweeperGetADCOn(adcIndexVoltage) )
				if ( AreStringsEqual(DigitizerModelGetADCModeName(adcIndexVoltage),"Voltage") )
					// Note that we don't check to see if the current ADC is turned off, as it
					// will be if the user actually clicks on the "Current Clamp" radiobutton.
					// This is by design, but may turn out to be a bad design.  I'll have to wait and see
					// if this causes any confusion with the users.
					amplifierMode="Current Clamp"
				endif
			endif			
		elseif ( AreStringsEqual(dacModeName,"Voltage") )
			// Looks like amplifier mode is voltage-clamp, but verify that everything else is in order
			if ( SweeperGetADCOn(adcIndexCurrent) )
				if ( AreStringsEqual(DigitizerModelGetADCModeName(adcIndexCurrent),"Current") )
					// Note that we don't check to see if the voltage ADC is turned off, as it
					// will be if the user actually clicks on the "Voltage Clamp" radiobutton.
					// This is by design, but may turn out to be a bad design.  I'll have to wait and see
					// if this causes any confusion with the users.
					amplifierMode="Voltage Clamp"
				endif
			endif			
		endif	
	else
		// The DAC channel is off, so the only possible switcher modes are
		// Unused and Other.
		if ( !SweeperGetADCOn(adcIndexVoltage) && !SweeperGetADCOn(adcIndexCurrent) )
			amplifierMode="Unused"
		endif
	endif
	
	// Set the mode
	return amplifierMode
End



// Not sure where this belongs, but it's useful
Function SwitcherModelExists()
	return (DataFolderExists("root:Switcher"))
End


