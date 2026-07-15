// BSD 3-Clause License

// Copyright (c) 2020-present, CCvitaminHsieh
// All rights reserved.

// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:

// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.

// * Redistributions in binary form must reproduce the above copyright notice, this
//   list of conditions and the following disclaimer in the documentation and/or
//   other materials provided with the distribution.

// * Neither the name of the NTHU-HoiQEL nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Warning
// This source code is for academic use only. 
// DO NOT paste this program into your "Thesis".


#pragma rtGlobals=3		     // Use modern global access method and strict wave access.
#pragma IgorVersion = 6.37           // Check code for compatibility with Igor 6.37 or above
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GUI for main program
Menu "Wave Import / Export"
	"Import csv files as experimental wave", DataImportAsWave()
	 help = {"Import data ( *.csv) into Data Browser as a wave."}
	"Export wave to dat files", SelectWaveToExport()
	 help = {"Select and export a wave with (*.dat) extensions."}
End
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Command mode for main program
Function SelectWaveToExport()
   String anyWave
   Prompt anyWave, "Exported Wave:"popup Wavelist("*", ";", "")
   DoPrompt "Select and export a wave with (*.dat) extensions.", anyWave
   If (v_flag)
     	Print "WaveExportToDat Cancelled!!!"
     	return -1
   EndIf
   WaveExportToDat($anyWave)
End

Function/S  DataImportAsWave()
	// It will popup a dialog to import the experiment data ( *.csv, *.dat) into Data Browser.
	// create a folder to store temporary waves, strings, variables
	Variable killAxisFlag = 1
	String folderPath = tmpDirPath()
	NewDataFolder/o $folderPath
	SetDataFolder  $folderPath
	
	// Select experiment rowdata to $FileName
	String outputPath
	outputPath = PopupFileDialog("wData", "Read", "")
	If (StrLen(outputPath) == 0)
		Print "DataImportAsWave Cancelled!!!"
		KillDataFolder/z GetDataFolder(1)
	Else
		String FileName = ParseFilePath(3, outputPath, ":", 0, 0)
		Variable TotalWaveNum = LoadTracesToDataBrowser(outputPath)
		MergeTracesToWave(TotalWaveNum)
		Rename $"TracesMerged", $FileName
		
		// Import AxisInfo and set the scale to $FileName
		outputPath = PopupFileDialog("wAxisInfo", "Read", "")
		If (StrLen(outputPath) == 0)
			Print "Import AxisInfo Cancelled!!!"
		Else
			// reference for LoadWave: 
			// https://www.wavemetrics.com/forum/general/delimited-text
			// https://www.wavemetrics.com/comment/21970
			Variable bAddQuantToUnit = 0
			LoadWave/O/Q/A/J/D/W/K=0/V={","," $",1,0}/L={0,0,0,0,4} outputPath
			Wave/T XW, YW // Axis info for Xaxis, Yaxis
			ModifyXYScale($FileName, XW, YW, bAddQuantToUnit)
			// clean tmp waves and strings
			If (killAxisFlag)
				KillWaves/Z XW, YW
			EndIf
			KillStrings/Z outputPath
		EndIf
	EndIf

End
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Directory Path
Function/S tmpDirPath()
	String tmpPath = "root:tmpDirectory"
	return tmpPath
End
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Clear variables
Function DeleteGlobalVariables()
	killWaves/z XW, YW // axis data
	KillWaves/z wUnits, wAxis
	KillStrings/z outputPath
End
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// GUI for popup
Function/S PopupFileDialog(titleEvent, ioHandle, anyWaveToExport)
	// reference for implementing this function: 
	// https://www.wavemetrics.com/forum/general/how-test-string-equality
	// https://www.wavemetrics.com/forum/general/multiple-datatxt-file-import
	// https://www.wavemetrics.com/forum/general/save-delimited-data-csv-file-extension
	// https://www.wavemetrics.com/forum/general/trouble-understanding-igor-open-command-sfilename-and-returning-strings
	String titleEvent, ioHandle, anyWaveToExport
	String titleMsg
	String fileFilters
	String/g outputPath
	If (StringMatch(ioHandle, "Read"))
		StrSwitch (titleEvent)
			Case "wData":
				titleMsg = "Select a file for experiment data to continue"
				break
			Case "wScaleProperties":
				titleMsg = "Select a file with wScaleProperties to continue"
				break
			Case "wUnits":
				titleMsg  = "Select a file with wUnits to continue"
				break
			Case "wAxisInfo":
				titleMsg = "Select a file with \"_axisInfo\" suffix to continue"
				break
		EndSwitch
		fileFilters = "Data Files (*.csv):.csv;"
		Open /D /R /F=fileFilters /M=titleMsg refNum
	ElseIf (StringMatch(ioHandle, "Write"))
		StrSwitch (titleEvent)
			Case "wData":
				titleMsg = "Export a \"Wave\" as dat extension to continue."
				break;
			Case "wAxisInfo":
				titleMsg = "Export its \"_axisInfo\" as dat extension to continue."
				break;
		EndSwitch
		//String/g outputPath
		fileFilters = "Data Files (*.dat):.dat;"
		Open /D/F=fileFilters /M=titleMsg refNum as anyWaveToExport
	EndIf
	outputPath = S_fileName
	return outputPath
