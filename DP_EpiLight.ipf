//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function EpiLightConstructor()
	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_EpiLight"))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)

	// Make a new DF, switch to it
	NewDataFolder /O/S root:DP_EpiLight

	// Instance vars
	Variable /G isOn=0	// boolean
	Variable /G ttlOutputIndex=3	// the TTL channel to which the light is hooked up
	
	// Restore the original data folder
	SetDataFolder savedDF	
End



Function EpiLightSetIsOn(value)
	Variable value
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR isOn
	NVAR ttlOutputIndex
	isOn=value
	SamplerSetTTLOutput(ttlOutputIndex,isOn)
	SetDataFolder savedDF	
End



Function EpiLightGetIsOn()	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR isOn	
	Variable value=isOn
	SetDataFolder savedDF	
	return value
End



Function EpiLightSetTTLOutputIndex(newValue)
	Variable newValue
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR ttlOutputIndex
	NVAR isOn
	ttlOutputIndex=newValue
	SamplerSetTTLOutput(ttlOutputIndex,isOn)
	SetDataFolder savedDF	
End



Function EpiLightGetTTLOutputIndex()	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR ttlOutputIndex
	Variable value=ttlOutputIndex
	SetDataFolder savedDF	
	return value
End
