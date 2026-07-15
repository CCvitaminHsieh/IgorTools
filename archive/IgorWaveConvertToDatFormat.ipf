#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static function getProp(wvname, i, j)
	wave wvname
	variable i, j
	variable row_start = dimoffset(wvname, i)
	variable row_delta = dimdelta(wvname, i)
	variable row_pts = dimsize(wvname, i)

	make/o/free/n=(3) prop={row_start, row_delta, row_pts}

	return prop[j]
end

function getwaveScale(wvname)
	wave wvname
	variable dim = wavedims(wvname)
	make/o/n=(dim, 3) wave_property
	variable i, j
	
	for(i = 0; i < dim; i+=1)
		for(j = 0; j < dimsize(wave_property, 1); j += 1)
			wave_property[i][j] = getProp(wvname, i, j)
		endfor
	endfor
end

function getwaveUnits(wvname)
	wave wvname
	variable i
	variable dim = wavedims(wvname)
	make/t/o/n=(dim) wave_unit
	for(i = 0; i < dim; i += 1)
		wave_unit[i] = waveunits(wvname, i)
	endfor
end

function save2Dat(wvname)
	wave wvname
	string nameformat
	sprintf nameformat, "%s.dat", nameofwave(wvname)
	save/J/O/M="\r\n" wvname as nameformat
end

function exportWave(wvname)
	wave wvname
	getwaveScale(wvname)
	getwaveUnits(wvname)
	wave wave_property, wave_unit
	save2Dat(wvname)
	save2Dat(wave_property)
	save2Dat(wave_unit)
	killwaves/z wave_property, wave_unit
end
