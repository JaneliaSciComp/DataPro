//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method, strict wave access

Function DigitizerContConstructor()
	DigitizerModelConstructor()
	DigitizerViewConstructor()
End

Function DigitizerContADCModePopup(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	Variable iChannel
	
	iChannel=str2num(ctrlName[strlen(ctrlName)-1])
	DigitizerContSetADCMode(iChannel,popNum-1)  // Call the method that does the work
	SwitcherViewUpdate()
	ASwitcherViewUpdate()
End

Function DigitizerContDACModePopup(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	Variable iChannel
	
	iChannel=str2num(ctrlName[strlen(ctrlName)-1])
	DigitizerContSetDACMode(iChannel,popNum-1)  // Call the method that actually does the work
	SwitcherViewUpdate()
	ASwitcherViewUpdate()
End

Function DigitizerContSetADCMode(iChannel,mode)
	Variable iChannel, mode
	DigitizerModelSetADCMode(iChannel,mode)  // notify the model
	DigitizerViewADCModeChanged(iChannel)  // notify the view
End

Function DigitizerContSetADCModeName(iChannel,modeName)
	Variable iChannel
	String modeName
	DigitizerModelSetADCModeName(iChannel,modeName)  // notify the model
	DigitizerViewADCModeChanged(iChannel)  // notify the view
End

Function DigitizerContSetDACMode(iChannel,mode)
	Variable iChannel, mode
	DigitizerModelSetDACMode(iChannel,mode)  // notify the model
	DigitizerViewDACModeChanged(iChannel)  // notify the view
	// Notify the TestPulser, b/c it may need to change units
	TestPulserContDigitizerChanged()
	// Notify the SweeperController, b/c it may need to change units
	SweepControllerDigitizerChanged()
End

Function DigitizerContSetDACModeName(iChannel,modeName)
	Variable iChannel
	String modeName
	DigitizerModelSetDACModeName(iChannel,modeName)  // notify the model
	DigitizerViewDACModeChanged(iChannel)  // notify the view
	// Notify the TestPulser, b/c it may need to change units
	TestPulserContDigitizerChanged()
	// Notify the SweeperController, b/c it may need to change units
	SweepControllerDigitizerChanged()
End

Function DigitizerContLoadSettingsButton(ctrlName) : ButtonControl
	String ctrlName

	// Change to the Digitizer data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	// Declare the DF vars we need
	WAVE adcMode
	WAVE adcGainAll
	WAVE dacMode
	WAVE dacGainAll
	NVAR nChannelModes
	NVAR nADCChannels
	NVAR nDACChannels

	// Prompt user for a filename
	String fileFilters="DataPro Digitizer Settings Files (*.dds):.dds;"
	fileFilters += "All Files:.*;"
	Variable settingsFile
	Open /D /R /F=fileFilters settingsFile	// Doesn't actually open, just brings up file chooser
	String fileNameAbs=S_fileName
	Variable userCancelled=( strlen(fileNameAbs)==0 )
	if (!userCancelled)
		// Actually open the file
		Open /Z /R settingsFile as fileNameAbs
		Variable fileOpenedSuccessfully=(V_flag==0)
		if (fileOpenedSuccessfully)
			// Read the ADC settings from the file, set in model
			String oneLine
			Variable i,j
			for (i=0; i<nADCChannels; i+=1)
				FReadLine settingsFile, oneLine
				adcMode[i]=str2num(oneLine)
				for (j=0; j<nChannelModes; j+=1)
					FReadLine settingsFile, oneLine
					adcGainAll[i][j]=str2num(oneLine)
				endfor
			endfor
			// Read the DAC settings from the file, set in model
			for (i=0; i<nDACChannels; i+=1)
				FReadLine settingsFile, oneLine
				dacMode[i]=str2num(oneLine)
				for (j=0; j<nChannelModes; j+=1)
					FReadLine settingsFile, oneLine
					dacGainAll[i][j]=str2num(oneLine)
				endfor
			endfor
			// Close the file
			Close settingsFile
			// Notify the view that the model has changed
			DigitizerViewUpdate()
			// Also notify the TestPulser, b/c it might need to change units
			TestPulserContDigitizerChanged()
			// Also notify the Sweeper, b/c it might need to change units, too
			SweepControllerDigitizerChanged()
		endif
	endif
	
	// Restore the original DF
	SetDataFolder savedDF	
End

Function DigitizerContSaveSettingsButton(ctrlName) : ButtonControl
	String ctrlName

	// Change to the Digitizer data folder
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer

	// Declare the DF vars we need
	WAVE adcGainAll
	WAVE dacGainAll
	WAVE adcMode, dacMode
	NVAR nChannelModes
	NVAR nADCChannels
	NVAR nDACChannels

	// Prompt user for a filename
	String fileFilters="DataPro Digitizer Settings Files (*.dds):.dds;"
	fileFilters += "All Files:.*;"
	Variable settingsFile
	Open /D  /F=fileFilters settingsFile		// Doesn't actually open, just brings up file chooser
	String fileNameAbs=S_fileName
	Variable userCancelled=( strlen(fileNameAbs)==0 )
	if (!userCancelled)
		// Actually open the file
		Open /Z settingsFile as fileNameAbs
		Variable fileOpenedSuccessfully=(V_flag==0)
		if (fileOpenedSuccessfully)
			// Save the ADC parameters
			Variable i,j
			for (i=0;i<nADCChannels;i+=1)
				fprintf settingsFile, "%d\r", adcMode[i]
				for (j=0; j<nChannelModes; j+=1)
					fprintf settingsFile, "%g\r", adcGainAll[i][j]
				endfor
			endfor
			
			// Save the DAC parameters
			String controlName
			for (i=0;i<nDACChannels;i+=1)
				fprintf settingsFile, "%d\r", dacMode[i]
				for (j=0; j<nChannelModes; j+=1)
					fprintf settingsFile, "%g\r", dacGainAll[i][j]
				endfor
			endfor
			
			// Close the file
			Close settingsFile
		else
			// unable to open the file
			DoAlert /T="Unable to open file" 0, "Unable to open file."
		endif
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function DigitizerContADCGainSV(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	Variable i=str2num(ctrlName[7])  // ADC channel index
	DigitizerModelSetADCGain(i,varNum);
End

Function DigitizerContDACGainSV(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	Variable i=str2num(ctrlName[7])  // DAC channel index
	DigitizerModelSetDACGain(i,varNum)
End


