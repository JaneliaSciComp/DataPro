//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=1		// Use modern global access method.

Function DigitizerModelConstructor()
	//	USERS SHOULD NOT EDIT ANYTHING HERE
	//	EDIT ONLY IN THE MyVariables FILE
	
	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_Digitizer"))
		return 0		// have to return something
	endif
	
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /O /S root:DP_Digitizer
	
	// dimensions
	Variable /G nADCChannels=8
	Variable /G nDACChannels=4
	Variable /G nTTLChannels=4
	
	// Each ADC and DAC channel has a "mode".  Currently, this described whether it's a 
	// current channel or a voltage channel, but other modes may be added in the future.
	// Technically, the channel mode is either 0 or 1, and the channel's mode name is "Current" or
	// "Voltage"
	Variable /G nChannelModes=2		// current, voltage
	
	// Current and voltage units
	//String /G unitsCurrent="pA"
	//String /G unitsVoltage="mV"
	Make /O /T /N=(nChannelModes) modeNameFromMode={"Current","Voltage"}	
	Make /O /T /N=(nChannelModes) unitsFromMode={"pA","mV"}

	// initial mode of ADC, DAC channels
	Make /O /N=(nADCChannels) adcMode={1,1,1,1,1,1,1,1}	// all voltage channels
	Make /O /N=(nDACChannels) dacMode={0,0,0,0}			// all current channels 

	// Make waves to hold adc and dac gains
	Make /O /N=(nADCChannels,nChannelModes) adcGainAll={ {0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,0.0001}, {0.01,0.01,0.01,0.01,0.01,0.01,0.01,0.01} }
	Make /O /N=(nDACChannels,nChannelModes) dacGainAll={ {10000,10000,10000,10000}, {20,20,20,20} }

	// Do the usr customization
	SetupDigitizerForUser()  // Allows user to set desired channel gains, etc.
	
	// Restore the original data folder
	SetDataFolder savedDF
End

Function /S DigitizerModelADCGainUnits(i)
	// Returns the units string for the given ADC channel.
	Variable i

	// Switch to the digitizer data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	// Core of the method
	WAVE adcMode
	WAVE /T unitsFromMode
	String out=sprintf1s("V/%s",unitsFromMode[adcMode[i]])

	// Restore the data folder
	SetDataFolder savedDF
	
	// Return	
	return out
End

Function /S DigitizerModelDACGainUnits(i)
	// Returns the units string for the given DAC channel
	Variable i

	// Switch to the digitizer data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	// Core of the method
	WAVE dacMode
	WAVE /T unitsFromMode
	String out=sprintf1s("%s/V",unitsFromMode[dacMode[i]])

	// Restore the data folder
	SetDataFolder savedDF
	
	// Return	
	return out
End

Function DigitizerModelSetADCMode(iChannel,mode)
	// Switches the indicated ADC channel to the given mode.
	Variable iChannel, mode
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer
	
	WAVE adcMode
	
	adcMode[iChannel]=mode

	SetDataFolder savedDF
End

Function DigitizerModelSetDACMode(iChannel,mode)
	// Switches the indicated DAC channel to the given mode.
	Variable iChannel, mode

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	WAVE dacMode

	dacMode[iChannel]=mode

	SetDataFolder savedDF
End

Function DigitizerModelGetADCMode(iChannel)
	Variable iChannel
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer
	
	WAVE adcMode

	Variable mode=adcMode[iChannel]

	SetDataFolder savedDF
	
	return mode
End

Function /S DigitizerModelGetADCModeName(iChannel)
	// Returns the units string for an ADC of the given mode.
	Variable iChannel

	// Switch to the digitizer data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	// Core of the method
	WAVE adcMode
	WAVE /T modeNameFromMode
	String modeName=modeNameFromMode[adcMode[iChannel]]

	// Restore the data folder
	SetDataFolder savedDF
	
	// Return	
	return modeName
End

Function /S DigitizerModelGetADCUnitsString(iChannel)
	// Returns the units string for an ADC of the given mode.
	Variable iChannel

	// Switch to the digitizer data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	// Core of the method
	WAVE adcMode
	WAVE /T unitsFromMode
	String unitsString=unitsFromMode[adcMode[iChannel]]

	// Restore the data folder
	SetDataFolder savedDF
	
	// Return	
	return unitsString
End

Function DigitizerModelGetDACMode(iChannel)
	Variable iChannel
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer
	
	WAVE dacMode

	Variable mode=dacMode[iChannel]

	SetDataFolder savedDF
	
	return mode
End

Function /S DigitizerModelGetDACModeName(iChannel)
	Variable iChannel
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer
	
	WAVE dacMode
	WAVE /T modeNameFromMode

	Variable mode=dacMode[iChannel]
	String modeString=modeNameFromMode[mode]

	SetDataFolder savedDF
	
	return modeString
End

