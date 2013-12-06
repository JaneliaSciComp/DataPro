//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function ImageBrowserContConstructor()
	ImageBrowserModelConstructor()
	ImageBrowserViewConstructor()
End

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

Function ImageBrowserContScaleToData(ctrlName) : ButtonControl
	String ctrlName
	
	ImageBrowserModelScaleToData()
	ImageBrowserViewModelEtcChanged()
End


Function ImageBrowserContFullScale(ctrlName) : ButtonControl
	String ctrlName
	
	ImageBrowserModelFullScale()
	ImageBrowserViewModelEtcChanged()
End


Function ImagePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	if ( !AreStringsEqual(popStr,"(none)") && !AreStringsEqual(popStr,"None Selected"))
		ImageBrowserModelSetVideo(popStr)
		ImageBrowserViewModelEtcChanged()
	endif
End


Function ImageBrowserContAutoscToData(ctrlName,isChecked): CheckboxControl
	String ctrlName
	Variable isChecked
	
	ImageBrowserModSetAutoscToData(isChecked)
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
	Variable xROILeft=V_left
	Variable yROITop=V_top
	Variable xROIRight=V_right
	Variable yROIBottom=V_bottom
	ImagerAddROI(xROILeft, yROITop, xROIRight, yROIBottom)
	ImageBrowserModelImagerChanged()
	ImagerViewModelChanged()
	ImageBrowserViewModelEtcChanged()
End

