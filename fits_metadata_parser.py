import sys
import json

from astropy.io import fits

if __name__ == '__main__':
	hdulist = fits.open(sys.argv[1])

	metadata = hdulist[0].header

	creator = ""
	instrument = ""
	facility = ""

	if ('OBSERVER' in hdulist[0].header):
		creator = hdulist[0].header['OBSERVER']
	elif ('AUTHOR' in hdulist[0].header):
		creator = hdulist[0].header['AUTHOR']

	if ('INSTRUME' in hdulist[0].header and 'TELESCOP' in hdulist[0].header):
		instrument = hdulist[0].header['INSTRUME'] + " " + hdulist[0].header['TELESCOP']
	elif ('INSTRUME' in hdulist[0].header):
		instrument = hdulist[0].header['INSTRUME']
	elif ('TELESCOP' in hdulist[0].header):
		instrument = hdulist[0].header['TELESCOP']
	elif ('CAMERA' in hdulist[0].header):
		instrument = hdulist[0].header['CAMERA']

	if ('ORIGIN' in hdulist[0].header):
		facility = hdulist[0].header['ORIGIN']

	result = {'creator': creator, 'instrument': instrument, 'facility': facility}

	json.dump(result, sys.stdout)