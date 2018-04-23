import sys
import json

from astropy.io import fits

if __name__ == '__main__':
	hdulist = fits.open(sys.argv[1])
	hdu_index = int(sys.argv[2])

	columns = hdulist[hdu_index].columns.names
	units = hdulist[hdu_index].columns.units

	ucds = []

	for j in range(len(columns)):
		ucd_key = "TBUCD{}".format(j + 1)
		ucd_key_2 = "UCD__{}".format(j + 1)

		if (ucd_key in hdulist[hdu_index].header):
			ucds.append(hdulist[hdu_index].header[ucd_key])
		elif (ucd_key_2 in hdulist[hdu_index].header):
			ucds.append(hdulist[hdu_index].header[ucd_key_2])
		else:
			ucds.append("")

	result = {'index': hdu_index, 'columns': list(columns), 'units': list(units), 'ucds': ucds}

	json.dump(result, sys.stdout)