Function /S DigitizerModelGetDACUnitsString(iChannel)
	Variable iChannel
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer
	
	WAVE dacMode
	WAVE /T unitsFromMode

	Variable mode=dacMode[iChannel]
	String unitsString=unitsFromMode[mode]

	SetDataFolder savedDF
	
	return unitsString
End

Function DigitizerModelGetADCGain(i)
	// Gets the current gain on ADC channel i, taking into account the channel mode.
	Variable i

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	WAVE adcMode
	WAVE adcGainAll
	
	Variable adcGain=adcGainAll[i][adcMode[i]]

	SetDataFolder savedDF	

	return adcGain
End

Function DigitizerModelGetDACGain(i)
	// Gets the current gain on DAC channel i, taking into account the channel mode.
	Variable i

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer
	WAVE dacMode
	WAVE dacGainAll
	
	Variable dacGain=dacGainAll[i][dacMode[i]]		// (native units)/V

	SetDataFolder savedDF	

	return dacGain
End

Function DigitizerModelSetADCGain(i,newGain)
	// Sets the current gain on ADC channel i, taking into account the channel mode.
	Variable i, newGain

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	WAVE adcMode
	WAVE adcGainAll
	
	adcGainAll[i][adcMode[i]]=newGain

	SetDataFolder savedDF	
End

Function DigitizerModelSetDACGain(i,newGain)
	// Sets the current gain on DAC channel i, taking into account the channel mode.
	Variable i, newGain

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	WAVE dacMode
	WAVE dacGainAll
	
	dacGainAll[i][dacMode[i]]=newGain		// (native units)/V

	SetDataFolder savedDF	
End

Function DigitizerModelGetADCNtvsPerPnt(iADCChannel)
	// Calculates the input gain (in native units per point) based on the gain for the given 
	// channel and pointsPerVoltADC.
	Variable iADCChannel
	
	// Set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer
	
	// these are the "inputs" to this procedure
	Variable pointsPerVoltADC=32768/10.24		// points/V
	Variable adcGain=DigitizerModelGetADCGain(iADCChannel)		// V/(native unit)
	
	// do what's described above
	Variable result=1/(adcGain*pointsPerVoltADC)		// (native units)/point

	// Restore the DF	
	SetDataFolder savedDF

	// Exit
	return result
End

Function DigitizerModelGetDACPntsPerNtv(iDACChannel)
	// Calculates the output gain (in points per native unit) based on the gain for the given 
	// channel and pointsPerVoltDAC.
	Variable iDACChannel

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	Variable dacGain=DigitizerModelGetDACGain(iDACChannel)		// (native units)/V
	Variable pointsPerVoltDAC=32768/10.24	// points/V
	//NVAR pointsPerVoltDAC	// points/V

	Variable result=pointsPerVoltDAC/dacGain	// points/(native unit)

	SetDataFolder savedDF

	return result
End

Function /S DigitizerModelGetChanModeList()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	NVAR nChannelModes
	WAVE /T modeNameFromMode
	String result=""
	Variable i
	for (i=0; i<nChannelModes; i+=1)
		result+=(modeNameFromMode[i]+";")
	endfor

	SetDataFolder savedDF
	
	return result
End

Function DigitizerModelGetNumADCChans()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	NVAR nADCChannels
	Variable result=nADCChannels

	SetDataFolder savedDF
	
	return result
End

Function DigitizerModelGetNumDACChans()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	NVAR nDACChannels
	Variable result=nDACChannels

	SetDataFolder savedDF
	
	return result
End

Function DigitizerModelGetNumTTLChans()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	NVAR nTTLChannels
	Variable result=nTTLChannels

	SetDataFolder savedDF
	
	return result
End

//Function DigitizerModelGetNumChanModes()
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:DP_Digitizer
//
//	NVAR nChannelModes
//	Variable result=nChannelModes
//
//	SetDataFolder savedDF
//	
//	return result
//End

Function DigitizerModelSetDACModeName(iChannel,modeName)
	// Switches the indicated DAC channel to the given mode.
	Variable iChannel
	String modeName

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	WAVE dacMode
	WAVE /T modeNameFromMode
	NVAR nChannelModes

	Variable mode
	for (mode=0; mode<nChannelModes; mode+=1)
		if ( AreStringsEqual(modeName,modeNameFromMode[mode]) )
			dacMode[iChannel]=mode
			break
		endif
	endfor

	SetDataFolder savedDF
End

Function DigitizerModelSetADCModeName(iChannel,modeName)
	// Switches the indicated ADC channel to the given mode.
	Variable iChannel
	String modeName

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	WAVE adcMode
	WAVE /T modeNameFromMode
	NVAR nChannelModes

	Variable mode
	for (mode=0; mode<nChannelModes; mode+=1)
		if ( AreStringsEqual(modeName,modeNameFromMode[mode]) )
			adcMode[iChannel]=mode
			break
		endif
	endfor

	SetDataFolder savedDF
End

