//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function ImagePlaneSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	ImageBrowserModelSetIFrame(varNum)
	ImageBrowserViewModelEtcChanged()
	//ModifyImage ''#0 plane=(iFrame)
End

Function BlackCountSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	ImageBrowserModelSetBlackCount(varNum)
	ImageBrowserViewModelEtcChanged()
End

Function WhiteCountSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	ImageBrowserModelSetWhiteCount(varNum)
	ImageBrowserViewModelEtcChanged()
End

Function ImageBrowserContScaleButton(ctrlName) : ButtonControl
	String ctrlName
	
	ImageBrowserModelScale()
	ImageBrowserViewModelEtcChanged()
End

Function ImagePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	ImageBrowserModelSetVideo(popStr)
	ImageBrowserViewModelEtcChanged()
End


Function ImageBrowserContAutoscaleCB(ctrlName,isChecked): CheckboxControl
	String ctrlName
	Variable isChecked
	
	ImageBrowserModSetAutoscale(isChecked)
	ImageBrowserViewModelEtcChanged()	

End




Function ImageBrowserContSetVideo(imageWaveName)
	String imageWaveName
	
	ImageBrowserModelSetVideo(imageWaveName)
	RaiseOrCreateView("ImageBrowserView")
	ImageBrowserViewModelEtcChanged()	
End





// Marquee functions --- these are invoked by clicking inside a Marquee

Function ImagerBrowserContAddROI()
	GetMarquee /W=ImageBrowserView /K left, bottom
	Variable iROILeft=V_left
	Variable iROIRight=V_right
	Variable iROITop=V_top
	Variable iROIBottom=V_bottom
	ImagerAddROI(iROILeft, iROIRight, iROITop, iROIBottom)
	ImageBrowserModelImagerChanged()
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End