End
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// XY scale setting
Function ModifyXYScale(targetWave, xWave, yWave, bAddQuantToUnit)
	wave targetWave
	wave/T xWave, yWave // The data type of elements in xWave and yWave are text type.
	variable bAddQuantToUnit
	string xUnit, yUnit
	if (bAddQuantToUnit)
		sprintf xUnit "%s (%s)", xWave[0], xWave[1]
		sprintf yUnit "%s (%s)", yWave[0], yWave[1]
	else
		sprintf xUnit "%s", xWave[1]
		sprintf yUnit "%s", yWave[1]
	endif
	setscale/i x, Str2Num(xWave[2]), Str2Num(xWave[3]), xUnit, targetWave
	setscale/i y, Str2Num(yWave[2]), Str2Num(yWave[3]), yUnit, targetWave
End


// Generate the wave for wAxis
Function GenWaveAxisInfo(anyWave, bMatrixTranspose)
	Wave anyWave
	Variable bMatrixTranspose
	Variable r, c
	Variable dim = WaveDims(anyWave)
	Make/t/o/n=(2, 6) wAxis
	For (r = 0; r < dim; r = r + 1)
		If (StrLen(wAxis[r][0]) == 0)
			If (r == 0)
				wAxis[r][0] = "X" // X axis
			ElseIf (r == 1)
				wAxis[r][0] = "Y" // Y axis
			EndIf
		EndIf
		wAxis[r][1] = "" // wAxis[r][1] is a quantity information
		wAxis[r][2] = WaveUnits(anyWave, r) // unit
		wAxis[r][3] = Num2Str(DimOffset(anyWave, r)) // start
		wAxis[r][4] = Num2Str(DimOffset(anyWave, r) + (DimSize(anyWave, r) - 1) * DimDelta(anyWave, r)) // end
		wAxis[r][5] = Num2Str(DimDelta(anyWave, r)) // delta
	Endfor
	If (bMatrixTranspose)
		MatrixTranspose wAxis
	EndIf
End
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Data Export 
Function WaveExportToDat(anyWave)
	// Export the experimental data as (*.csv, *.dat), and save it in computer.
	Wave anyWave
	Variable bMatrixTranspose = 1
	// deal with data output
	GenWaveAxisInfo(anyWave, bMatrixTranspose)
	SaveWaveAsDat(anyWave, "", "wData")
	// deal with data axis quantities output (xaxis, yaxis information)
	Wave wAxis
	SaveWaveAsDat(wAxis, NameOfWave(anyWave), "wAxisInfo")
	// delete temp data
	killWaves/z XW, YW // axis data
	KillWaves/z wUnits, wAxis
	KillStrings/z outputPath
End

Function SaveWaveAsDat(anyWave, prefix, titleEvent)
	Wave anyWave
	String prefix, titleEvent
	String datName
	If (StrLen(prefix) == 0)
		Sprintf datName, "%s.dat", NameOfWave(anyWave)
	Else
		Wave wAxis
		If (StringMatch("wAxis", NameOfWave(wAxis)))
			Rename $"wAxis", $"_axisInfo"
		EndIf
		Sprintf datName, "%s%s.dat", prefix, NameOfWave(anyWave)
	EndIf
	String outputPath = PopupFileDialog(titleEvent, "Write", datName)
	If (StrLen(outputPath) == 0)
		return -1 // User cancelled
	EndIf
	Save/j/o/m="\r\n" anyWave as outputPath
End
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Data Import
Function LoadTracesToDataBrowser(outputPath)
	String outputPath
	String folderPath = tmpDirPath()
	LoadWave/o/a/d/g/k=0 outputPath
	//Variable/g TotalWaveNum = CountObjects(folderPath, 1)
	Variable TotalWaveNum=CountObjects(folderPath, 1)
	return TotalWaveNum
End
	
Function MergeTracesToWave(TotalWaveNum)
	Variable TotalWaveNum
	Variable killTempFlag = 1
	String necessaryWave  = "wave0"
	String cFolderPath  = GetDataFolder(1)
	If (WaveExists($necessaryWave))
      Variable idx 
		//Nvar TotalWaveNum
		Wave wave0 = $necessaryWave
		String waveMergeName = "TracesMerged"
		Variable wavPts = DimSize(wave0, 0)
		// create an empty wave in order to store data which is from tmpDirPath()
		If (TotalWaveNum == 1)
			Make/d/o/n=(wavPts) $waveMergeName
		Else
			Make/d/o/n=(wavPts, TotalWaveNum) $waveMergeName
		EndIf
		Wave WaveMerge = $waveMergeName
		// merge traces into a wave named WaveMerge 
		For (idx = 0; idx < TotalWaveNum; idx += 1)
			Wave trace = $("wave" + num2str(idx))
			WaveMerge[][idx] = trace[p][0]
		EndFor
	EndIf
	// delete all global variables from temporary files
	If (killTempFlag)
		MoveWave $(cFolderPath + nameofwave(waveMerge)), root:
		KillDataFolder/z $cFolderPath
	EndIf
End